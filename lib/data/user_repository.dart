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

  Future<Map<String, dynamic>> sendOtp(String phone, {String purpose = 'inquiry'}) async {
    return await ApiClient.post('/auth/otp/send', {'phone': phone, 'purpose': purpose}, auth: false) as Map<String, dynamic>;
  }

  Future<void> verifyOtp(String phone, String code, {String purpose = 'inquiry'}) async {
    await ApiClient.post('/auth/otp/verify', {'phone': phone, 'code': code, 'purpose': purpose}, auth: false);
  }

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
        'span': (j['unit'] as String?)?.trim().isNotEmpty == true ? ' / ${j['unit']}' : '',
        'feats': _packageFeatures(j),
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
      final imageUrl = j['image_url'] as String? ?? '';
      final images = (j['images'] as List?)
              ?.map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          (imageUrl.isNotEmpty ? [imageUrl] : <String>[]);
      return {
        'label': tag,
        'sub': headline,
        'e': emoji,
        'bg': bg,
        'type': type,
        'headline': headline,
        'desc': desc,
        'emoji': emoji,
        'imageUrl': images.isNotEmpty ? images.first : imageUrl,
        'images': images,
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

  static List<String> _packageFeatures(Map<String, dynamic> j) {
    final desc = (j['description'] as String?)?.trim() ?? '';
    if (desc.isNotEmpty) {
      final parts = desc.split('.').where((s) => s.trim().isNotEmpty).map((s) => s.trim()).toList();
      if (parts.isNotEmpty) return parts;
    }
    final title = (j['title'] as String?)?.trim() ?? '';
    final category = (j['category'] as String?)?.trim() ?? '';
    final unit = (j['unit'] as String?)?.trim() ?? '';
    return [
      if (category.isNotEmpty) category,
      if (unit.isNotEmpty) 'Priced per $unit',
      if (title.isNotEmpty) title,
    ];
  }

  static Map<String, dynamic> _normalizeSceneItem(Map<String, dynamic> item) {
    if (item.containsKey('group')) return item;
    final status = (item['status'] as String?)?.trim().isNotEmpty == true ? item['status'] as String : 'avail';
    final icon = switch (status) {
      'verified' => '⚠',
      'restricted' => '🔒',
      'no' => '✗',
      _ => (item['icon'] as String?)?.trim().isNotEmpty == true ? item['icon'] as String : '✓',
    };
    return {
      ...item,
      'status': status,
      'icon': icon,
      'label': item['label'] ?? '',
      'desc': item['desc'] ?? item['description'] ?? '',
    };
  }

  static List<Map<String, dynamic>> _normalizeSceneData(List<dynamic> raw) {
    return raw
        .whereType<Map>()
        .map((m) => _normalizeSceneItem(m.cast<String, dynamic>()))
        .toList();
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
      'sceneData': _normalizeSceneData((data['scene_data'] as List?) ?? []),
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
    String phoneOtp = '',
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
      'phone_otp': phoneOtp,
    }, auth: false);
    return data as Map<String, dynamic>;
  }

  // POST /api/v1/bookings/advance — submit advance with receipt for admin approval
  Future<Map<String, dynamic>> payAdvance(String bookingId, String inquiryRef, String receiptImageUrl) async {
    final data = await ApiClient.post('/bookings/advance', {
      'booking_id': bookingId,
      'inquiry_ref': inquiryRef,
      'amount': 5000,
      'method': 'UPI',
      'receipt_image': receiptImageUrl,
    });
    return data as Map<String, dynamic>;
  }

  // ── Events ────────────────────────────────────────────────────

  // GET /api/v1/events — live and upcoming events for the user app
  Future<List<Map<String, dynamic>>> events() async {
    final data = await ApiClient.get('/events');
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map && data['items'] is List) {
      return (data['items'] as List).cast<Map<String, dynamic>>();
    }
    return const [];
  }

  // GET /api/v1/cms/newsletters — published digest (empty if the desk hasn't shipped this yet)
  Future<List<Map<String, dynamic>>> newsletters() async {
    try {
      final data = await ApiClient.get('/cms/newsletters');
      if (data is List) return data.cast<Map<String, dynamic>>();
      if (data is Map && data['items'] is List) {
        return (data['items'] as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    try {
      final data = await ApiClient.get('/browse/newsletters');
      if (data is List) return data.cast<Map<String, dynamic>>();
      if (data is Map && data['items'] is List) {
        return (data['items'] as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return const [];
  }

  // POST /api/v1/browse/newsletter/subscribe — capture name, email, phone, city
  Future<void> subscribeNewsletter({
    required String name,
    required String email,
    String phone = '',
    String city = '',
  }) async {
    await ApiClient.post('/browse/newsletter/subscribe', {
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
    }, auth: false);
  }

  // POST /api/v1/browse/newsletter/contribute — press/vendor story with credentials
  Future<void> contributeNewsletter(Map<String, dynamic> payload) async {
    await ApiClient.post('/browse/newsletter/contribute', payload, auth: false);
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
  Future<Map<String, dynamic>> requestSubscription(String planId, String receiptImageUrl) async {
    final data = await ApiClient.post('/subscriptions/request', {
      'plan_id': planId,
      'receipt_image': receiptImageUrl,
    });
    return data as Map<String, dynamic>;
  }

  // GET /api/v1/subscriptions/requests/mine
  Future<List<Map<String, dynamic>>> mySubscriptionRequests() async {
    final data = await ApiClient.get('/subscriptions/requests/mine') as List;
    return data.cast<Map<String, dynamic>>();
  }

  // ── Directory content ─────────────────────────────────────────
  // Each of these is additive surface the marketplace didn't have before.
  // They all resolve to an empty list rather than throwing, because every
  // caller falls back to seed content — a desk that hasn't published yet
  // must never blank the page or surface a stack trace to a visitor.

  Future<List<Map<String, dynamic>>> _listFrom(List<String> paths) async {
    for (final path in paths) {
      try {
        final data = await ApiClient.get(path);
        if (data is List) return data.cast<Map<String, dynamic>>();
        if (data is Map && data['items'] is List) {
          return (data['items'] as List).cast<Map<String, dynamic>>();
        }
      } catch (_) {
        // try the next candidate path
      }
    }
    return const [];
  }

  /// GET /browse/ads — video and photo ad creatives for the display slots.
  Future<List<Map<String, dynamic>>> ads() =>
      _listFrom(['/browse/ads', '/cms/ads']);

  /// GET /sessions — workshops and webinars.
  Future<List<Map<String, dynamic>>> sessions() =>
      _listFrom(['/sessions', '/events/sessions', '/cms/sessions']);

  /// GET /cms/partners — academic and brand partners with logo artwork.
  Future<List<Map<String, dynamic>>> partners() =>
      _listFrom(['/cms/partners', '/browse/partners']);

  /// GET /cms/team — the AOneGo9 desk.
  Future<List<Map<String, dynamic>>> team() =>
      _listFrom(['/cms/team', '/browse/team']);

  /// GET /browse/updates — the notification bar feed across every division.
  Future<List<Map<String, dynamic>>> updates() =>
      _listFrom(['/browse/updates', '/cms/updates']);

  // ── Lead capture ──────────────────────────────────────────────

  /// POST /browse/leads — contact, join-us and apply forms.
  ///
  /// [kind] is one of `contact`, `join`, `apply_artist`, `apply_vendor`.
  /// Falls back to the newsletter contribution endpoint, which the backend
  /// already accepts, so a submission is never silently dropped just because
  /// the dedicated leads route hasn't shipped.
  Future<void> submitLead(String kind, Map<String, dynamic> payload) async {
    final body = {...payload, 'kind': kind};
    try {
      await ApiClient.post('/browse/leads', body, auth: false);
      return;
    } catch (_) {
      // fall through
    }
    await ApiClient.post('/browse/newsletter/contribute', body, auth: false);
  }

  /// POST /sessions/{id}/register — reserve a seat on a workshop or webinar.
  Future<void> registerForSession(String sessionId, Map<String, dynamic> payload) async {
    try {
      await ApiClient.post('/sessions/$sessionId/register', payload, auth: false);
    } catch (_) {
      await submitLead('session_register', {...payload, 'session_id': sessionId});
    }
  }
}
