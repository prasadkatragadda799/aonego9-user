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
    if (filter != null && filter.isNotEmpty) params['filter'] = filter;
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
    return data as Map<String, dynamic>;
  }

  // GET /api/v1/vendors/public/{id}/packages
  // Returns the vendor's active packages formatted for the profile screen's
  // p['packages'] list — keys: name, price (formatted ₹), span, feats, pop.
  Future<List<Map<String, dynamic>>> vendorPackages(String vendorId) async {
    final data = await ApiClient.get('/vendors/public/$vendorId/packages') as List;
    return data.map((j) {
      final price = (j['price'] as num).toDouble();
      final priceStr = '₹${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
      return {
        'name': j['title'] ?? '',
        'price': priceStr,
        'span': ' / ${j['unit'] ?? ''}',
        'feats': (j['description'] as String? ?? '').split('.').where((s) => s.trim().isNotEmpty).map((s) => s.trim()).toList(),
        'pop': false,
        'id': j['id'],
        'bookingsCount': j['bookings_count'] ?? 0,
      };
    }).toList();
  }

  // GET /api/v1/vendors/public/{id}/portfolio
  Future<List<Map<String, dynamic>>> vendorPortfolio(String vendorId) async {
    final data = await ApiClient.get('/vendors/public/$vendorId/portfolio') as List;
    return data.map((j) {
      final tag = j['tag'] as String? ?? '';
      final type = (j['type'] as String? ?? '').isNotEmpty ? j['type'] as String : tag.toLowerCase();
      final bg = (j['bg'] as num?)?.toInt() ?? 0;
      final headline = j['headline'] as String? ?? '';
      final desc = j['description'] as String? ?? '';
      final emoji = j['emoji'] as String? ?? '🖼️';
      return {
        'label': tag,
        'sub': headline,
        'e': emoji,
        'bg': bg,
        'type': type,
        'headline': headline,
        'desc': desc,
        'emoji': emoji,
      };
    }).toList();
  }

  // GET /api/v1/reviews/public/{id}
  Future<Map<String, dynamic>> vendorReviews(String vendorId) async {
    final data = await ApiClient.get('/reviews/public/$vendorId');
    return data as Map<String, dynamic>;
  }

  // GET /api/v1/vendors/public/{id}/profile-details
  Future<Map<String, dynamic>> vendorProfileDetails(String vendorId) async {
    final data = await ApiClient.get('/vendors/public/$vendorId/profile-details');
    return _mapProfileDetails(data as Map<String, dynamic>);
  }

  static Map<String, dynamic> _mapProfileDetails(Map<String, dynamic> data) {
    final cc = (data['comp_card'] as Map?)?.cast<String, dynamic>() ?? {};
    return {
      'overview': data['overview'] ?? '',
      'exp': data['experience'] ?? '',
      'training': data['training'] ?? '',
      'langs': data['languages'] ?? '',
      'height': cc['height'] ?? '',
      'weight': cc['weight'] ?? '',
      'bust': cc['bust'] ?? '',
      'chest': cc['chest'] ?? '',
      'waist': cc['waist'] ?? '',
      'hip': cc['hip'] ?? '',
      'shoe': cc['shoe'] ?? '',
      'age': cc['age'],
      'hair': cc['hair'] ?? '',
      'eye': cc['eye'] ?? '',
      'skin': cc['skin'] ?? '',
      'stats': data['stats'] ?? [],
      'tags': data['tags'] ?? [],
      'services': data['services'] ?? [],
      'amenities': data['amenities'] ?? [],
      'avail': data['availability'] ?? [],
      'sceneData': data['scene_data'] ?? [],
      'spaces': data['spaces'] ?? [],
      'equipment': data['equipment'] ?? [],
      'reels': data['reels'] ?? [],
    };
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
  Future<Map<String, dynamic>> myProfile() async {
    final data = await ApiClient.get('/users/me');
    return data as Map<String, dynamic>;
  }

  // GET /api/v1/bookings/me
  Future<List<Map<String, dynamic>>> myBookings() async {
    final data = await ApiClient.get('/bookings/me') as Map;
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  // ── Subscriptions ────────────────────────────────────────────

  // GET /api/v1/subscriptions/plans?audience=user
  Future<List<Map<String, dynamic>>> subscriptionPlans() async {
    final data = await ApiClient.get('/subscriptions/plans?audience=user') as List;
    return data.cast<Map<String, dynamic>>();
  }

  // GET /api/v1/subscriptions/me — null if the user has no active subscription (404)
  Future<Map<String, dynamic>?> currentSubscription() async {
    try {
      final data = await ApiClient.get('/subscriptions/me');
      return data as Map<String, dynamic>;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  // GET /api/v1/subscriptions/payment-info (public)
  Future<Map<String, dynamic>> paymentInfo() async {
    final data = await ApiClient.get('/subscriptions/payment-info');
    return data as Map<String, dynamic>;
  }

  // POST /api/v1/subscriptions/request
  Future<Map<String, dynamic>> requestSubscription(String planId, String receiptImageBase64) async {
    final data = await ApiClient.post('/subscriptions/request', {
      'plan_id': planId,
      'receipt_image': receiptImageBase64,
    });
    return data as Map<String, dynamic>;
  }

  // GET /api/v1/subscriptions/requests/mine
  Future<List<Map<String, dynamic>>> mySubscriptionRequests() async {
    final data = await ApiClient.get('/subscriptions/requests/mine') as List;
    return data.cast<Map<String, dynamic>>();
  }
}
