import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../data/app_data.dart';
import '../data/user_repository.dart';
import '../data/vendor_profile_utils.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/chrome.dart';
import '../widgets/lead_form.dart';
import '../widgets/model_gallery.dart';
import '../widgets/scene_matrix.dart';

/// Full-screen profile view (`.pview`).
class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const ProfileScreen({super.key, required this.profile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final List<String> _tabs;
  late String _tab;
  bool _leadSent = false;
  final _scrollKey = GlobalKey();
  final _repo = UserRepository();

  // Real packages loaded from backend; null = still loading, [] = none/failed
  List<Map<String, dynamic>>? _apiPackages;
  List<Map<String, dynamic>>? _apiPortfolio;
  List<Map<String, dynamic>>? _apiReviews;
  double? _apiReviewAvg;
  late Map<String, dynamic> _mergedProfile;
  bool _detailsLoaded = false;

  Map<String, dynamic> get p => _mergedProfile;
  String get cat => p['cat'] as String? ?? '';
  bool get isModel => cat == 'modelF' || cat == 'modelM';
  bool get isVenue => cat == 'venue';
  bool get isEvent => cat == 'events';
  bool get isVideo => cat == 'video';
  Color get accent => T.ac(cat);

  @override
  void initState() {
    super.initState();
    _mergedProfile = Map<String, dynamic>.from(widget.profile);
    _tabs = isModel
        ? ['Gallery', 'Comp Card', 'Scene Availability', 'Packages', 'Reviews']
        : isEvent
            ? ['Overview', 'Portfolio', 'Packages', 'Reviews']
            : isVenue
                ? ['Spaces', 'Portfolio', 'Packages', 'Availability', 'Reviews']
                : ['Portfolio', 'About', 'Equipment', 'Packages', 'Reviews'];
    _tab = _tabs.first;
    _fetchPackages();
    _fetchPortfolio();
    _fetchReviews();
    _fetchProfileDetails();
    _fetchVendorProfile();
  }

  Future<void> _fetchVendorProfile() async {
    final vendorId = widget.profile['id'] as String? ?? '';
    if (vendorId.isEmpty) return;
    try {
      final v = await _repo.vendorProfile(vendorId);
      if (!mounted) return;
      final galleryUrls = ((v['gallery_urls'] as List?) ?? (v['galleryUrls'] as List?) ?? [])
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
      setState(() {
        _mergedProfile = {
          ..._mergedProfile,
          'galleryUrls': galleryUrls,
          'avatarUrl': (v['avatar_url'] as String?)?.trim().isNotEmpty == true
              ? (v['avatar_url'] as String).trim()
              : _mergedProfile['avatarUrl'],
        };
      });
    } catch (_) {}
  }

  Future<void> _fetchProfileDetails() async {
    final vendorId = widget.profile['id'] as String? ?? '';
    if (vendorId.isEmpty) { setState(() => _detailsLoaded = true); return; }
    try {
      final details = await _repo.vendorProfileDetails(vendorId);
      if (mounted) {
        setState(() {
          _mergedProfile = VendorProfileUtils.mergeDetails(_mergedProfile, details);
          _mergedProfile['stats'] = VendorProfileUtils.buildDefaultStats(_mergedProfile);
          _detailsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _detailsLoaded = true);
    }
  }

  Future<void> _fetchReviews() async {
    final vendorId = p['id'] as String? ?? '';
    if (vendorId.isEmpty) { setState(() { _apiReviews = []; _apiReviewAvg = 0; }); return; }
    try {
      final data = await _repo.vendorReviews(vendorId);
      if (!mounted) return;
      final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final total = (data['total'] as num?)?.toInt() ?? items.length;
      final avg = (data['average_rating'] as num?)?.toDouble() ?? 0;
      setState(() {
        _apiReviews = items.map((r) {
          final stars = (r['stars'] as num?)?.toInt() ?? 0;
          return {
            'author': r['author'] ?? 'Client',
            'role': '',
            'stars': '★' * stars,
            'text': r['text'] ?? '',
          };
        }).toList();
        _apiReviewAvg = avg;
        _mergedProfile = {
          ..._mergedProfile,
          'reviewCount': total,
          if (avg > 0) 'rating': avg,
        };
        _mergedProfile['stats'] = VendorProfileUtils.buildDefaultStats(_mergedProfile);
      });
    } catch (_) {
      if (mounted) setState(() { _apiReviews = []; _apiReviewAvg = 0; });
    }
  }

  Future<void> _fetchPortfolio() async {
    final vendorId = p['id'] as String? ?? '';
    if (vendorId.isEmpty) { setState(() => _apiPortfolio = []); return; }
    try {
      final items = await _repo.vendorPortfolio(vendorId);
      if (mounted) setState(() => _apiPortfolio = items);
    } catch (_) {
      if (mounted) setState(() => _apiPortfolio = []);
    }
  }

  Future<void> _fetchPackages() async {
    final vendorId = p['id'] as String? ?? '';
    if (vendorId.isEmpty) { setState(() => _apiPackages = []); return; }
    try {
      final pkgs = await _repo.vendorPackages(vendorId);
      if (mounted) setState(() => _apiPackages = pkgs);
    } catch (_) {
      if (mounted) setState(() => _apiPackages = []);
    }
  }

  void _toast(String t, String b, String i) => context.read<AppState>().showToast(t, b, i);

  /// Copy the real, shareable deep link to the clipboard and bump share/reach.
  Future<void> _copyLink(AppState app) async {
    final link = app.shareLink(p);
    await Clipboard.setData(ClipboardData(text: link));
    app.recordShare(p['id'] as String? ?? '');
    _toast('Link copied — ready to share', link, '🔗');
  }

  /// "Share" — same shareable link; on a real device this is where the native
  /// share sheet (WhatsApp, etc.) opens. Copies + tracks the share either way.
  Future<void> _share(AppState app, String channel) async {
    final link = app.shareLink(p);
    await Clipboard.setData(ClipboardData(text: link));
    app.recordShare(p['id'] as String? ?? '');
    _toast('$channel share ready', '$link  ·  copied to clipboard', '📤');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tablet = isTablet(context);
    return Container(
      color: T.bg,
      child: Column(
        children: [
          _pnav(app),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: isNarrow(context) ? _pheroNarrow(app) : _phero(app)),
                SliverToBoxAdapter(child: _reachBar(app)),
                if ((p['stats'] as List?)?.isNotEmpty == true) SliverToBoxAdapter(child: _stats()),
                SliverPersistentHeader(pinned: true, delegate: _TabsDelegate(_tabs, _tab, accent, (t) => setState(() => _tab = t))),
                SliverToBoxAdapter(child: _layout(tablet)),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          if (!_leadSent && tablet) _mobBar(),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  // ── reach / share analytics bar ──
  Widget _reachBar(AppState app) {
    final id = p['id'] as String? ?? '';
    final link = app.shareLink(p);
    final metrics = [
      ['👁', _fmt(app.profileViews(id)), 'Profile views'],
      ['↗', _fmt(app.profileReach(id)), 'Total reach'],
      ['🔗', _fmt(app.profileShares(id)), 'Shares'],
    ];
    return Container(
      decoration: const BoxDecoration(color: T.bg, border: Border(bottom: BorderSide(color: T.bdr))),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isNarrow(context) ? 16 : 20, vertical: 12),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 10,
              children: [
                // Wrap, not Row — three metrics on one fixed line overflowed a
                // 375px phone. On mobile the labels also shorten so all three
                // still fit across a single line.
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final m in metrics)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(m[0], style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
                        Text(m[1], style: F.fraunces(size: 16, weight: FontWeight.w700, color: accent, height: 1)),
                        const SizedBox(width: 5),
                        Text(isNarrow(context) ? m[2].split(' ').last : m[2],
                            style: F.syne(size: 11, weight: FontWeight.w400, color: T.mut)),
                      ]),
                  ],
                ),
                // Shareable link pill + copy. Hidden on phones: the raw URL
                // eats the whole row, and "Copy" in the top bar is the same
                // action — so mobile keeps just the three metrics as proof.
                if (!isNarrow(context))
                  HoverFx(
                    onTap: () => _copyLink(app),
                    builder: (h) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: T.surf,
                        border: Border.all(color: h ? accent : T.bdr),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.link, size: 14, color: T.gold),
                        const SizedBox(width: 7),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: Text(link.replaceFirst(RegExp(r'^https?://'), ''),
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: F.mono(size: 10, color: T.mut)),
                        ),
                        const SizedBox(width: 9),
                        Text('Copy link', style: F.syne(size: 11, weight: FontWeight.w700, color: h ? accent : T.text)),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── pnav ──
  Widget _pnav(AppState app) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xF709090B),
        border: Border(bottom: BorderSide(color: T.bdr)),
      ),
      child: Row(
        children: [
          const MenuBtn(),
          const SizedBox(width: 10),
          _PnavBtn(label: isNarrow(context) ? '←' : '← Back', onTap: app.backToBrowse, back: true),
          const SizedBox(width: 12),
          Expanded(
            child: Text(p['name'] ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: F.syne(size: 13, weight: FontWeight.w700, color: T.text)),
          ),
          if (!isNarrow(context)) ...[
            _PnavBtn(label: '🔗 Copy', onTap: () => _copyLink(app)),
            const SizedBox(width: 6),
          ],
          _PnavBtn(label: 'Share', onTap: () => _share(app, 'Profile')),
        ],
      ),
    );
  }

  /// Full-bleed cover art for the mobile hero — the real photo when there is
  /// one, otherwise the category gradient with the emoji at full strength.
  /// (The desktop hero washes the emoji out to 13% as a backdrop; at phone
  /// width that just reads as an empty box.)
  Widget _heroCover() {
    final url = (p['avatarUrl'] as String?)?.trim() ?? '';
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _heroCoverFallback(),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                decoration: BoxDecoration(gradient: T.gr(0)),
                alignment: Alignment.center,
                child: const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: T.gold),
                ),
              ),
      );
    }
    return _heroCoverFallback();
  }

  Widget _heroCoverFallback() => Container(
        decoration: BoxDecoration(gradient: T.gr(0)),
        alignment: Alignment.center,
        child: Text(p['emoji'] ?? '', style: const TextStyle(fontSize: 96)),
      );

  /// Mobile hero — image first.
  ///
  /// The desktop hero stacks eyebrow → name → tagline → meta → rating → three
  /// share chips (one of which is the raw share URL) over a near-invisible
  /// emoji. On a phone that is a wall of text above the fold with nothing to
  /// look at, so this leads with the cover shot and the identity, exactly like
  /// the listing card the user just tapped, and defers everything else.
  Widget _pheroNarrow(AppState app) {
    final catName = cats.firstWhere((c) => c['id'] == cat, orElse: () => {'name': ''})['name'];
    final rating = (p['rating'] as num?)?.toDouble() ?? 0;
    final tagline = (p['tagline'] ?? '').toString();

    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: T.bdr))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Cover + identity ──
          SizedBox(
            height: 320,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _heroCover(),
                // Scrim so the name stays legible over any photo.
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: .62,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xF509090B)],
                        ),
                      ),
                    ),
                  ),
                ),
                if (p['verified'] == true)
                  Positioned(
                    top: 14,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4)),
                      child: Text('✓ VERIFIED',
                          style: F.syne(size: 10, weight: FontWeight.w700, color: T.bg, letterSpacing: .5)),
                    ),
                  ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 14, height: 1.5, color: accent),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text('$catName · ${p['badge']}'.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: F.syne(size: 10, weight: FontWeight.w700, color: accent, letterSpacing: 2)),
                        ),
                      ]),
                      const SizedBox(height: 9),
                      Text(p['name'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: F.fraunces(
                              size: 30, weight: FontWeight.w700, color: Colors.white, letterSpacing: -.8, height: 1.08)),
                      const SizedBox(height: 5),
                      Text('📍 ${p['loc']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: F.syne(size: 12, weight: FontWeight.w600, color: accent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Tagline, proof, share ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tagline.isNotEmpty) ...[
                  Text(tagline, style: F.syne(size: 13.5, weight: FontWeight.w400, color: T.mut, height: 1.6)),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(rating.toStringAsFixed(1),
                          style: F.fraunces(size: 18, weight: FontWeight.w700, color: accent)),
                      const SizedBox(width: 6),
                      Text('★' * rating.floor(),
                          style: TextStyle(color: accent, fontSize: 12, letterSpacing: 1.5)),
                      const SizedBox(width: 6),
                      Text('(${p['reviewCount']})', style: F.syne(size: 12, weight: FontWeight.w400, color: T.dim)),
                    ]),
                    if (VendorProfileUtils.hasText(p['exp']))
                      Text('🎯 ${VendorProfileUtils.displayValue(p['exp'])}',
                          style: F.syne(size: 12, weight: FontWeight.w400, color: T.dim)),
                  ],
                ),
                const SizedBox(height: 14),
                // Share only — the raw share URL chip is dropped here because
                // "Copy" in the top bar already does exactly that.
                Row(children: [
                  _HeroChip(text: '💬 WhatsApp', onTap: () => _share(app, 'WhatsApp')),
                  const SizedBox(width: 8),
                  _HeroChip(text: '📤 Share', onTap: () => _share(app, 'Profile')),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── phero ──
  Widget _phero(AppState app) {
    final catName = cats.firstWhere((c) => c['id'] == cat, orElse: () => {'name': ''})['name'];
    final nameSize = (screenW(context) * 0.05).clamp(26.0, 52.0);
    final pad = (screenW(context) * 0.04).clamp(20.0, 42.0);
    return Container(
      constraints: BoxConstraints(minHeight: isNarrow(context) ? 220 : 280),
      decoration: BoxDecoration(
        gradient: T.gr(0),
        border: const Border(bottom: BorderSide(color: T.bdr)),
      ),
      child: Stack(
        children: [
          // huge faded emoji
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: Center(
              child: Opacity(
                opacity: .13,
                child: Text(p['emoji'] ?? '', style: TextStyle(fontSize: (screenW(context) * 0.16).clamp(110.0, 190.0))),
              ),
            ),
          ),
          // gradient overlay
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF09090B), Color(0x3309090B)],
                  stops: [0.4, 1],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: EdgeInsets.all(pad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (((p['avatarUrl'] as String?)?.trim() ?? '').isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(width: 72, height: 72, child: _profileAvatar(size: 72, emojiSize: 34)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 14, height: 1.5, color: accent),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('$catName · ${p['badge']}'.toUpperCase(),
                            style: F.syne(size: 10, weight: FontWeight.w700, color: accent, letterSpacing: 2.5)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Text(p['name'] ?? '',
                        style: F.fraunces(size: nameSize, weight: FontWeight.w700, color: T.cream, letterSpacing: -1.2, height: 1.04)),
                    const SizedBox(height: 7),
                    Text(p['tagline'] ?? '', style: F.syne(size: 14, weight: FontWeight.w400, color: T.mut, height: 1.65)),
                    const SizedBox(height: 16),
                    Wrap(spacing: 14, runSpacing: 6, children: [
                      Text('📍 ${p['loc']}', style: F.syne(size: 12, weight: FontWeight.w400, color: T.dim)),
                      if (VendorProfileUtils.hasText(p['exp'])) Text('🎯 ${VendorProfileUtils.displayValue(p['exp'])}', style: F.syne(size: 12, weight: FontWeight.w400, color: T.dim)),
                      if (p['verified'] == true) Text('✓ Verified', style: F.syne(size: 12, weight: FontWeight.w400, color: T.grn)),
                    ]),
                    const SizedBox(height: 14),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('${p['rating']}', style: F.fraunces(size: 20, weight: FontWeight.w700, color: accent)),
                      const SizedBox(width: 7),
                      Text('★' * ((p['rating'] as num?)?.floor() ?? 0), style: TextStyle(color: accent, fontSize: 13, letterSpacing: 2)),
                      const SizedBox(width: 7),
                      Text('(${p['reviewCount']} reviews)', style: F.syne(size: 12, weight: FontWeight.w400, color: T.dim)),
                    ]),
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      _HeroChip(text: app.shareLink(p).replaceFirst(RegExp(r'^https?://'), ''), mono: true, onTap: () => _copyLink(app)),
                      _HeroChip(text: '💬 WhatsApp', onTap: () => _share(app, 'WhatsApp')),
                      _HeroChip(text: '📤 Share', onTap: () => _share(app, 'Profile')),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── stats strip ──
  Widget _stats() {
    final stats = (p['stats'] as List).cast<Map>();
    final narrow = screenW(context) <= 480;
    final perRow = narrow || isNarrow(context) ? 2 : 4;
    return Container(
      decoration: const BoxDecoration(color: T.surf, border: Border(bottom: BorderSide(color: T.bdr))),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: LayoutBuilder(builder: (context, bc) {
            final cellW = bc.maxWidth / perRow;
            return Wrap(
              children: [
                for (int i = 0; i < stats.length; i++)
                  Container(
                    width: cellW,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border(right: (i % perRow != perRow - 1) ? const BorderSide(color: T.bdr) : BorderSide.none),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${stats[i]['n']}', style: F.fraunces(size: 22, weight: FontWeight.w700, color: accent, height: 1)),
                        const SizedBox(height: 3),
                        Text('${stats[i]['l']}', style: F.syne(size: 11, weight: FontWeight.w400, color: T.dim)),
                      ],
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ── 2-col layout ──
  Widget _layout(bool tablet) {
    final pad = isNarrow(context) ? 16.0 : 20.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 22, pad, 0),
          child: tablet
              ? Column(key: _scrollKey, children: [_content(), const SizedBox(height: 14), _leadBox()])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _content()),
                    const SizedBox(width: 22),
                    SizedBox(width: 348, child: _leadBox()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _leadBox() {
    return Container(
      key: _scrollKey,
      decoration: BoxDecoration(
        color: T.card,
        border: Border.all(color: T.bdr),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: const BoxDecoration(color: T.surf, border: Border(bottom: BorderSide(color: T.bdr))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Send an Inquiry', style: F.fraunces(size: 19, weight: FontWeight.w700, color: T.cream)),
                const SizedBox(height: 3),
                Text('Posted directly to this profile + AOneGo9 admin. Response within 2–4 hrs.',
                    style: F.syne(size: 12, weight: FontWeight.w400, color: T.mut, height: 1.5)),
                const SizedBox(height: 6),
                Text('→ ${p['name']}', style: F.mono(size: 11, color: accent, )),
                if (p['verified'] == true) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: T.grn.withValues(alpha: .08),
                      border: Border.all(color: T.grn.withValues(alpha: .2)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('✓ Verified Profile', style: F.syne(size: 10, weight: FontWeight.w700, color: T.grn)),
                  ),
                ],
              ],
            ),
          ),
          LeadForm(
            name: p['name'] as String? ?? '',
            cat: cat,
            accent: accent,
            vendorId: p['id'] as String? ?? '',
            onDone: () => setState(() => _leadSent = true),
          ),
        ],
      ),
    );
  }

  Widget _mobBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: const BoxDecoration(
        color: Color(0xF709090B),
        border: Border(top: BorderSide(color: T.bdr)),
      ),
      child: GestureDetector(
        onTap: () => Scrollable.ensureVisible(_scrollKey.currentContext ?? context,
            duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
          child: Text('Send Inquiry →', style: F.syne(size: 14, weight: FontWeight.w700, color: T.bg)),
        ),
      ),
    );
  }

  // ── content dispatcher ──
  Widget _content() {
    switch (_tab) {
      case 'Gallery':
        return Blk(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _profilePhotoGallery(),
          const BlkHeader('Portfolio Gallery'),
          if (_apiPortfolio == null)
            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_apiPortfolio!.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text('No portfolio works yet.', style: F.syne(size: 13, color: T.mut)))
          else
            ModelGallery(items: _apiPortfolio!, accent: accent, onToast: _toast),
        ]));
      case 'Comp Card':
        return _compCard();
      case 'Scene Availability':
        return Blk(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const BlkHeader('Professional Scene Availability'),
          if (!_detailsLoaded)
            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else if (((p['sceneData'] as List?) ?? []).isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text('No scene availability listed yet.', style: F.syne(size: 13, color: T.mut)))
          else
            SceneMatrix(sceneData: (p['sceneData'] as List?)?.cast<Map<String, dynamic>>() ?? [], accent: accent),
        ]));
      case 'Portfolio':
        return _genPortfolio();
      case 'Overview':
        return _overview();
      case 'About':
        return Blk(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const BlkHeader('About'),
          Text(p['overview'] ?? '', style: F.syne(size: 14, weight: FontWeight.w400, color: T.mut, height: 1.75)),
        ]));
      case 'Equipment':
        return _equipment();
      case 'Spaces':
        return _spaces();
      case 'Availability':
        return _availability();
      case 'Packages':
        return _packages();
      case 'Reviews':
        return _reviews();
    }
    return const SizedBox.shrink();
  }

  Widget _compCard() {
    if (!_detailsLoaded) {
      return const Blk(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ));
    }
    final mF = cat == 'modelF';
    final meas = <List<String>>[
      if (VendorProfileUtils.hasText(p['height'])) ['Height', VendorProfileUtils.displayValue(p['height'])],
      if (VendorProfileUtils.hasText(p['weight'])) ['Weight', VendorProfileUtils.displayValue(p['weight'])],
      if (mF && VendorProfileUtils.hasText(p['bust'])) ['Bust', VendorProfileUtils.displayValue(p['bust'])],
      if (!mF && VendorProfileUtils.hasText(p['chest'])) ['Chest', VendorProfileUtils.displayValue(p['chest'])],
      if (VendorProfileUtils.hasText(p['waist'])) ['Waist', VendorProfileUtils.displayValue(p['waist'])],
      if (mF && VendorProfileUtils.hasText(p['hip'])) ['Hip', VendorProfileUtils.displayValue(p['hip'])],
      if (VendorProfileUtils.hasText(p['shoe'])) ['Shoe', VendorProfileUtils.displayValue(p['shoe'])],
      if (p['age'] != null) ['Age', VendorProfileUtils.displayValue(p['age'], suffix: ' yrs')],
    ];
    final bio = <List<String>>[
      if (VendorProfileUtils.hasText(p['skin'])) ['Skin Tone', VendorProfileUtils.displayValue(p['skin'])],
      if (VendorProfileUtils.hasText(p['hair'])) ['Hair', VendorProfileUtils.displayValue(p['hair'])],
      if (VendorProfileUtils.hasText(p['eye'])) ['Eyes', VendorProfileUtils.displayValue(p['eye'])],
      if (VendorProfileUtils.hasText(p['langs'])) ['Languages', VendorProfileUtils.displayValue(p['langs'])],
      if (VendorProfileUtils.hasText(p['training'])) ['Training', VendorProfileUtils.displayValue(p['training'])],
      if (VendorProfileUtils.hasText(p['exp'])) ['Experience', VendorProfileUtils.displayValue(p['exp'])],
    ];
    final measCols = screenW(context) <= 768 ? 2 : 4;
    return Container(
      padding: const EdgeInsets.all(22),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [T.surf, T.bg]),
        border: Border.all(color: T.bdr),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 16, runSpacing: 16, crossAxisAlignment: WrapCrossAlignment.start, children: [
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              color: T.gold.withValues(alpha: .1),
              border: Border.all(color: T.gold.withValues(alpha: .25)),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: _profileAvatar(size: 68, emojiSize: 34),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(p['name'] ?? '', style: F.fraunces(size: 22, weight: FontWeight.w700, color: T.cream)),
            const SizedBox(height: 3),
            Text(((p['tags'] as List?) ?? []).join(' · '), style: F.syne(size: 12, weight: FontWeight.w700, color: accent)),
            const SizedBox(height: 2),
            Text(
              '📍 ${p['loc']}${VendorProfileUtils.hasText(p['exp']) ? ' · ${VendorProfileUtils.displayValue(p['exp'])} experience' : ''}',
              style: F.syne(size: 12, weight: FontWeight.w400, color: T.dim),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: T.surf, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(4)),
              child: Text('AONEGO9.COM REPRESENTED TALENT', style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 1.5)),
            ),
          ]),
        ]),
        const SizedBox(height: 22),
        if (meas.isEmpty && bio.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('No comp card details saved yet.', style: F.syne(size: 13, color: T.mut)),
          ),
        if (meas.isNotEmpty) ...[
        const BlkHeader('Physical Measurements'),
        LayoutBuilder(builder: (context, bc) {
          const gap = 9.0;
          final w = (bc.maxWidth - gap * (measCols - 1)) / measCols;
          return Wrap(spacing: gap, runSpacing: gap, children: [
            for (final m in meas)
              Container(
                width: w,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: T.bg, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Text(m[1], style: F.fraunces(size: 18, weight: FontWeight.w700, color: accent, height: 1)),
                  const SizedBox(height: 3),
                  Text(m[0].toUpperCase(), style: F.syne(size: 10, weight: FontWeight.w400, color: T.dim, letterSpacing: .5)),
                ]),
              ),
          ]);
        }),
        ],
        if (bio.isNotEmpty) ...[
        const SizedBox(height: 18),
        const BlkHeader('Personal & Professional'),
        LayoutBuilder(builder: (context, bc) {
          final twoCol = screenW(context) > 768;
          final colW = twoCol ? (bc.maxWidth - 18) / 2 : bc.maxWidth;
          return Wrap(spacing: 18, children: [
            for (final b in bio)
              Container(
                width: colW,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: T.bdr))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b[0], style: F.syne(size: 11, weight: FontWeight.w400, color: T.mut)),
                    const Spacer(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(b[1], maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right,
                          style: F.syne(size: 12, weight: FontWeight.w700, color: T.text)),
                    ),
                  ],
                ),
              ),
          ]);
        }),
        ],
      ]),
    );
  }

  Widget _profilePhotoGallery() {
    final gallery = (p['galleryUrls'] as List?)?.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList() ?? const <String>[];
    if (gallery.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const BlkHeader('Profile Photos'),
      SizedBox(
        height: 112,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: gallery.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              gallery[i],
              width: 112,
              height: 112,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 112,
                height: 112,
                color: T.card,
                alignment: Alignment.center,
                child: Text(p['emoji'] ?? '', style: const TextStyle(fontSize: 28)),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
    ]);
  }

  Widget _profileAvatar({required double size, double emojiSize = 80}) {
    final url = (p['avatarUrl'] as String?)?.trim() ?? '';
    if (url.isNotEmpty) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: Text(p['emoji'] ?? '', style: TextStyle(fontSize: emojiSize)),
        ),
      );
    }
    return Center(child: Text(p['emoji'] ?? '', style: TextStyle(fontSize: emojiSize)));
  }

  Widget _genPortfolio() {
    final port = (_apiPortfolio ?? (p['portfolio'] as List?)?.cast<Map<String, dynamic>>() ?? []);
    if (_apiPortfolio == null) {
      return const Blk(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ));
    }
    if (port.isEmpty) {
      return Blk(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('No portfolio works yet.', style: F.syne(size: 13, color: T.mut)),
      ));
    }
    final cols = screenW(context) <= 480 ? 1 : (screenW(context) <= 768 ? 2 : 3);
    return Blk(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _profilePhotoGallery(),
      const BlkHeader('Portfolio Gallery'),
      LayoutBuilder(builder: (context, bc) {
        const gap = 10.0;
        final w = (bc.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (int i = 0; i < port.length; i++)
            SizedBox(
              width: w,
              child: HoverFx(
                // Was a "Full view" toast that never opened one. Photographers,
                // videographers, venues and event profiles all land here, so
                // four of six categories had no way to actually see a shot.
                onTap: () => openPortfolioLightbox(
                  context,
                  items: port,
                  index: i,
                  accent: accent,
                  onToast: _toast,
                ),
                builder: (h) => AspectRatio(
                  aspectRatio: .78,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    transform: h ? (Matrix4.identity()..scaleByDouble(1.02, 1.02, 1.02, 1)) : Matrix4.identity(),
                    transformAlignment: Alignment.center,
                    decoration: BoxDecoration(border: Border.all(color: h ? T.gold : T.bdr), borderRadius: BorderRadius.circular(9)),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(fit: StackFit.expand, children: [
                      portfolioCoverImage(port[i], emojiSize: 40),
                      Positioned(
                        top: 9, left: 9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xD909090B), borderRadius: BorderRadius.circular(3)),
                          child: Text('${port[i]['label']}'.toUpperCase(), style: F.syne(size: 10, weight: FontWeight.w700, color: T.gold, letterSpacing: 1.2)),
                        ),
                      ),
                      if (h)
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xE0000000)], stops: [.4, 1]),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                              Text(port[i]['label'] ?? '', style: F.syne(size: 12, weight: FontWeight.w700, color: Colors.white)),
                              const SizedBox(height: 2),
                              Text(port[i]['sub'] ?? '', style: F.syne(size: 10, weight: FontWeight.w400, color: Colors.white.withValues(alpha: .5))),
                            ]),
                          ),
                        ),
                    ]),
                  ),
                ),
              ),
            ),
        ]);
      }),
    ]));
  }

  Widget _overview() {
    if (!_detailsLoaded) {
      return const Blk(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ));
    }
    final services = (p['services'] as List?)?.cast<String>() ?? [];
    final overview = p['overview'] as String? ?? '';
    if (overview.isEmpty && services.isEmpty) {
      return Blk(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('No overview or services listed yet.', style: F.syne(size: 13, color: T.mut)),
      ));
    }
    const svcIcons = ['🎭', '🏆', '🏢', '🚀', '🎵', '🎓', '💒', '🎤'];
    return Column(children: [
      if (overview.isNotEmpty)
        Blk(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const BlkHeader('About'),
          Text(overview, style: F.syne(size: 14, weight: FontWeight.w400, color: T.mut, height: 1.75)),
        ])),
      if (services.isNotEmpty)
        Blk(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const BlkHeader('Services We Manage'),
          Wrap(spacing: 7, runSpacing: 7, children: [
            for (int i = 0; i < services.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: T.surf, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(6)),
                child: Text('${svcIcons[i % 8]} ${services[i]}', style: F.syne(size: 12, weight: FontWeight.w600, color: T.mut)),
              ),
          ]),
        ])),
    ]);
  }

  Widget _equipment() {
    if (!_detailsLoaded) {
      return const Blk(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ));
    }
    final reels = (p['reels'] as List?)?.cast<Map>() ?? [];
    final equip = (p['equipment'] as List?)?.cast<Map>() ?? [];
    if (reels.isEmpty && equip.isEmpty) {
      return Blk(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('No equipment or showreels listed yet.', style: F.syne(size: 13, color: T.mut)),
      ));
    }
    return Column(children: [
      if (isVideo && reels.isNotEmpty)
        Blk(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const BlkHeader('Showreels & Samples'),
          for (final r in reels)
            HoverFx(
              onTap: () => _toast('Playing reel', r['name'] ?? '', '▶️'),
              builder: (h) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: T.surf, border: Border.all(color: h ? T.gold : T.bdr), borderRadius: BorderRadius.circular(9)),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: T.gold.withValues(alpha: .1), border: Border.all(color: T.gold.withValues(alpha: .2)), borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: Text(r['e'] ?? '▶', style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(r['name'] ?? '', style: F.syne(size: 13, weight: FontWeight.w700, color: T.text)),
                      const SizedBox(height: 3),
                      Text(r['type'] ?? '', style: F.syne(size: 10, weight: FontWeight.w700, color: accent)),
                    ]),
                  ),
                  Text(r['dur'] ?? '', style: F.mono(size: 11, color: T.dim)),
                ]),
              ),
            ),
        ])),
      if (equip.isNotEmpty)
        Blk(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const BlkHeader('Equipment & Technology'),
          for (int i = 0; i < equip.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(border: Border(bottom: i == equip.length - 1 ? BorderSide.none : const BorderSide(color: T.bdr))),
              child: Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: T.gold.withValues(alpha: .1), border: Border.all(color: T.gold.withValues(alpha: .18)), borderRadius: BorderRadius.circular(6)),
                  alignment: Alignment.center,
                  child: Text(equip[i]['e'] ?? '', style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(equip[i]['name'] ?? '', style: F.syne(size: 13, weight: FontWeight.w700, color: T.text)),
                    const SizedBox(height: 2),
                    Text(equip[i]['note'] ?? '', style: F.syne(size: 11, weight: FontWeight.w400, color: T.dim)),
                  ]),
                ),
              ]),
            ),
        ])),
    ]);
  }

  Widget _spaces() {
    if (!_detailsLoaded) {
      return const Blk(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ));
    }
    final spaces = (p['spaces'] as List?)?.cast<Map>() ?? [];
    final amenities = (p['amenities'] as List?)?.cast<String>() ?? [];
    if (spaces.isEmpty && amenities.isEmpty) {
      return Blk(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('No spaces or amenities listed yet.', style: F.syne(size: 13, color: T.mut)),
      ));
    }
    final twoCol = screenW(context) > 768;
    return Column(children: [
      Blk(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const BlkHeader('Event Spaces'),
        LayoutBuilder(builder: (context, bc) {
          const gap = 11.0;
          final w = twoCol ? (bc.maxWidth - gap) / 2 : bc.maxWidth;
          return Wrap(spacing: gap, runSpacing: gap, children: [
            for (int i = 0; i < spaces.length; i++)
              SizedBox(
                width: w,
                child: HoverFx(
                  onTap: () => _toast('Space noted', spaces[i]['name'] ?? '', '🏛️'),
                  builder: (h) => Container(
                    decoration: BoxDecoration(color: T.surf, border: Border.all(color: h ? T.gold : T.bdr), borderRadius: BorderRadius.circular(10)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Container(
                        height: 72,
                        decoration: BoxDecoration(gradient: T.gr((spaces[i]['bg'] as int?) ?? i)),
                        alignment: Alignment.center,
                        child: Text(spaces[i]['e'] ?? '', style: const TextStyle(fontSize: 28)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Text(spaces[i]['name'] ?? '', style: F.syne(size: 13, weight: FontWeight.w700, color: T.text)),
                          const SizedBox(height: 3),
                          Text(spaces[i]['cap'] ?? '', style: F.syne(size: 11, weight: FontWeight.w400, color: T.dim)),
                          const SizedBox(height: 7),
                          Text(spaces[i]['price'] ?? '', style: F.fraunces(size: 19, weight: FontWeight.w700, color: accent)),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
          ]);
        }),
      ])),
      Blk(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const BlkHeader('Amenities & Facilities'),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final a in amenities)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: T.surf, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(4)),
              child: Text('✓ $a', style: F.syne(size: 11, weight: FontWeight.w600, color: T.mut)),
            ),
        ]),
      ])),
    ]);
  }

  Widget _availability() {
    if (!_detailsLoaded) {
      return const Blk(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ));
    }
    final avail = (p['avail'] as List?)?.cast<String>() ?? [];
    if (avail.isEmpty) {
      return Blk(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('No availability calendar published yet.', style: F.syne(size: 13, color: T.mut)),
      ));
    }
    final legend = [
      [T.grn, T.grn.withValues(alpha: .3), 'Open'],
      [T.redText, T.red.withValues(alpha: .2), 'Booked'],
      [accent, accent.withValues(alpha: .13), 'Today'],
    ];
    return Blk(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const BlkHeader('Availability Calendar — This Month'),
      Wrap(spacing: 14, runSpacing: 8, children: [
        for (final l in legend)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: l[1] as Color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 5),
            Text(l[2] as String, style: F.syne(size: 11, weight: FontWeight.w400, color: l[0] as Color)),
          ]),
      ]),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        children: [
          for (final d in 'SMTWTFS'.split(''))
            Center(child: Text(d, style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: .5))),
          for (int i = 0; i < avail.length; i++) _availDay(i + 1, avail[i]),
        ],
      ),
    ]));
  }

  Widget _availDay(int n, String s) {
    Color bg = Colors.transparent, border = Colors.transparent, fg = T.dim;
    if (s == 'open') {
      bg = T.grn.withValues(alpha: .1); border = T.grn.withValues(alpha: .22); fg = T.grn;
    } else if (s == 'busy') {
      bg = T.red.withValues(alpha: .07); border = T.red.withValues(alpha: .18); fg = T.redText;
    } else if (s == 'today') {
      border = T.gold; fg = T.gold;
    }
    return Opacity(
      opacity: s == 'busy' ? .7 : 1,
      child: Container(
        decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(5)),
        alignment: Alignment.center,
        child: Text('$n', style: F.mono(size: 10, color: fg, )),
      ),
    );
  }

  Widget _packages() {
    // Prefer live backend packages; fall back to static profile data while loading
    final pkgs = (_apiPackages ?? (p['packages'] as List?)?.cast<Map>() ?? []);
    final featTwoCol = screenW(context) > 768;
    return Blk(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const BlkHeader('Packages & Pricing'),
      if (_apiPackages == null)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        )
      else if (pkgs.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text('No packages listed yet.', style: F.syne(size: 13, color: T.mut)),
        )
      else for (final pk in pkgs)
        HoverFx(
          onTap: () => _toast('Package noted', pk['name'] ?? '', '✓'),
          builder: (h) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: pk['pop'] == true ? T.gold.withValues(alpha: .04) : null,
              border: Border.all(color: (pk['pop'] == true || h) ? T.gold : T.bdr),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: T.bdr))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(pk['name'] ?? '', style: F.syne(size: 14, weight: FontWeight.w700, color: T.cream)),
                    const SizedBox(height: 4),
                    Text.rich(TextSpan(children: [
                      TextSpan(text: pk['price'], style: F.fraunces(size: 26, weight: FontWeight.w700, color: accent)),
                      TextSpan(text: pk['span'] ?? '', style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut)),
                    ])),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  child: _featGrid((pk['feats'] as List).cast<String>(), featTwoCol, check: false),
                ),
              ]),
              if (pk['pop'] == true)
                Positioned(
                  top: 14, right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(20)),
                    child: Text('POPULAR', style: F.syne(size: 10, weight: FontWeight.w700, color: T.bg, letterSpacing: 1)),
                  ),
                ),
            ]),
          ),
        ),
    ]));
  }

  Widget _featGrid(List<String> feats, bool twoCol, {required bool check}) {
    return LayoutBuilder(builder: (context, bc) {
      final colW = twoCol ? (bc.maxWidth - 16) / 2 : bc.maxWidth;
      return Wrap(spacing: 16, children: [
        for (final f in feats)
          SizedBox(
            width: colW,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(check ? '✓ ' : '— ', style: TextStyle(fontSize: check ? 11 : 10, color: accent, fontWeight: FontWeight.w700)),
                Expanded(child: Text(f, style: F.syne(size: 12, weight: FontWeight.w400, color: T.mut, height: 1.45))),
              ]),
            ),
          ),
      ]);
    });
  }

  Widget _reviews() {
    if (_apiReviews == null) {
      return const Blk(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ));
    }
    final revs = _apiReviews!;
    final avgRating = _apiReviewAvg ?? ((p['rating'] as num?)?.toDouble() ?? 0);
    final reviewCount = revs.length;
    if (revs.isEmpty) {
      return Blk(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('No reviews yet.', style: F.syne(size: 13, color: T.mut)),
      ));
    }
    final bd = _starDistribution(revs);
    final twoCol = screenW(context) > 768;
    return Column(children: [
      // summary
      Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: T.surf, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(10)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(avgRating.toStringAsFixed(1), style: F.fraunces(size: 52, weight: FontWeight.w700, color: accent, height: 1)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final row in bd)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(children: [
                    SizedBox(width: 18, child: Text('${row[0]}★', textAlign: TextAlign.right, style: F.syne(size: 10, weight: FontWeight.w400, color: T.dim))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(value: row[1] / 100, minHeight: 4, backgroundColor: T.bdr, color: accent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(width: 22, child: Text('${(reviewCount * row[1] / 100).round()}', style: F.mono(size: 10, color: T.dim))),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
      // grid
      LayoutBuilder(builder: (context, bc) {
        const gap = 11.0;
        final w = twoCol ? (bc.maxWidth - gap) / 2 : bc.maxWidth;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final r in revs) SizedBox(width: w, child: _reviewCard(r)),
        ]);
      }),
    ]);
  }

  List<List<int>> _starDistribution(List<Map<String, dynamic>> revs) {
    final counts = List<int>.filled(5, 0);
    for (final r in revs) {
      final stars = (r['stars'] as String? ?? '').length.clamp(0, 5);
      if (stars > 0) counts[stars - 1]++;
    }
    final total = revs.length;
    return [
      for (var i = 4; i >= 0; i--)
        [i + 1, total == 0 ? 0 : ((counts[i] * 100) / total).round()],
    ];
  }

  Widget _reviewCard(Map r) {
    final initials = (r['author'] as String).split(' ').map((w) => w.isEmpty ? '' : w[0]).join();
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: T.surf, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: T.gold.withValues(alpha: .12), border: Border.all(color: T.gold.withValues(alpha: .2)), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text(initials.length > 2 ? initials.substring(0, 2) : initials, style: F.fraunces(size: 13, weight: FontWeight.w700, color: accent)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(r['author'] ?? '', style: F.syne(size: 12, weight: FontWeight.w700, color: T.text)),
              const SizedBox(height: 2),
              Text(r['role'] ?? '', style: F.syne(size: 10, weight: FontWeight.w400, color: T.dim, height: 1.4)),
            ]),
          ),
          const SizedBox(width: 8),
          Text(r['stars'] ?? '', style: TextStyle(fontSize: 11, color: accent, letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 9),
        Text('"${r['text']}"', style: F.syne(size: 12, weight: FontWeight.w400, color: T.mut, height: 1.65).copyWith(fontStyle: FontStyle.italic)),
        if (r['tag'] != null) ...[
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: T.gold.withValues(alpha: .07), border: Border.all(color: T.gold.withValues(alpha: .15)), borderRadius: BorderRadius.circular(20)),
            child: Text(r['tag'], style: F.syne(size: 10, weight: FontWeight.w600, color: accent)),
          ),
        ],
      ]),
    );
  }
}

