import 'package:flutter/widgets.dart';
import '../data/api_client.dart';
import '../data/user_repository.dart';
import '../data/vendor_profile_utils.dart';

/// Toast payload — title (t), body (b), icon (i).
class ToastMsg {
  final String t;
  final String b;
  final String i;
  const ToastMsg(this.t, this.b, this.i);
}

/// A submitted inquiry — the first step of the inquiry → booking pipeline.
/// Posting it raises a "Requested" booking for the vendor + the admin.
class Inquiry {
  final String ref;
  final String vendorName;
  final String cat;
  final bool urgent;
  final DateTime at;
  final double advanceAmount; // refundable deposit to confirm & prioritise
  bool advancePaid;
  String status; // Sent → Viewed → Responded (updated by vendor/admin)
  Inquiry({
    required this.ref,
    required this.vendorName,
    required this.cat,
    required this.urgent,
    required this.at,
    this.advanceAmount = 5000,
    this.advancePaid = false,
    this.status = 'Sent',
  });
}

/// AppState — direct port of App()'s useState machine.
class AppState extends ChangeNotifier {
  String view = 'browse'; // browse | profile | vendor-auth | vendor-dash | vendor-edit
  Map<String, dynamic>? selectedProfile;
  String activeCat = 'modelF';
  String filter = 'All';

  /// The user's location. The whole marketplace is filtered to what is
  /// available here, so "in my location I see what's available". A profile
  /// whose location is Pan-India serves every city.
  String location = 'Mumbai';
  static const List<String> cities = ['Mumbai', 'Delhi NCR', 'Bangalore', 'All India'];
  ToastMsg? toast;
  String vendorName = 'Vendor';

  /// Inquiries the user has posted — kept so they are trackable end-to-end.
  final List<Inquiry> inquiries = [];

  /// API repository — replaces static mock data with real HTTP calls.
  final _repo = UserRepository();

  /// ── Customer session ──────────────────────────────────────────
  Map<String, dynamic>? currentUser;
  bool get isLoggedIn => currentUser != null;
  String? authError;
  bool authBusy = false;

  /// Restore a session from a previously-saved token (called on startup).
  Future<void> restoreSession() async {
    if (!await ApiClient.isLoggedIn()) return;
    try {
      currentUser = await _repo.myProfile();
      notifyListeners();
    } catch (_) {
      // stale/expired token — clear it silently
      await _repo.logout();
    }
  }

  Future<bool> loginUser(String email, String password) async {
    authBusy = true;
    authError = null;
    notifyListeners();
    try {
      await _repo.login(email, password);
      currentUser = await _repo.myProfile();
      authBusy = false;
      view = 'browse';
      notifyListeners();
      showToast('Welcome back', currentUser?['name'] ?? '', '👋');
      return true;
    } catch (e) {
      authBusy = false;
      authError = e is ApiException ? e.message : 'Login failed — check your details and try again';
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String city = '',
  }) async {
    authBusy = true;
    authError = null;
    notifyListeners();
    try {
      await _repo.register(name: name, email: email, password: password, phone: phone, city: city);
      currentUser = await _repo.myProfile();
      authBusy = false;
      view = 'browse';
      notifyListeners();
      showToast('Account created', 'Welcome to AOneGo9, $name', '🎉');
      return true;
    } catch (e) {
      authBusy = false;
      authError = e is ApiException ? e.message : 'Registration failed — please try again';
      notifyListeners();
      return false;
    }
  }

  Future<void> logoutUser() async {
    await _repo.logout();
    currentUser = null;
    view = 'browse';
    notifyListeners();
    showToast('Signed out', 'See you again soon', '👋');
  }

  /// Live listings loaded from the backend for the active category. Null
  /// while the first fetch for this category is still in flight; an empty
  /// list is a genuine "nothing here yet" — never backfilled with fake data.
  List<Map<String, dynamic>>? _apiListings;
  List<Map<String, dynamic>>? _apiTickerEvents;
  final Map<String, List<String>> _apiFilters = {};
  bool listingsLoading = false;

