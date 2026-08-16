import 'dart:async';

import 'package:flutter/material.dart';
// Prefixed: this file also uses the app's own `Ticker` marquee widget.
import 'package:flutter/scheduler.dart' as sched;
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../data/app_data.dart';
import '../state/app_state.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/ticker.dart';
import '../widgets/listing_card.dart';
import '../widgets/footer.dart';

/// Browse view — ticker, nav, hero, category rail, filters, listing grid.
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final accent = T.ac(app.activeCat);
    final catInfo = cats.firstWhere((c) => c['id'] == app.activeCat, orElse: () => cats.first);
    final hero = heroCopy[app.activeCat] ?? heroCopy['venue']!;
    final items = app.catItems;
    final w = screenW(context);

    return Container(
      color: T.bg,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: Ticker(accent: accent)),
          SliverPersistentHeader(pinned: true, delegate: _NavDelegate(app, accent, app.location, w)),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: _hero(context, accent, catInfo, hero),
              ),
            ),
          ),
          // The category rail is now the ONLY category switcher — the nav used
          // to repeat the same six links right above it. Pinned, because
          // dropping the nav copy would otherwise leave no way to change
          // category once you scroll past the hero.
          SliverPersistentHeader(pinned: true, delegate: _RailDelegate(app, accent, w)),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _listBar(context, app, accent, catInfo, items.length),
                    _grid(context, app, accent, items, w),
                    const SizedBox(height: 72),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SiteFooter()),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, Color accent, Map cat, Map hero) {
    final pad = isNarrow(context) ? 16.0 : 20.0;
    final hSize = (screenW(context) * 0.06).clamp(32.0, 64.0);
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, isNarrow(context) ? 36 : 48, pad, isNarrow(context) ? 22 : 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeUp(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 16, height: 1.5, color: accent),
                const SizedBox(width: 8),
                Text('${cat['icon']} ${cat['name']}'.toUpperCase(),
                    style: F.syne(size: 10, weight: FontWeight.w700, color: accent, letterSpacing: 2.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FadeUp(
            delay: const Duration(milliseconds: 70),
            child: Text.rich(
              TextSpan(
                style: F.fraunces(size: hSize, weight: FontWeight.w700, color: T.cream, height: 1.04, letterSpacing: -1.5),
                children: [
                  TextSpan(text: hero['h1']),
                  TextSpan(text: hero['h2'], style: F.fraunces(size: hSize, weight: FontWeight.w700, color: accent, height: 1.04, letterSpacing: -1.5, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeUp(
            delay: const Duration(milliseconds: 140),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Text(hero['sub'], style: F.syne(size: 15, weight: FontWeight.w400, color: T.mut, height: 1.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listBar(BuildContext context, AppState app, Color accent, Map cat, int count) {
    final fs = app.filtersFor(app.activeCat);
    return Padding(
      padding: EdgeInsets.fromLTRB(isNarrow(context) ? 16 : 20, 16, isNarrow(context) ? 16 : 20, 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 10,
        spacing: 10,
        children: [
          // Constrained so a long category + city string wraps instead of
          // overflowing the row on a phone.
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenW(context) - (isNarrow(context) ? 32 : 40)),
            child: Text('$count available · ${cat['name']} · 📍 ${app.location}',
                style: F.mono(size: 11, color: T.dim)),
          ),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final f in fs) _FilterChip(label: f, active: app.filter == f, accent: accent, onTap: () => app.setFilter(f)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context, AppState app, Color accent, List<Map<String, dynamic>> items, double w) {
    final pad = isNarrow(context) ? 16.0 : 20.0;
    if (items.isEmpty && app.listingsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: T.gold)),
      );
    }
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📍', style: TextStyle(fontSize: 30)),
              const SizedBox(height: 10),
              Text('Nothing in this category in ${app.location} yet',
                  style: F.syne(size: 14, weight: FontWeight.w600, color: T.mut)),
              const SizedBox(height: 6),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => app.setLocation('All India'),
                    child: Text('See all India  ', style: F.syne(size: 13, weight: FontWeight.w700, color: accent)),
                  ),
                  Text('·  ', style: F.syne(size: 13, weight: FontWeight.w400, color: T.dim)),
                  GestureDetector(
                    onTap: () => app.setView('vendor-auth'),
                    child: Text('Add yours →', style: F.syne(size: 13, weight: FontWeight.w700, color: accent)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    // grid-template-columns: repeat(auto-fill, minmax(275px,1fr))
    final avail = (w.clamp(0, 1280)) - pad * 2;
    int cols = (avail / 275).floor().clamp(1, 5);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad),
      child: LayoutBuilder(builder: (context, bc) {
        const gap = 20.0;
        final cardW = (bc.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: cardW,
                child: ListingCard(
                  item: item,
                  onView: () => app.openProfile(item),
                  availIn: app.location == 'All India' ? null : app.location,
                ),
              ),
          ],
        );
      }),
    );
  }
}

/// Sticky nav header.
class _NavDelegate extends SliverPersistentHeaderDelegate {
  final AppState app;
  final Color accent;
  final String location;

  /// Carried so [shouldRebuild] fires on resize — the nav's responsive
  /// breakpoints are read inside [build], and without this the header would
  /// keep a stale desktop/mobile layout after the window changed size.
  final double width;
  _NavDelegate(this.app, this.accent, this.location, this.width);

  @override
  double get minExtent => 58;
  @override
  double get maxExtent => 58;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final narrow = isNarrow(context);
    // Category links used to live here too, duplicating the rail immediately
    // below. They are gone: the pinned rail is the single category switcher,
    // and it carries live per-category counts the nav links never had.
    final showVendorBtn = screenW(context) > 880;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF709090B),
        border: Border(bottom: BorderSide(color: T.bdr)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Logo — the brand mark, home affordance.
                Tooltip(
                  message: 'AOneGo9 — back to browse',
                  child: HoverFx(
                    onTap: () => app.switchCat('modelF'),
                    builder: (h) => AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: h ? .82 : 1,
                      child: BrandLogo(size: narrow ? 17 : 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Location picker — the whole marketplace filters to this city.
                _LocationChip(app: app, compact: narrow),
                const SizedBox(width: 8),
                const Spacer(),
                const SizedBox(width: 8),
                // Right
                if (showVendorBtn) ...[
                  _GhostBtn(label: 'Vendor Portal', onTap: () => app.setView('vendor-auth')),
                  const SizedBox(width: 8),
                ],
                _GhostBtn(
                  label: app.isLoggedIn ? (app.currentUser?['name']?.toString().split(' ').first ?? 'Account') : 'Sign In',
                  onTap: () => app.setView('account'),
                ),
                const SizedBox(width: 8),
                _GoldBtn(
                  label: 'Enquire',
                  color: accent,
                  onTap: () => app.showToast('Browse profiles', 'Click any card to view profile + inquiry form', '👇'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _NavDelegate old) =>
      old.app.activeCat != app.activeCat ||
      old.accent != accent ||
      old.location != location ||
      old.width != width ||
      old.app.isLoggedIn != app.isLoggedIn;
}

/// Pinned category rail — the app's primary category switcher.
///
/// Replaces the six duplicate links that used to sit in the nav bar directly
/// above it. Pinning keeps categories reachable after the hero scrolls away,
/// which is what the nav copy was doing.
class _RailDelegate extends SliverPersistentHeaderDelegate {
  final AppState app;
  final Color accent;
  final double width;
  _RailDelegate(this.app, this.accent, this.width);

  @override
  double get minExtent => 86;
  @override
  double get maxExtent => 86;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF709090B),
        border: Border(bottom: BorderSide(color: T.bdr)),
      ),
      alignment: Alignment.center,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: _CategoryRail(app: app),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _RailDelegate old) =>
      old.app.activeCat != app.activeCat || old.accent != accent || old.width != width;
}

/// The scrolling row of category tabs.
///
/// Stateful for two reasons, both about keeping the *other* categories present
/// in the user's mind once one is selected:
///   1. edge fades signal that the row continues past the viewport, which is
///      the only cue on a phone that more categories exist off-screen;
///   2. selecting a category scrolls that tab into view, so switching from the
///      footer or a deep link never leaves the rail parked somewhere unrelated.
class _CategoryRail extends StatefulWidget {
  final AppState app;
  const _CategoryRail({required this.app});
  @override
  State<_CategoryRail> createState() => _CategoryRailState();
}

class _CategoryRailState extends State<_CategoryRail> with SingleTickerProviderStateMixin {
  final _sc = ScrollController();
  final _keys = {for (final c in cats) c['id'] as String: GlobalKey()};
  late String _lastCat = widget.app.activeCat;
  bool _more = false;
  bool _before = false;

  // ── Slow auto-scroll ──────────────────────────────────────────────
  // The rail drifts gently end-to-end so every category is seen without the
  // user having to discover that it scrolls. It ping-pongs rather than looping,
  // because a seamless loop would mean duplicating the tabs — and duplicate
  // category tabs are ambiguous to tap and break the per-tab keys.
  // Deliberately slow: this is ambient "there is more over here" motion, not a
  // marquee. The speed carries the calm; the end pause is kept short so the
  // rail reads as continuously drifting rather than stopping and starting.
  static const double _driftPxPerSecond = 7;
  static const double _edgeHoldSeconds = 0.5;

  sched.Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  double _hold = _edgeHoldSeconds; // settle before the first drift
  int _dir = 1;
  bool _paused = false;
  bool _reduceMotion = false;
  Timer? _resumeTimer;

  @override
  void initState() {
    super.initState();
    _sc.addListener(_syncEdges);
    // Deliberately no _reveal() on mount. The default category is the 4th of
    // six, so centring it on first paint would scroll Event Venues and
    // Photography off-screen before the user has seen the rail at all. Landing
    // at the start shows the list in order; the edge fade advertises the rest.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncEdges());
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _resumeTimer?.cancel();
    _sc.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    var dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0) return;
    // Clamp long frames rather than discarding them. A backgrounded tab throttles
    // rAF and produces huge deltas; clamping keeps the rail from lurching, while
    // discarding (the obvious alternative) stalls the drift completely on any
    // host that renders below 4fps.
    if (dt > 1 / 30) dt = 1 / 30;
    if (_paused || _reduceMotion || !_sc.hasClients) return;

    final max = _sc.position.maxScrollExtent;
    if (max <= 0) return; // everything already fits — nothing to reveal
    if (_hold > 0) {
      _hold -= dt;
      return;
    }

    var next = _sc.offset + _dir * _driftPxPerSecond * dt;
    if (next >= max) {
      next = max;
      _dir = -1;
      _hold = _edgeHoldSeconds;
    } else if (next <= 0) {
      next = 0;
      _dir = 1;
      _hold = _edgeHoldSeconds;
    }
    _sc.jumpTo(next);
  }

  /// Stop drifting while the user is doing something, and for a beat after.
  void _pauseDrift() {
    _resumeTimer?.cancel();
    _paused = true;
  }

  void _resumeDrift([Duration after = const Duration(seconds: 3)]) {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(after, () {
      if (mounted) _paused = false;
    });
  }

  void _syncEdges() {
    if (!_sc.hasClients) return;
    final more = _sc.offset < _sc.position.maxScrollExtent - 1;
    final before = _sc.offset > 1;
    if (more != _more || before != _before) {
      setState(() {
        _more = more;
        _before = before;
      });
    }
  }

  /// Bring the selected tab fully into view, centred where possible.
  ///
  /// Driven off the rail's own controller rather than
  /// `Scrollable.ensureVisible`, which walks every ancestor scrollable and
  /// would scroll the page vertically as a side effect of a category tap.
  void _reveal() {
    if (!_sc.hasClients) return;
    final ctx = _keys[widget.app.activeCat]?.currentContext;
    final rail = context.findRenderObject() as RenderBox?;
    final tab = ctx?.findRenderObject() as RenderBox?;
    if (rail == null || tab == null || !rail.hasSize || !tab.hasSize) return;

    final dx = tab.localToGlobal(Offset.zero, ancestor: rail).dx;
    final target = _sc.offset + dx - (rail.size.width - tab.size.width) / 2;
    _sc.animateTo(
      target.clamp(0.0, _sc.position.maxScrollExtent),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // `app` is a single ChangeNotifier instance, so didUpdateWidget can't see a
    // category change — track it here instead.
    if (_lastCat != widget.app.activeCat) {
      _lastCat = widget.app.activeCat;
      _pauseDrift();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reveal();
        _syncEdges();
      });
      // Long enough that the recentre animation lands and the user can read
      // their choice before the rail starts moving again.
      _resumeDrift(const Duration(seconds: 5));
    }

    // Users who asked their OS to reduce motion get a static rail. Held in its
    // own flag rather than forcing `_paused`, so the drift comes back if the
    // preference is switched off mid-session instead of latching off forever.
    _reduceMotion = MediaQuery.of(context).disableAnimations;

    final pad = isNarrow(context) ? 16.0 : 20.0;
    return MouseRegion(
      // Drifting out from under a cursor that is about to click is the fastest
      // way to make this feel broken, so hovering halts it immediately.
      onEnter: (_) => _pauseDrift(),
      onExit: (_) => _resumeDrift(const Duration(milliseconds: 1200)),
      child: Listener(
        // Touch + manual scroll: hold still while the finger is down, then wait
        // before taking over again.
        onPointerDown: (_) => _pauseDrift(),
        onPointerUp: (_) => _resumeDrift(),
        onPointerCancel: (_) => _resumeDrift(),
        // Wheel/trackpad: pause AND schedule the resume in one go — a signal
        // has no matching "up" event to resume from.
        onPointerSignal: (_) {
          _pauseDrift();
          _resumeDrift();
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _sc,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: Row(
                children: [
                  for (final c in cats) ...[
                    _CTab(
                      key: _keys[c['id'] as String],
                      cat: c,
                      active: widget.app.activeCat == c['id'],
                      count: widget.app.knownCategoryCount(c['id'] as String),
                      onTap: () => widget.app.switchCat(c['id'] as String),
                    ),
                    const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
            // Fades that say "there is more this way".
            _EdgeFade(visible: _before, left: true),
            _EdgeFade(visible: _more, left: false),
          ],
        ),
      ),
    );
  }
}

class _EdgeFade extends StatelessWidget {
  final bool visible;
  final bool left;
  const _EdgeFade({required this.visible, required this.left});

  @override
  Widget build(BuildContext context) => Positioned(
        left: left ? 0 : null,
        right: left ? null : 0,
        top: 0,
        bottom: 0,
        child: IgnorePointer(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: visible ? 1 : 0,
            child: Container(
              width: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: left ? Alignment.centerLeft : Alignment.centerRight,
                  end: left ? Alignment.centerRight : Alignment.centerLeft,
                  colors: const [Color(0xF709090B), Color(0x0009090B)],
                ),
              ),
            ),
          ),
        ),
      );
}

class _GhostBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: T.gold.withValues(alpha: .06),
            border: Border.all(color: T.gold.withValues(alpha: .3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label, style: F.syne(size: 12, weight: FontWeight.w700, color: T.gold)),
        ),
      );
}

class _GoldBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _GoldBtn({required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
          child: Text(label, style: F.syne(size: 12, weight: FontWeight.w700, color: T.bg)),
        ),
      );
}

class _CTab extends StatelessWidget {
  final Map cat;
  final bool active;
  final int? count; // null = not fetched yet (this category hasn't been opened this session)
  final VoidCallback onTap;
  const _CTab({super.key, required this.cat, required this.active, required this.count, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final accent = T.ac(cat['id']);
    final none = count == 0;

    // Every tab wears its OWN category accent, not just the selected one.
    // Previously the five unselected tabs collapsed into identical grey, so
    // choosing a category made the alternatives disappear — the user stopped
    // registering that other categories existed. Now the rail always reads as
    // six distinct, colour-coded options, and "selected" is a difference of
    // intensity rather than the difference between colour and no colour.
    return HoverFx(
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? accent.withValues(alpha: .16)
              : (h ? accent.withValues(alpha: .10) : T.card),
          border: Border.all(
            // Even at rest an unselected tab keeps a readable tint of its own
            // accent, so the row never flattens into grey.
            color: active
                ? accent
                : accent.withValues(alpha: h ? .65 : .34),
            width: active ? 1.6 : 1.2,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [BoxShadow(color: accent.withValues(alpha: .22), blurRadius: 18, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Availability dot: accent when selected, green when this category
            // has listings, hollow when it is empty.
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? accent : (none ? Colors.transparent : T.grn),
                border: none && !active ? Border.all(color: T.bdhi, width: 1.2) : null,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text('${cat['icon']}', style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 7),
            Text(
              cat['name'],
              style: F.syne(
                size: 13.5,
                weight: FontWeight.w700,
                // Unselected labels sit at full body brightness (7.4:1), not
                // the old muted grey — they have to stay readable to stay
                // clickable.
                color: active ? accent : (h ? T.cream : T.text),
              ),
            ),
            const SizedBox(width: 10),
            // Count as a badge rather than loose trailing digits.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: active ? accent.withValues(alpha: .22) : accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                count == null ? '–' : '$count',
                style: F.mono(size: 10, color: none && !active ? T.dim : accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Location picker — switches the city the whole marketplace is filtered to.
class _LocationChip extends StatelessWidget {
  final AppState app;

  /// On phones the city label is dropped so the nav row never overflows —
  /// the pin + chevron still read as a picker, and the tooltip names the city.
  final bool compact;
  const _LocationChip({required this.app, this.compact = false});
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Location: ${app.location} — tap to change',
      color: T.surf,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: T.bdr)),
      position: PopupMenuPosition.under,
      onSelected: app.setLocation,
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          height: 30,
          child: Text('YOUR LOCATION', style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 1.5)),
        ),
        for (final c in AppState.cities)
          PopupMenuItem(
            value: c,
            child: Row(
              children: [
                Icon(c == app.location ? Icons.location_on : Icons.location_on_outlined,
                    size: 16, color: c == app.location ? T.gold : T.mut),
                const SizedBox(width: 10),
                Text(c, style: F.syne(size: 13, weight: FontWeight.w700, color: c == app.location ? T.cream : T.text)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 11, vertical: 7),
        decoration: BoxDecoration(
          color: T.gold.withValues(alpha: .08),
          border: Border.all(color: T.gold.withValues(alpha: .35)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 14, color: T.gold),
            if (!compact) ...[
              const SizedBox(width: 6),
              Text(app.location, style: F.syne(size: 12, weight: FontWeight.w700, color: T.gold)),
            ],
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down, size: 15, color: T.gold),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.accent, required this.onTap});
  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: (active || h) ? accent : T.bdr),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: F.syne(size: 11, weight: FontWeight.w600, color: (active || h) ? accent : T.dim)),
        ),
      );
}
