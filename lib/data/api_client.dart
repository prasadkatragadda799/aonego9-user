import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Base URL — change to your deployed backend URL in production.
const String kBaseUrl = 'http://localhost:8000/api/v1';

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

  static dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String detail = 'Request failed (${res.statusCode})';
    try {
      detail = jsonDecode(res.body)['detail'] ?? detail;
    } catch (_) {}
    throw ApiException(res.statusCode, detail);
  }

  static Future<dynamic> get(String path) async =>
      _decode(await http.get(Uri.parse('$kBaseUrl$path'), headers: await _headers()));

  static Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async =>
      _decode(await http.post(Uri.parse('$kBaseUrl$path'), headers: await _headers(auth: auth), body: jsonEncode(body)));
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}
