import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/api_client.dart';
import '../data/directory.dart';
import '../data/editorial.dart';
import '../data/geo.dart';
import '../data/taxonomy.dart';
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
  String view = 'browse'; // browse | profile | vendor-auth | newsletter | events | about | partners | team | sessions | connect | login | account | subscription
  Map<String, dynamic>? selectedProfile;
  NewsletterIssue? selectedIssue;

  /// The rail is two levels now: a division holds several categories.
  /// [activeDivision] is always [activeCat]'s own division — see [switchCat].
  String activeDivision = 'talent';
  String activeCat = 'modelF';
  String filter = 'All';
  String newsletterTab = 'happening'; // happening | trend

  /// Industry vertical filter on the digest ('all' = unfiltered).
  String newsVertical = 'all';

  /// Which form the Connect screen opens on: contact | join | apply.
  String connectTab = 'contact';

  bool showNewsletterPopup = false;
  bool newsletterSubscribed = false;

  /// The user's location. The whole marketplace is filtered to what is
  /// available here, so "in my location I see what's available". A profile
  /// whose location is Pan-India serves every city.
  String location = 'Mumbai';

  /// Shortcut cities kept for the footer's "Cities" column. The full
  /// state → city → area hierarchy lives in [GeoIndex]; this is just the
  /// handful worth a permanent link.
  static const List<String> cities = ['Mumbai', 'Delhi NCR', 'Bangalore', 'Hyderabad', 'Chennai', kAllIndia];

  /// The state [location] sits in, or '' when it is a state itself or
  /// [kAllIndia]. Shown next to the city in the search bar.
  String get locationState => GeoIndex.stateOfCity(location);

  /// ── Appearance ───────────────────────────────────────────────
  /// 'system' | 'dark' | 'light'. Persisted, and defaults to following the
  /// OS so a visitor who runs their phone in light mode is not handed a dark
  /// page on first paint.
  String themeMode = 'system';

  /// Resolve the stored preference against the platform's current brightness.
  Brightness resolveBrightness(Brightness platform) => switch (themeMode) {
        'dark' => Brightness.dark,
        'light' => Brightness.light,
        _ => platform,
      };

  Future<void> setThemeMode(String mode) async {
    if (themeMode == mode) return;
    themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
  }

  /// Steps system → light → dark → system, which is what the single
  /// toolbar button cycles through.
  void cycleThemeMode() => setThemeMode(switch (themeMode) {
        'system' => 'light',
        'light' => 'dark',
        _ => 'system',
      });

  Future<void> _restoreThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    if (saved != null && saved != themeMode && const ['system', 'dark', 'light'].contains(saved)) {
      themeMode = saved;
      notifyListeners();
    }
  }

  /// Free-text marketplace search — name, tagline, tags, city.
  String query = '';
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
  List<NewsletterIssue> _newsletters = List.of(seedNewsletters);
  List<Map<String, dynamic>> _platformEvents = List.of(seedEvents);
  final Map<String, List<String>> _apiFilters = {};
  bool listingsLoading = false;
  bool eventsLoading = false;

  /// ── Directory feeds ─────────────────────────────────────────
  /// Each falls back to its seed list when the desk has published nothing,
  /// so no page is ever an empty wall on a fresh deployment.
  List<AdCreative> _ads = List.of(seedAds);
  List<Session> _sessions = List.of(seedSessions);
  List<LogoPartner> _logoPartners = [...seedAcademicPartners, ...seedBrandPartners];
  List<TeamMember> _team = List.of(seedTeam);
  List<Map<String, dynamic>> _updates = const [];

  List<AdCreative> get ads => _ads;
  List<Session> get sessions => _sessions;
  List<TeamMember> get team => _team;
  List<LogoPartner> get academicPartners =>
      _logoPartners.where((p) => p.tier == PartnerTier.academic).toList();
  List<LogoPartner> get brandPartners =>
      _logoPartners.where((p) => p.tier != PartnerTier.academic).toList();

  List<Session> get workshops => _sessions.where((s) => !s.isWebinar).toList();
  List<Session> get webinars => _sessions.where((s) => s.isWebinar).toList();

  /// Filter chips fall back to the catalogue when the backend hasn't
  /// published a set for a category.

  /// Real per-category listing counts, filled in as each category is
  /// visited this session. Never guessed/faked — a category the user
  /// hasn't opened yet just has no entry (see [knownCategoryCount]).
  final Map<String, int> _categoryCounts = {};
  int? knownCategoryCount(String catId) => _categoryCounts[catId];

  List<Map<String, dynamic>> get apiListings => _apiListings ?? [];
  List<Map<String, dynamic>> get tickerEvents => _apiTickerEvents ?? [];
  List<NewsletterIssue> get newsletters => _newsletters;
  List<NewsletterIssue> get happeningIssues => _byVertical('happening');
  List<NewsletterIssue> get trendIssues => _byVertical('trend');

  /// Issues of one kind, narrowed to [newsVertical] when a vertical is picked.
  List<NewsletterIssue> _byVertical(String kind) => _newsletters
      .where((n) => n.kind == kind)
      .where((n) => newsVertical == 'all' || n.vertical == newsVertical)
      .toList();

  /// Verticals that actually have a story behind them, so the filter row never
  /// offers a chip that leads to an empty page.
  Set<String> get populatedVerticals =>
      {for (final n in _newsletters) n.vertical};
  NewsletterIssue get featuredIssue {
    final match = _newsletters.where((n) => n.id == featuredIssueId);
    return match.isNotEmpty ? match.first : _newsletters.first;
  }
  List<Map<String, dynamic>> get platformEvents => _platformEvents;

  /// The notification bar's feed: every division's upcoming activity in one
  /// stream — platform events, workshops and webinars — newest first and
  /// scoped to the browsing location.
  ///
  /// Built from what is already loaded rather than a separate request, so the
  /// bar is populated on first paint instead of after a second round trip.
  List<UpdateEntry> get updateFeed {
    final out = <UpdateEntry>[];

    for (final u in _updates) {
      out.add(UpdateEntry(
        id: '${u['id'] ?? ''}',
        kind: (u['kind'] as String? ?? 'update'),
        division: u['division'] as String? ?? '',
        title: u['title'] as String? ?? '',
        city: u['city'] as String? ?? '',
        state: u['state'] as String? ?? '',
        date: u['date'] as String? ?? '',
        emoji: u['emoji'] as String? ?? '📣',
        live: u['live'] == true || u['on_poster'] == true,
      ));
    }

    for (final e in _platformEvents) {
      final city = '${e['city'] ?? ''}';
      out.add(UpdateEntry(
        id: '${e['id'] ?? ''}',
        kind: 'event',
        division: 'crew',
        title: '${e['title'] ?? ''}',
        city: city,
        state: GeoIndex.stateOfCity(city),
        date: '${e['date'] ?? ''}',
        emoji: '${e['emoji'] ?? '📅'}',
        live: e['on_poster'] == true,
      ));
    }

    for (final w in _sessions) {
      out.add(UpdateEntry(
        id: w.id,
        kind: w.isWebinar ? 'webinar' : 'workshop',
        division: w.division,
        title: w.title,
        city: w.city,
        state: w.state.isNotEmpty ? w.state : GeoIndex.stateOfCity(w.city),
        date: w.date,
        emoji: w.emoji,
        live: w.nearlyFull,
      ));
    }

    final scoped = out.where((u) {
      // Online sessions have no city and belong to everyone.
      if (u.city.isEmpty || u.city.toLowerCase() == 'online') return true;
      return GeoIndex.matches(selected: location, listingCity: u.city);
    }).toList();

    scoped.sort((a, b) => a.date.compareTo(b.date));
    return scoped;
  }
  List<String> filtersFor(String catId) => _apiFilters[catId] ?? catOf(catId)?.filters ?? const ['All'];

  /// Vendors self-report a free-text category at registration (e.g.
  /// "Photography"), matched case-insensitively as a substring by the
  /// backend. Both the slug mapping and the search term now come from the
  /// catalogue, so a new vertical needs no change here.
  ///
  /// Note: the backend has no gender field on vendors, so "Female Models"
  /// and "Male Models" both search the same "talent" term — there is no way
  /// to tell them apart server-side with the current schema.
  static String _searchTermFor(String catId) => catOf(catId)?.searchTerm ?? catId;

  /// Fetch listings from the backend and normalise each vendor map so the
  /// existing UI widgets (ListingCard, ProfileScreen) work without changes.
  Future<void> fetchListings() async {
    listingsLoading = true;
    notifyListeners();
    try {
      // A state cannot be sent as `city` — the backend would match nothing.
      // In that case fetch broadly and narrow locally, which also means
      // asking for more rows than one screen's worth.
      final narrowsLocally = GeoIndex.needsClientNarrowing(location);
      final results = await _repo.listings(
        category: _searchTermFor(activeCat),
        city: GeoIndex.cityParamFor(location),
        filter: filter == 'All' ? null : filter,
        pageSize: narrowsLocally || query.isNotEmpty ? 60 : 20,
      );
      _apiListings = results.map(_normaliseVendor).toList();
      // Count what is actually browsable here, not what the request returned —
      // otherwise the rail badge disagrees with the grid under it.
      _categoryCounts[activeCat] = _scopedToLocation(_apiListings!).length;
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

  /// Live + upcoming platform events. Seed content stays if the API is empty.
  Future<void> fetchPlatformEvents() async {
    eventsLoading = true;
    notifyListeners();
    try {
      final raw = await _repo.events();
      if (raw.isNotEmpty) {
        _platformEvents = raw.map(_normaliseEvent).toList();
      }
    } catch (_) {
      // keep seed events so the page is never a blank wall
    } finally {
      eventsLoading = false;
      notifyListeners();
    }
  }

  static Map<String, dynamic> _normaliseEvent(Map<String, dynamic> e) {
    return {
      'id': '${e['id'] ?? ''}',
      'title': e['title'] ?? '',
      'city': e['city'] ?? e['location'] ?? '',
      'date': e['date'] ?? e['starts_at'] ?? '',
      'end_date': e['end_date'] ?? e['ends_at'] ?? '',
      'status': e['status'] ?? 'upcoming',
      'on_poster': e['on_poster'] == true,
      'venue': e['venue'] ?? e['location'] ?? '',
      'blurb': e['blurb'] ?? e['description'] ?? e['subtitle'] ?? '',
      'emoji': e['emoji'] ?? '📅',
      'bg': (e['bg'] as num?)?.toInt() ?? 0,
    };
  }

  /// Ads, sessions, partners, team and the updates feed. Each keeps its seed
  /// list on failure or an empty response — see [_ads] and friends.
  Future<void> fetchDirectory() async {
    final results = await Future.wait([
      _repo.ads(),
      _repo.sessions(),
      _repo.partners(),
      _repo.team(),
      _repo.updates(),
    ]);

    final ads = results[0].map(AdCreative.fromJson).where((a) => a.headline.isNotEmpty).toList();
    if (ads.isNotEmpty) _ads = ads;

    final sessions = results[1].map(Session.fromJson).where((x) => x.title.isNotEmpty).toList();
    if (sessions.isNotEmpty) _sessions = sessions;

    final partners = results[2].map(LogoPartner.fromJson).where((x) => x.name.isNotEmpty).toList();
    if (partners.isNotEmpty) _logoPartners = partners;

    final team = results[3].map(TeamMember.fromJson).where((x) => x.name.isNotEmpty).toList();
    if (team.isNotEmpty) _team = team;

    _updates = results[4];
    notifyListeners();
  }

  Future<void> fetchNewsletters() async {
    try {
      final raw = await _repo.newsletters();
      if (raw.isEmpty) return;
      final parsed = raw.map(NewsletterIssue.fromJson).where((n) => n.title.isNotEmpty).toList();
      if (parsed.isNotEmpty) {
        _newsletters = parsed;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> subscribeNewsletter({
    required String name,
    required String email,
    String phone = '',
    String city = '',
  }) async {
    try {
      await _repo.subscribeNewsletter(name: name, email: email, phone: phone, city: city);
    } catch (_) {
      // captured locally either way — the desk still has the lead
    }
    newsletterSubscribed = true;
    showNewsletterPopup = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('nl_sub', true);
    await prefs.setString('nl_email', email);
    await prefs.setString('nl_name', name);
    notifyListeners();
    showToast('You\'re on the digest', 'What\'s happening + trends, every Friday', '✉️');
  }

  Future<void> contributeNewsletter(Map<String, dynamic> payload) async {
    try {
      await _repo.contributeNewsletter(payload);
    } catch (_) {}
    showToast('Story received', 'The desk will verify credentials before it goes live', '📝');
  }

  Future<void> dismissNewsletterPopup() async {
    showNewsletterPopup = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('nl_popup_at', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _maybeShowNewsletterPopup() async {
    final prefs = await SharedPreferences.getInstance();
    newsletterSubscribed = prefs.getBool('nl_sub') ?? false;
    if (newsletterSubscribed) return;
    final last = prefs.getInt('nl_popup_at') ?? 0;
    if (last != 0) {
      final age = DateTime.now().millisecondsSinceEpoch - last;
      if (age < const Duration(hours: 18).inMilliseconds) return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (view == 'browse') {
      showNewsletterPopup = true;
      notifyListeners();
    }
  }

  void setNewsletterTab(String tab) {
    if (newsletterTab == tab) return;
    newsletterTab = tab;
    if (selectedIssue != null && selectedIssue!.kind != tab) {
      selectedIssue = null;
    }
    notifyListeners();
  }

  void openIssue(NewsletterIssue issue) {
    selectedIssue = issue;
    newsletterTab = issue.kind;
    view = 'newsletter';
    notifyListeners();
  }

  /// Load filter chips for each browse category from the backend.
  Future<void> fetchCategories() async {
    try {
      final cats = await _repo.categories();
      for (final c in cats) {
        final slug = c['slug'] as String? ?? '';
        final catId = catIdFromSlug(slug);
        // catIdFromSlug falls back to modelF for anything it cannot place.
        // Accepting that here would let an unrelated backend category
        // overwrite the female-models filter chips and count.
        if (slug.isEmpty || (catId == 'modelF' && !_looksLikeFemaleModels(slug))) continue;
        final filters = (c['filters'] as List?)?.cast<String>() ?? const ['All'];
        _apiFilters[catId] = filters;
        if (catId == 'modelF') _apiFilters['modelM'] = filters;
        final count = (c['count'] as num?)?.toInt();
        if (count != null) _categoryCounts[catId] = count;
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Guards the modelF fallback in [catIdFromSlug] — only a slug that really
  /// is the female-models category may claim it.
  static bool _looksLikeFemaleModels(String slug) {
    final s = slug.toLowerCase();
    return s == 'models' || s == 'modelf' || s.contains('female') || s.contains('talent');
  }

  /// Map a backend vendor JSON to the shape the UI expects.
  static Map<String, dynamic> _normaliseVendor(Map<String, dynamic> v) {
    // Map the vendor's free-text category onto a catalogue id. The old
    // inline if-chain only knew the original six and, worse, matched
    // "female" against `contains('male')` — every female model was filed
    // as modelM. [catIdFromBackend] checks the most specific terms first.
    final cat = catIdFromBackend(v['category'] as String? ?? '');

    final name = v['name'] as String? ?? v['company'] as String? ?? '';
    final city = v['city'] as String? ?? '';
    final rating = (v['rating'] as num?)?.toDouble() ?? 0.0;
    final bookings = (v['total_bookings'] as num?)?.toInt() ?? 0;
    final avatarUrl = (v['avatar_url'] as String?)?.trim() ?? '';
    final galleryUrls = ((v['gallery_urls'] as List?) ?? (v['galleryUrls'] as List?) ?? [])
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
    fetchListings();
    fetchTickerEvents();
    fetchCategories();
    fetchPlatformEvents();
    fetchNewsletters();
    fetchDirectory();
    _restoreThemeMode();
    restoreSession();
    _maybeShowNewsletterPopup();
  }

  /// Optional deep-link via URL fragment (e.g. #profile/mf1, #vendor-dash).
  /// Only affects the INITIAL screen — no effect on UI/UX otherwise.
  void _initFromUrl() {
    final loc = Uri.base.queryParameters['loc'];
    if (loc != null && loc.isNotEmpty) {
      // Accepts a city, a state or an area name — the old check only allowed
      // the four hardcoded cities, so ?loc=Hyderabad was silently ignored.
      final resolved = GeoIndex.resolve(loc);
      if (resolved != null) location = resolved;
    }
    final q = Uri.base.queryParameters['q'];
    if (q != null && q.trim().isNotEmpty) query = q.trim();
    final go = Uri.base.queryParameters['go'];
    if (go == null || go.isEmpty) return;
    final parts = go.split('/');
    switch (parts[0]) {
      case 'browse':
        if (parts.length > 1 && catById.containsKey(parts[1])) {
          activeCat = parts[1];
          activeDivision = divisionOf(activeCat);
        }
        break;
      case 'division':
        // ?go=division/beauty — land on a division's first category.
        if (parts.length > 1) {
          final cats = catsByDivision[parts[1]];
          if (cats != null && cats.isNotEmpty) {
            activeDivision = parts[1];
            activeCat = cats.first.id;
          }
        }
        break;
      case 'profile':
        final id = parts.length > 1 ? parts[1] : '';
        if (id.isNotEmpty) _openSharedProfile(id);
        break;
      case 'connect':
        // ?go=connect/join — deep link straight to a form.
        if (parts.length > 1 && const ['contact', 'join', 'apply'].contains(parts[1])) {
          connectTab = parts[1];
        }
        view = 'connect';
        break;
      case 'newsletter':
      case 'events':
      case 'about':
      case 'partners':
      case 'team':
      case 'sessions':
        view = parts[0];
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
  ///
  /// [_apiListings] is already scoped to [activeCat] server-side. Two filters
  /// are still applied here:
  ///
  ///   · the free-text [query], because the backend has no search parameter
  ///     and matching client-side is better than no search at all;
  ///   · the geo match, because [location] can now be a STATE, which the
  ///     backend's single `city` parameter cannot express.
  ///
  /// Empty means genuinely no vendors — never backfilled with placeholders.
  /// Narrow a result set to [location] — but ONLY for a state, which is the
  /// one thing the backend's single `city` parameter cannot express.
  ///
  /// Re-filtering a city the backend already filtered would hide any listing
  /// whose city string [geoStates] happens not to list (a vendor in Ghaziabad
  /// browsing "Delhi NCR", say), which is a regression this guard exists to
  /// prevent.
  List<Map<String, dynamic>> _scopedToLocation(List<Map<String, dynamic>> items) {
    if (!GeoIndex.needsClientNarrowing(location)) return items;
    return items
        .where((v) => GeoIndex.matches(selected: location, listingCity: '${v['loc'] ?? ''}'))
        .toList();
  }

  List<Map<String, dynamic>> get catItems {
    var items = _scopedToLocation(_apiListings ?? const <Map<String, dynamic>>[]);

    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((v) {
        final tags = ((v['tags'] as List?) ?? const []).join(' ');
        final haystack = [
          v['name'], v['loc'], v['tagline'], v['badge'], tags,
          catOf(v['cat'] as String?)?.name,
        ].map((e) => '${e ?? ''}').join(' ').toLowerCase();
        return haystack.contains(q);
      }).toList();
    }

    return items;
  }

  /// True when the grid is empty only because a filter is on — so the empty
  /// state can offer to clear it instead of claiming the category is bare.
  bool get filteredToNothing =>
      (_apiListings?.isNotEmpty ?? false) && catItems.isEmpty;

  /// Accepts a city, a state, or [kAllIndia].
  void setLocation(String place) {
    if (location == place) return;
    location = place;
    _apiListings = null; // clear so UI shows a loading state while re-fetching
    notifyListeners();
    fetchListings();
  }

  /// Free-text search. Filters locally and, when the term looks like a place,
  /// also moves the location — typing "Jaipur" should show Jaipur, not zero
  /// results for a vendor literally named Jaipur.
  void setQuery(String q) {
    final next = q.trim();
    if (query == next) return;
    query = next;

    final place = next.isEmpty ? null : GeoIndex.resolve(next);
    if (place != null && place != location) {
      location = place;
      query = ''; // the term was consumed as a location
      _apiListings = null;
      notifyListeners();
      fetchListings();
      return;
    }
    notifyListeners();
  }

  void clearQuery() {
    if (query.isEmpty) return;
    query = '';
    notifyListeners();
  }

  /// Switch the primary rail. Selects the division's first category so the
  /// grid always shows something rather than an empty division.
  void switchDivision(String id) {
    if (activeDivision == id) return;
    activeDivision = id;
    final first = catsByDivision[id];
    if (first != null && first.isNotEmpty) {
      switchCat(first.first.id);
    } else {
      notifyListeners();
    }
  }

  void setNewsVertical(String v) {
    if (newsVertical == v) return;
    newsVertical = v;
    notifyListeners();
  }

  void openConnect(String tab) {
    connectTab = tab;
    view = 'connect';
    notifyListeners();
  }

  /// Submit one of the contact / join / apply forms.
  Future<bool> submitLead(String kind, Map<String, dynamic> payload) async {
    try {
      await _repo.submitLead(kind, payload);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> registerForSession(Session session, Map<String, dynamic> payload) async {
    try {
      await _repo.registerForSession(session.id, payload);
      showToast('Seat requested', '${session.title} — the desk will confirm by email', '🎟️');
      return true;
    } catch (_) {
      showToast('Could not register', 'Try again in a moment', '⚠️');
      return false;
    }
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
  Future<bool> payAdvanceApi(String bookingId, String inquiryRef, String receiptImageUrl) async {
    if (!isLoggedIn) return false;
    try {
      await _repo.payAdvance(bookingId, inquiryRef, receiptImageUrl);
      final i = inquiries.indexWhere((q) => q.ref == inquiryRef);
      if (i != -1) {
        inquiries[i].status = 'Advance submitted';
      }
      notifyListeners();
      showToast('Advance submitted', 'Receipt sent for admin review — slot reserved once approved', '💳');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Opens a profile from a RAW backend vendor payload (ads, updates, search
  /// results) rather than an already-normalised listing map.
  void openVendorById(Map<String, dynamic> vendor) {
    final normalised = _normaliseVendor(vendor);
    activeCat = normalised['cat'] as String;
    activeDivision = divisionOf(activeCat);
    openProfile(normalised);
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
    activeDivision = divisionOf(id);
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
    selectedIssue = null;
    notifyListeners();
  }
}