// ── shared small widgets ──
class _PnavBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool back;
  const _PnavBtn({required this.label, required this.onTap, this.back = false});
  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          padding: EdgeInsets.symmetric(horizontal: back ? 14 : 12, vertical: back ? 6 : 5),
          decoration: BoxDecoration(
            color: back ? null : Colors.white.withValues(alpha: .03),
            border: Border.all(color: h ? (back ? T.bdhi : T.gold) : T.bdr),
            borderRadius: BorderRadius.circular(back ? 6 : 5),
          ),
          child: Text(label,
              style: F.syne(size: back ? 12 : 11, weight: FontWeight.w600, color: h ? (back ? T.text : T.gold) : T.mut)),
        ),
      );
}

class _HeroChip extends StatelessWidget {
  final String text;
  final bool mono;
  final VoidCallback onTap;
  const _HeroChip({required this.text, this.mono = false, required this.onTap});
  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .04),
            border: Border.all(color: h ? (mono ? T.gold : T.bdhi) : Colors.white.withValues(alpha: .08)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(text,
              style: mono
                  ? F.mono(size: 10, color: T.gold)
                  : F.syne(size: 11, weight: FontWeight.w600, color: h ? T.text : T.mut)),
        ),
      );
}

/// Sticky profile tabs.
class _TabsDelegate extends SliverPersistentHeaderDelegate {
  final List<String> tabs;
  final String active;
  final Color accent;
  final ValueChanged<String> onTap;
  _TabsDelegate(this.tabs, this.active, this.accent, this.onTap);

  @override
  double get minExtent => 47;
  @override
  double get maxExtent => 47;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(color: T.surf, border: Border(bottom: BorderSide(color: T.bdr))),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final t in tabs)
                  HoverFx(
                    onTap: () => onTap(t),
                    builder: (h) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: t == active ? accent : Colors.transparent, width: 2)),
                      ),
                      child: Text(t, style: F.syne(size: 13, weight: FontWeight.w600, color: t == active ? accent : (h ? T.text : T.mut))),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabsDelegate old) => old.active != active || old.accent != accent;
}
