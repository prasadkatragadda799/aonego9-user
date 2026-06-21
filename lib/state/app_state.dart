import 'package:flutter/widgets.dart';
import '../data/app_data.dart';

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
  final List<Map<String, dynamic>> vendorProfiles = [];

  /// Inquiries the user has posted — kept so they are trackable end-to-end.
  final List<Inquiry> inquiries = [];

  /// ── Reach / share analytics ───────────────────────────────────
  /// Live increments per profile id. Seeded with a deterministic base so
  /// every profile shows a believable reach; opens and shares add on top.
  /// (A real backend would persist these cross-device — these are the
  /// counters the profile + vendor console read.)
  final Map<String, int> _views = {};
  final Map<String, int> _shares = {};

  int _seed(String id, int span) => id.isEmpty ? 0 : (id.hashCode.abs() % span);

  /// Total views a profile has had (seeded base + live opens).
  int profileViews(String id) => 820 + _seed(id, 1400) + (_views[id] ?? 0);

  /// Total times a profile link was shared (seeded base + live shares).
  int profileShares(String id) => 24 + _seed(id, 70) + (_shares[id] ?? 0);

  /// Overall reach — views plus an amplification per share.
  int profileReach(String id) => profileViews(id) + profileShares(id) * 9;

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
        final found = profiles.firstWhere((p) => p['id'] == id, orElse: () => const {});
        if (found.isNotEmpty) {
          selectedProfile = found;
          view = 'profile';
          activeCat = found['cat'] as String;
          _views[id] = (_views[id] ?? 0) + 1; // arriving via a shared link is a view
        }
        break;
      case 'vendor-auth':
        view = 'vendor-auth';
        break;
      case 'vendor-dash':
        view = 'vendor-dash';
        vendorName = 'Rohan Studio';
        break;
      case 'vendor-edit':
        view = 'vendor-edit';
        break;
    }
  }

  /// allProfiles = static PROFILES + published vendor profiles (mapped).
  List<Map<String, dynamic>> get allProfiles => [
        ...profiles,
        ...vendorProfiles.map((vp) => {
              ...vp,
              'id': 'vp-${vp['name']}',
              'rating': 4.5,
              'reviewCount': 0,
              'verified': false,
              'tags': <String>[],
              'isNew': true,
              'revList': <dynamic>[],
              'stats': [
                {'n': 'New', 'l': 'Profile'},
                {'n': '0', 'l': 'Reviews'},
                {'n': 'Just', 'l': 'Published'},
                {'n': '—', 'l': 'Rating'},
              ],
            }),
      ];

  /// Items in the active category that are available in the chosen location.
  List<Map<String, dynamic>> get catItems =>
      allProfiles.where((p) => p['cat'] == activeCat && servesLocation(p)).toList();

  /// ── Location filtering ────────────────────────────────────────
  /// Normalise a free-text location ("Bandra, Mumbai", "Pan India") to a key.
  String _cityKey(String loc) {
    final l = loc.toLowerCase();
    if (l.contains('mumbai')) return 'mumbai';
    if (l.contains('delhi')) return 'delhi';
    if (l.contains('bangalore') || l.contains('bengaluru')) return 'bangalore';
    if (l.contains('pan india') || l.contains('all india') || l.contains('india')) return 'all';
    return l.trim();
  }

  /// Does this profile serve [city]? Pan-India profiles serve everywhere.
  bool servesCity(Map<String, dynamic> p, String city) {
    if (city == 'All India') return true;
    final pk = _cityKey((p['loc'] ?? '').toString());
    if (pk == 'all') return true;
    return pk == _cityKey(city);
  }

  bool servesLocation(Map<String, dynamic> p) => servesCity(p, location);

  /// Total profiles available in [city] (any category).
  int availableIn(String city) => allProfiles.where((p) => servesCity(p, city)).length;

  /// Profiles available in [city] within [catId] — for location-aware tabs.
  int availableInCat(String city, String catId) =>
      allProfiles.where((p) => p['cat'] == catId && servesCity(p, city)).length;

  void setLocation(String city) {
    if (location == city) return;
    location = city;
    notifyListeners();
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

  /// Pays the advance/deposit that confirms an inquiry and pushes it up the
  /// vendor's queue. The deposit is adjusted against the final bill.
  void payAdvance(String ref) {
    final i = inquiries.indexWhere((q) => q.ref == ref);
    if (i == -1) return;
    inquiries[i].advancePaid = true;
    inquiries[i].status = 'Advance paid';
    notifyListeners();
    showToast('Advance paid', 'Slot reserved with ${inquiries[i].vendorName} · adjusted against final bill', '💳');
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
    notifyListeners();
  }

  void setFilter(String f) {
    filter = f;
    notifyListeners();
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

  void vendorLogin() {
    vendorName = 'Rohan Studio';
    view = 'vendor-dash';
    notifyListeners();
  }

  void publishProfile(Map<String, dynamic> np) {
    vendorProfiles.add({
      ...np,
      'rating': 4.5,
      'reviewCount': 0,
      'verified': false,
      'isNew': true,
      'tags': <String>[],
      'tagline': 'Newly published profile',
      'loc': 'India',
      'badge': 'New Profile',
    });
    view = 'vendor-dash';
    notifyListeners();
    showToast('Profile Published!', 'Your profile is now live on AOneGo9', '🎉');
  }
}
