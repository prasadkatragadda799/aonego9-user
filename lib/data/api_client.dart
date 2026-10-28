import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base URL — change to your deployed backend URL in production.
const String kBaseUrl = 'https://aonego9-backend.onrender.com/api/v1';

class ApiClient {
  static const _tokenKey = 'user_access_token';
  static const _refreshKey = 'user_refresh_token';
  static String? _cachedToken;

  static Future<void> saveTokens(String access, String refresh) async {
    _cachedToken = access;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, access);
    await prefs.setString(_refreshKey, refresh);
  }

  static Future<String?> getAccessToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  static Future<void> clearTokens() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
  }

  static Future<bool> isLoggedIn() async => (await getAccessToken()) != null;

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final t = await getAccessToken();
      if (t != null) h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  static String _formatDetail(dynamic raw, int statusCode) {
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    if (raw is List) {
      return raw.map((e) => e is Map ? (e['msg'] ?? e.toString()) : e.toString()).join('; ');
    }
    if (raw != null) return raw.toString();
    return 'Request failed ($statusCode)';
  }

  static dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String detail = 'Request failed (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body.containsKey('detail')) {
        detail = _formatDetail(body['detail'], res.statusCode);
      }
    } catch (_) {}
    throw ApiException(res.statusCode, detail);
  }

  static Future<bool> _refreshAccessToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refresh}),
          )
          .timeout(_postTimeout);
      if (res.statusCode != 200) return false;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      await saveTokens(body['access_token'] as String, body['refresh_token'] as String);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Without a deadline a hung backend (a cold Render instance, a dropped
  /// connection) left every spinner in the app turning forever. GETs get one
  /// retry, which also rides out the cold start; POSTs are not retried
  /// because they are not safe to repeat.
  static const _getTimeout = Duration(seconds: 30);
  static const _postTimeout = Duration(seconds: 45);

  static Future<http.Response> _withAuthRetry(
    Future<http.Response> Function() send, {
    required bool auth,
  }) async {
    var res = await send();
    if (auth && res.statusCode == 401 && await _refreshAccessToken()) {
      res = await send();
    }
    if (auth && res.statusCode == 401) await clearTokens();
    return res;
  }

  static Future<dynamic> get(String path, {bool auth = true}) async {
    Future<http.Response> send() async => http
        .get(Uri.parse('$kBaseUrl$path'), headers: await _headers(auth: auth))
        .timeout(_getTimeout);
    try {
      return _decode(await _withAuthRetry(send, auth: auth));
    } on TimeoutException {
      return _decode(await _withAuthRetry(send, auth: auth));
    } on http.ClientException {
      return _decode(await _withAuthRetry(send, auth: auth));
    }
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    Future<http.Response> send() async => http
        .post(Uri.parse('$kBaseUrl$path'), headers: await _headers(auth: auth), body: jsonEncode(body))
        .timeout(_postTimeout);
    return _decode(await _withAuthRetry(send, auth: auth));
  }

  /// List endpoints answer either a bare array or a page envelope
  /// (`{items|results|data: [...]}`) depending on the route. Casting straight
  /// to `List` threw on the envelope and the screen silently showed nothing.
  static List<Map<String, dynamic>> asList(dynamic data) {
    final raw = data is List
        ? data
        : data is Map
            ? (data['items'] ?? data['results'] ?? data['data'] ?? const [])
            : const [];
    return (raw is List ? raw : const [])
        .whereType<Map>()
        .map((m) => m.cast<String, dynamic>())
        .toList();
  }

  /// POST /api/v1/uploads/image — JSON base64 on web, multipart on mobile.
  static Future<Map<String, dynamic>> uploadImage({
    required List<int> bytes,
    required String filename,
    String folder = 'misc',
    String mimeType = 'image/jpeg',
  }) async {
    if ((await getAccessToken())?.isEmpty ?? true) {
      if (!await _refreshAccessToken()) {
        throw const ApiException(401, 'Not logged in — sign in again to upload photos');
      }
    }

    Future<http.Response> send() async {
      if (kIsWeb) {
        return http.post(
          Uri.parse('$kBaseUrl/uploads/image-base64'),
          headers: await _headers(),
          body: jsonEncode({
            'data': base64Encode(bytes),
            'filename': filename,
            'folder': folder,
            'content_type': mimeType,
          }),
        );
      }
      final token = await getAccessToken();
      final uri = Uri.parse('$kBaseUrl/uploads/image').replace(queryParameters: {'folder': folder});
      final request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ));
      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    var res = await send();
    if (res.statusCode == 401 && await _refreshAccessToken()) {
      res = await send();
    }
    return (_decode(res) as Map).cast<String, dynamic>();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}
