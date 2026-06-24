import 'api_client.dart';

/// ───────────────────────────────────────────────────────────────
/// USER APP REPOSITORY — all methods call the real FastAPI backend.
/// ───────────────────────────────────────────────────────────────
class UserRepository {

  // ── Auth ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await ApiClient.post('/auth/login/user', {'email': email, 'password': password}, auth: false);
    await ApiClient.saveTokens(data['access_token'], data['refresh_token']);
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String city = '',
    String role = 'client',
  }) async {
    final data = await ApiClient.post('/auth/register/user', {
      'name': name, 'email': email, 'password': password,
      'phone': phone, 'city': city, 'role': role,
    }, auth: false);
    await ApiClient.saveTokens(data['access_token'], data['refresh_token']);
    return data;
  }

  Future<void> logout() => ApiClient.clearTokens();

  // ── Browse ────────────────────────────────────────────────────

  // GET /api/v1/browse/categories
  Future<List<Map<String, dynamic>>> categories() async {
    final data = await ApiClient.get('/browse/categories') as List;
    return data.cast<Map<String, dynamic>>();
  }

  // GET /api/v1/browse/listings?category=&city=&page=&page_size=
  Future<List<Map<String, dynamic>>> listings({
    String? category,
    String? city,
    String? filter,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, String>{'page': '$page', 'page_size': '$pageSize'};
    if (category != null) params['category'] = category;
    if (city != null) params['city'] = city;
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final data = await ApiClient.get('/browse/listings?$query') as List;
    return data.cast<Map<String, dynamic>>();
  }

  // GET /api/v1/browse/ticker
  Future<List<Map<String, dynamic>>> tickerEvents() async {
    final data = await ApiClient.get('/browse/ticker') as List;
    return data.cast<Map<String, dynamic>>();
  }

  // GET /api/v1/vendors/public/{id}
  Future<Map<String, dynamic>> vendorProfile(String vendorId) async {
    final data = await ApiClient.get('/vendors/public/$vendorId');
    return data;
  }

  // ── Inquiries ─────────────────────────────────────────────────

  // POST /api/v1/browse/inquiry
  Future<Map<String, dynamic>> submitInquiry({
    required String vendorId,
    required String category,
    required String name,
    required String email,
    required String phone,
    required String date,
    required String inquiryRef,
    String message = '',
    bool urgent = false,
  }) async {
    final data = await ApiClient.post('/browse/inquiry', {
      'vendor_id': vendorId,
      'category': category,
      'name': name,
      'email': email,
      'phone': phone,
      'date': date,
      'message': message,
      'urgent': urgent,
      'inquiry_ref': inquiryRef,
    });
    return data;
  }

  // POST /api/v1/bookings/advance — pay ₹5 000 advance for a booking
  Future<void> payAdvance(String bookingId, String inquiryRef) async {
    await ApiClient.post('/bookings/advance', {
      'booking_id': bookingId,
      'inquiry_ref': inquiryRef,
      'amount': 5000,
      'method': 'UPI',
    });
  }

  // ── Events ────────────────────────────────────────────────────

  // GET /api/v1/events — live and upcoming events for the user app
  Future<List<Map<String, dynamic>>> events() async {
    final data = await ApiClient.get('/events') as List;
    return data.cast<Map<String, dynamic>>();
  }

  // ── User profile ──────────────────────────────────────────────

  // GET /api/v1/users/me
  Future<Map<String, dynamic>> myProfile() async => ApiClient.get('/users/me');

  // GET /api/v1/bookings/me
  Future<List<Map<String, dynamic>>> myBookings() async {
    final data = await ApiClient.get('/bookings/me') as Map;
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }
}