  static const _defaultFilters = <String, List<String>>{
    'venue': ['All', 'Indoor', 'Outdoor', 'Rooftop', 'Heritage'],
    'photo': ['All', 'Fashion', 'Wedding', 'Commercial', 'Portrait'],
    'video': ['All', 'Brand Films', 'Wedding', 'Social Media', 'Documentary'],
    'modelF': ['All', 'Fashion', 'Ethnic', 'Ramp', 'Film', 'Commercial', 'Fitness'],
    'modelM': ['All', 'Fashion', 'Ethnic', 'Ramp', 'Film', 'Commercial', 'Fitness'],
    'events': ['All', 'Fashion Shows', 'Corporate', 'Wedding Events', 'Concerts'],
  };

  /// Real per-category listing counts, filled in as each category is
  /// visited this session. Never guessed/faked — a category the user
  /// hasn't opened yet just has no entry (see [knownCategoryCount]).
  final Map<String, int> _categoryCounts = {};
  int? knownCategoryCount(String catId) => _categoryCounts[catId];

  List<Map<String, dynamic>> get apiListings => _apiListings ?? [];
  List<Map<String, dynamic>> get tickerEvents => _apiTickerEvents ?? [];
  List<String> filtersFor(String catId) => _apiFilters[catId] ?? _defaultFilters[catId] ?? const ['All'];

  static String _catIdFromSlug(String slug) => switch (slug) {
        'venues' => 'venue',
        'photography' => 'photo',
        'videography' => 'video',
        'models' => 'modelF',
        'event-services' => 'events',
        _ => slug,
      };

  /// Vendors self-report a free-text category at registration (e.g.
  /// "Photography"), matched case-insensitively as a substring by the
  /// backend. The app's internal category ids don't all line up with that
  /// text 1:1, so map to a term that actually appears in real vendor data.
  /// Note: the backend has no gender field on vendors, so "Female Models"
  /// and "Male Models" both search the same "talent" term — there's no way
  /// to tell them apart server-side with the current schema.
  static String _searchTermFor(String catId) => switch (catId) {
        'photo' => 'photography',
        'video' => 'videography',
        'venue' => 'venue',
        'events' => 'event',
        'modelF' || 'modelM' => 'talent',
        _ => catId,
      };

  /// Fetch listings from the backend and normalise each vendor map so the
  /// existing UI widgets (ListingCard, ProfileScreen) work without changes.
  Future<void> fetchListings() async {
    listingsLoading = true;
    notifyListeners();
    try {
      final results = await _repo.listings(
        category: _searchTermFor(activeCat),
        city: location == 'All India' ? null : location,
        filter: filter == 'All' ? null : filter,
      );
      _apiListings = results.map(_normaliseVendor).toList();
      _categoryCounts[activeCat] = _apiListings!.length;
    } catch (_) {
      _apiListings = [];
    } finally {
      listingsLoading = false;
      notifyListeners();
    }
  }

  /// Fetch ticker events from the backend.
  Future<void> fetchTickerEvents() async {
    try {
      _apiTickerEvents = await _repo.tickerEvents();
      notifyListeners();
    } catch (_) {
      _apiTickerEvents = [];
      notifyListeners();
    }
  }

  /// Load filter chips for each browse category from the backend.
  Future<void> fetchCategories() async {
    try {
      final cats = await _repo.categories();
      for (final c in cats) {
        final catId = _catIdFromSlug(c['slug'] as String? ?? '');
        final filters = (c['filters'] as List?)?.cast<String>() ?? const ['All'];
        _apiFilters[catId] = filters;
        if (catId == 'modelF') _apiFilters['modelM'] = filters;
        final count = (c['count'] as num?)?.toInt();
        if (count != null) _categoryCounts[catId] = count;
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Map a backend vendor JSON to the shape the UI expects.
  static Map<String, dynamic> _normaliseVendor(Map<String, dynamic> v) {
    // Map backend category string → user app cat id
    final rawCat = (v['category'] as String? ?? '').toLowerCase();
    String cat = 'modelF';
    if (rawCat.contains('photo')) {
      cat = 'photo';
    } else if (rawCat.contains('video')) {
      cat = 'video';
    } else if (rawCat.contains('venue')) {
      cat = 'venue';
    } else if (rawCat.contains('event')) {
      cat = 'events';
    } else if (rawCat.contains('male')) {
      cat = 'modelM';
    }

    final name = v['name'] as String? ?? v['company'] as String? ?? '';
    final city = v['city'] as String? ?? '';
    final rating = (v['rating'] as num?)?.toDouble() ?? 0.0;
    final bookings = (v['total_bookings'] as num?)?.toInt() ?? 0;
    final avatarUrl = (v['avatar_url'] as String?)?.trim() ?? '';
    final galleryUrls = ((v['gallery_urls'] as List?) ?? [])
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final profile = <String, dynamic>{
      'id': v['id'] ?? '',
      'cat': cat,
      'name': name,
      'loc': city,
      'rating': rating,
      'reviewCount': bookings,
      'verified': v['kyc_verified'] as bool? ?? false,
      'tags': (v['tags'] as List?)?.cast<String>() ?? <String>[],
      'badge': v['plan'] ?? 'Starter',
      'tagline': v['bio'] as String? ?? '',
      'overview': v['bio'] as String? ?? '',
      'avatarUrl': avatarUrl,
      'galleryUrls': galleryUrls,
      'emoji': VendorProfileUtils.categoryEmoji(cat),
      'stats': [
        {'n': '$bookings', 'l': 'Bookings'},
        {'n': rating.toStringAsFixed(1), 'l': 'Rating'},
        if (city.isNotEmpty) {'n': city, 'l': 'City'},
        {'n': v['plan'] ?? 'Starter', 'l': 'Plan'},
      ],
      'revList': <dynamic>[],
      'isNew': bookings == 0,
      '_raw': v,
    };
    profile['stats'] = VendorProfileUtils.buildDefaultStats(profile);
    return profile;
  }

  /// Submit inquiry to the backend, then record locally.
  Future<void> submitInquiryApi({
    required String vendorId,
    required String vendorName,
    required String ref,
    required String cat,
    required bool urgent,
    required String email,
    required String phone,
    required String date,
    String message = '',
  }) async {
    try {
      await _repo.submitInquiry(
        vendorId: vendorId,
        category: cat,
        name: vendorName,
        email: email,
        phone: phone,
        date: date,
        inquiryRef: ref,
        message: message,
        urgent: urgent,
      );
    } catch (_) {
      // non-blocking — inquiry is recorded locally regardless
    }
    submitInquiry(ref: ref, vendorName: vendorName, cat: cat, urgent: urgent);
  }

  /// ── Reach / share analytics ───────────────────────────────────
  /// Session-only counters — no seeded fake bases.
  final Map<String, int> _views = {};
  final Map<String, int> _shares = {};

  int profileViews(String id) => _views[id] ?? 0;
  int profileShares(String id) => _shares[id] ?? 0;
  int profileReach(String id) => profileViews(id) + profileShares(id) * 3;

  /// The real, copy-pasteable deep link for a profile. Opening it routes
  /// straight to this profile via [_initFromUrl] (?go=profile/<id>).
  String shareLink(Map<String, dynamic> p) {
    final base = Uri.base;
    final origin = base.hasScheme ? '${base.scheme}://${base.host}${base.hasPort && base.port != 0 ? ':${base.port}' : ''}' : 'https://aone-eta.vercel.app';
    return '$origin/?go=profile/${p['id']}';
  }

  /// Records that a profile's link was shared (bumps shares + reach).
  void recordShare(String id) {
    _shares[id] = (_shares[id] ?? 0) + 1;
    notifyListeners();
  }

  int _toastToken = 0;

  AppState() {
    _initFromUrl();
    // Kick off API fetches immediately on startup
    fetchListings();
    fetchTickerEvents();
    fetchCategories();
    restoreSession();
  }

  /// Optional deep-link via URL fragment (e.g. #profile/mf1, #vendor-dash).
  /// Only affects the INITIAL screen — no effect on UI/UX otherwise.
  void _initFromUrl() {
    final loc = Uri.base.queryParameters['loc'];
    if (loc != null && cities.contains(loc)) location = loc;
    final go = Uri.base.queryParameters['go'];
    if (go == null || go.isEmpty) return;
    final parts = go.split('/');
    switch (parts[0]) {
      case 'browse':
        if (parts.length > 1) activeCat = parts[1];
        break;
      case 'profile':
        final id = parts.length > 1 ? parts[1] : '';
        if (id.isNotEmpty) _openSharedProfile(id);
        break;
      case 'vendor-auth':
      case 'vendor-dash':
      case 'vendor-edit':
        view = 'vendor-auth';
        break;
    }
  }

  /// Resolves a shared profile link (?go=profile/<vendor-id>) against the
  /// real backend. Runs async since the constructor can't await it —
  /// silently stays on the default browse view if the id doesn't exist.
  Future<void> _openSharedProfile(String id) async {
    try {
      final vendor = await _repo.vendorProfile(id);
      final normalised = _normaliseVendor(vendor);
      selectedProfile = normalised;
      view = 'profile';
      activeCat = normalised['cat'] as String;
      _views[id] = (_views[id] ?? 0) + 1; // arriving via a shared link is a view
      notifyListeners();
    } catch (_) {
      // unknown/invalid id — stay on the default browse view
    }
  }

  /// Real listings for the active category, straight from the backend.
  /// [_apiListings] is always scoped to [activeCat] already (that's what
  /// gets requested), so no further filtering is needed here. Empty means
  /// genuinely no vendors yet — never backfilled with placeholder profiles.
  List<Map<String, dynamic>> get catItems => _apiListings ?? [];

  void setLocation(String city) {
    if (location == city) return;
    location = city;
    _apiListings = null; // clear so UI shows a loading state while re-fetching
    notifyListeners();
    fetchListings();
  }

  void showToast(String t, String b, [String i = '✅']) {
    toast = ToastMsg(t, b, i);
    final token = ++_toastToken;
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      if (token == _toastToken) {
        toast = null;
        notifyListeners();
      }
    });
  }

  /// Records a posted inquiry (and surfaces a toast). The generated [ref]
  /// is the same code the vendor and admin consoles show against the
  /// resulting "Requested" booking.
  void submitInquiry({required String ref, required String vendorName, required String cat, required bool urgent}) {
    inquiries.insert(0, Inquiry(ref: ref, vendorName: vendorName, cat: cat, urgent: urgent, at: DateTime.now()));
    showToast('Inquiry sent to $vendorName', 'Tracked as $ref · response in 2–4 hrs', urgent ? '🚨' : '✅');
  }

  /// Pays the advance/deposit via the backend when the user is signed in.
  Future<bool> payAdvanceApi(String bookingId, String inquiryRef) async {
    if (!isLoggedIn) return false;
    try {
      await _repo.payAdvance(bookingId, inquiryRef);
      final i = inquiries.indexWhere((q) => q.ref == inquiryRef);
      if (i != -1) {
        inquiries[i].advancePaid = true;
        inquiries[i].status = 'Advance paid';
      }
      notifyListeners();
      showToast('Advance paid', 'Slot reserved · adjusted against final bill', '💳');
      return true;
    } catch (_) {
      return false;
    }
  }

  void openProfile(Map<String, dynamic> item) {
    selectedProfile = item;
    view = 'profile';
    final id = item['id'] as String?;
    if (id != null) _views[id] = (_views[id] ?? 0) + 1; // count the open as a view
    notifyListeners();
  }

  void switchCat(String id) {
    activeCat = id;
    filter = 'All';
    _apiListings = null; // clear so UI shows a loading state while re-fetching
    notifyListeners();
    fetchListings();
  }

  void setFilter(String f) {
    if (filter == f) return;
    filter = f;
    _apiListings = null;
    notifyListeners();
    fetchListings();
  }

  void setView(String v) {
    view = v;
    notifyListeners();
  }

  void backToBrowse() {
    view = 'browse';
    selectedProfile = null;
    notifyListeners();
  }
}
