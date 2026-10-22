import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
// Prefixed: this file also drives its own drifting rail animation.
import 'package:flutter/scheduler.dart' as sched;
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../data/taxonomy.dart';
import '../state/app_state.dart';
import '../widgets/brand.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/home_sections.dart';
import '../widgets/market_search.dart';
import '../widgets/updates_bar.dart';
import '../widgets/listing_card.dart';
import '../widgets/spotlight_reel.dart';
import '../widgets/footer.dart';

/// Search moves between two homes rather than appearing in both: the nav has
/// room for it above this width, and below it the field gets its own pinned
/// row. Duplicating it — which an earlier pass did — meant two live search
/// fields on a desktop, each able to disagree with the other.
bool searchFitsInNav(BuildContext c) => screenW(c) > 900;

/// Browse — laid out as a directory home page.
///
///   updates bar → nav (+ pinned search on smaller screens)
///   → hero: what this is, where you are, why trust it, + the ad carousel
///   → category icon grid: every category one tap away
///   → digest strip
///   → pinned division/category rail → results header + filters → listings
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _scroll = ScrollController();
  final _resultsKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openDivision(String id) => context.read<AppState>().openResults(division: id);

  void _scrollToResults() => _scrollTo(_resultsKey, includeRail: true);

  /// Scroll [key]'s box to the top of the viewport, below whatever is pinned
  /// there at the time it arrives.
  void _scrollTo(GlobalKey key, {bool includeRail = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ro = key.currentContext?.findRenderObject();
      if (ro == null || !_scroll.hasClients) return;
      final vp = RenderAbstractViewport.maybeOf(ro);
      if (vp == null) return;
      final narrow = isNarrow(context);
      final pinned = (narrow ? 0.0 : _NavDelegate.height) +
          (searchFitsInNav(context) ? 0.0 : _SearchDelegate.heightFor(narrow)) +
          (includeRail ? _RailDelegate.heightFor(narrow) : 0.0);
      final target = vp.getOffsetToReveal(ro, 0).offset - pinned - (includeRail ? 0 : 8);
      _scroll.animateTo(
        target.clamp(0.0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final accent = T.ac(app.activeCat);
    final cat = catOf(app.activeCat) ?? catalogue.first;
    final items = app.catItems;
    final w = screenW(context);
    final narrow = isNarrow(context);

    // Artists / Vendors dock tabs and home shortcuts ask for the results
    // through [AppState.openResults]; each request is consumed once.
    if (app.takeResultsRequest()) _scrollToResults();

    final page = CustomScrollView(
      controller: _scroll,
      slivers: [
        // The phone header carries a bell for the same feed, so the ticker
        // band is a wide-screen extra.
        if (!narrow) SliverToBoxAdapter(child: UpdatesBar(accent: accent)),
        // On a phone the brand bar scrolls away and only search stays
        // pinned — vertical space is the scarcest thing on that screen, and
        // the dock at the bottom carries the menu and account instead.
        SliverPersistentHeader(pinned: !narrow, delegate: _NavDelegate(app, accent, app.location, w)),
        // Below the nav's threshold the field gets its own pinned row rather
        // than being dropped — search is the primary way into a
        // sixteen-category marketplace.
        if (!searchFitsInNav(context)) SliverPersistentHeader(pinned: true, delegate: _SearchDelegate(accent, w)),
        // Home, top to bottom as the client's sketch stacks it — pictures
        // and tiles rather than paragraphs.
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PromoStrip(app: app),
                  // The big advertisement: video / poster creatives, events
                  // and workshops, each tapping through to its page or site.
                  SpotlightReel(onOpenDivision: _openDivision),
                  ListingProfiles(app: app),
                  QuickTiles(app: app),
                  UpdatesFolders(app: app),
                  ServiceProviders(app: app),
                  ReelsCarousel(app: app),
                  IndustryGrid(app: app),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        // The rail stays pinned so the category can be switched from
        // anywhere in the results: two rows on desktop (division, then
        // category), one row on a phone with the division behind a pill.
        SliverPersistentHeader(pinned: true, delegate: _RailDelegate(app, accent, w, narrow)),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              key: _resultsKey,
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _listBar(context, app, accent, cat, items.length),
                  _grid(context, app, accent, items, w),
                  const SizedBox(height: 56),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SiteFooter()),
      ],
    );

    return Container(
      color: T.bg,
      child: narrow
          ? Column(
              children: [
                Expanded(child: page),
                AppDock(
                  onHome: () {
                    if (_scroll.hasClients) {
                      _scroll.animateTo(0, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
                    }
                  },
                ),
              ],
            )
          : page,
    );
  }

  /// Results header — "Photographers in Mumbai", the count, the division,
  /// any active search term, then the category's filter chips.
  Widget _listBar(BuildContext context, AppState app, Color accent, Cat cat, int count) {
    final fs = app.filtersFor(app.activeCat);
    final narrow = isNarrow(context);
    final division = divisionById[cat.division];
    final place = app.location == 'All India' ? 'All India' : app.location;
    return Padding(
      padding: EdgeInsets.fromLTRB(narrow ? 16 : 20, 20, narrow ? 16 : 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${cat.icon}  ${cat.name} in $place',
              style: F.fraunces(size: narrow ? 19 : 23, weight: FontWeight.w700, color: T.cream, height: 1.25)),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text('$count ${count == 1 ? 'listing' : 'listings'}',
                  style: F.syne(size: 13, weight: FontWeight.w700, color: T.text)),
              if (division != null)
                Text('·  ${division.name}', style: F.syne(size: 13, weight: FontWeight.w500, color: T.mut)),
              if (app.query.isNotEmpty)
                HoverFx(
                  onTap: app.clearQuery,
                  builder: (h) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: T.gold.withValues(alpha: .08),
                      border: Border.all(color: T.gold.withValues(alpha: h ? .6 : .3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('"${app.query}"', style: F.syne(size: 12, weight: FontWeight.w600, color: T.gold)),
                      const SizedBox(width: 5),
                      Icon(Icons.close_rounded, size: 13, color: T.gold),
                    ]),
                  ),
                ),
            ],
          ),
          if (cat.sub.isNotEmpty) ...[
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Text(cat.sub, style: F.syne(size: 13, weight: FontWeight.w400, color: T.dim, height: 1.5)),
            ),
          ],
          if (fs.isNotEmpty) ...[
            const SizedBox(height: 14),
            // One scrolling row on a phone (a wrapped block of chips pushes the
            // results off the first screen); wrapped on wider screens.
            narrow
                ? SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: fs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) => _FilterChip(
                          label: fs[i], active: app.filter == fs[i], accent: accent, onTap: () => app.setFilter(fs[i])),
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final f in fs)
                        _FilterChip(label: f, active: app.filter == f, accent: accent, onTap: () => app.setFilter(f)),
                    ],
                  ),
          ],
        ],
      ),
    );
  }

  Widget _grid(BuildContext context, AppState app, Color accent, List<Map<String, dynamic>> items, double w) {
    final pad = isNarrow(context) ? 16.0 : 20.0;
    if (items.isEmpty && app.listingsLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: T.gold)),
      );
    }
    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: pad),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
          decoration: BoxDecoration(
            color: T.card,
            border: Border.all(color: T.bdr),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📍', style: TextStyle(fontSize: 30)),
              const SizedBox(height: 10),
              Text(
                app.filteredToNothing ? 'Nothing matches that here' : 'Nothing in this category in ${app.location} yet',
                textAlign: TextAlign.center,
                style: F.syne(size: 15, weight: FontWeight.w600, color: T.text),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Offer to undo the filter that actually caused the blank —
                  // telling someone to "see all India" when their search term
                  // is what emptied the grid sends them the wrong way.
                  if (app.query.isNotEmpty) _EmptyAction(label: 'Clear search', onTap: app.clearQuery),
                  _EmptyAction(label: 'See all India', onTap: () => app.setLocation('All India')),
                  _EmptyAction(label: 'Add yours →', onTap: () => app.openConnect('apply')),
                ],
              ),
            ],
          ),
        ),
      );
    }
    // Portfolio cards: repeat(auto-fill, minmax(260px, 1fr)) — one on a
    // small phone, two on a large phone, three on a tablet, four on desktop.
    final avail = (w.clamp(0, 1280)) - pad * 2;
    final cols = (avail / 260).floor().clamp(1, 4);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad),
      child: LayoutBuilder(builder: (context, bc) {
        final gap = cols == 1 ? 14.0 : 18.0;
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

class _EmptyAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _EmptyAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: h ? T.gold.withValues(alpha: .08) : T.card,
            border: Border.all(color: T.gold.withValues(alpha: .5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: F.syne(size: 13, weight: FontWeight.w700, color: T.gold)),
        ),
      );
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

  static const double height = 58;

  /// Taller on a phone, where the location line sits under the logo.
  static double heightFor(bool narrow) => narrow ? 64 : height;

  @override
  double get minExtent => heightFor(width <= 768);
  @override
  double get maxExtent => heightFor(width <= 768);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final narrow = isNarrow(context);
    final showVendorBtn = screenW(context) > 1080;
    final showSearch = searchFitsInNav(context);
    return Container(
      decoration: BoxDecoration(
        color: T.chrome,
        border: Border(bottom: BorderSide(color: T.bdr)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: narrow ? 14 : 20),
            child: Row(
              children: [
                const MenuBtn(),
                const SizedBox(width: 10),
                // Logo, with where you are and who you are under it on a
                // phone — the sketch's "Location · Profile name" line.
                Flexible(
                  flex: showSearch ? 0 : 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      if (narrow) ...[
                        const SizedBox(height: 3),
                        // An icon rather than a 📍 emoji: the emoji font
                        // loads late on web and showed as an empty box first.
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.location_on_rounded, size: 12, color: T.gold),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              [
                                app.location,
                                if (app.isLoggedIn) app.currentUser?['name']?.toString().split(' ').first ?? '',
                              ].where((x) => x.isNotEmpty).join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: F.syne(size: 10.5, weight: FontWeight.w600, color: T.mut, height: 1.2),
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: narrow ? 8 : 14),
                if (showSearch) Expanded(child: MarketSearch(accent: accent)),
                const SizedBox(width: 10),
                _BarIcon(
                  icon: Icons.notifications_none_rounded,
                  tooltip: 'Notifications · industry & news',
                  badge: app.updateFeed.length,
                  onTap: () => showNotifications(context, app),
                ),
                // A small phone signed out has room for one account control;
                // "Sign In" says more than the bare icon there.
                if (app.isLoggedIn || screenW(context) >= 400) ...[
                  const SizedBox(width: 6),
                  _BarIcon(
                    icon: app.isLoggedIn ? Icons.person_rounded : Icons.person_outline_rounded,
                    tooltip: app.isLoggedIn ? 'Your profile' : 'Profile',
                    onTap: () => app.setView('account'),
                  ),
                ],
                if (showVendorBtn) ...[
                  const SizedBox(width: 8),
                  GhostBtn(label: 'Vendor Portal', onTap: () => app.setView('vendor-auth')),
                ],
                if (!app.isLoggedIn || !narrow) ...[
                  const SizedBox(width: 6),
                  // Capped so a long first name shortens instead of pushing
                  // the bar past the edge of a 320px phone.
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: narrow ? 90 : 170),
                    child: GhostBtn(
                      label: app.isLoggedIn
                          ? (app.currentUser?['name']?.toString().split(' ').first ?? 'Account')
                          : 'Sign In',
                      onTap: () => app.setView('account'),
                      compact: narrow,
                    ),
                  ),
                ],
                if (screenW(context) > 620) ...[
                  const SizedBox(width: 8),
                  GoldBtn(
                    label: 'Apply',
                    color: T.gold,
                    onTap: () => app.openConnect('apply'),
                  ),
                ],
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
      old.app.query != app.query ||
      old.app.isLoggedIn != app.isLoggedIn ||
      old.app.updateFeed.length != app.updateFeed.length;
}

/// Square icon button for the nav, with an optional count badge.
class _BarIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final int badge;
  final VoidCallback onTap;
  const _BarIcon({required this.icon, required this.tooltip, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: HoverFx(
          onTap: onTap,
          builder: (h) => SizedBox(
            width: 36,
            height: 36,
            child: Stack(clipBehavior: Clip.none, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: h ? T.gold.withValues(alpha: .10) : Colors.transparent,
                  border: Border.all(color: h ? T.gold.withValues(alpha: .45) : T.bdr),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 19, color: h ? T.gold : T.text),
              ),
              if (badge > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 17),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: T.red, borderRadius: BorderRadius.circular(9)),
                    child: Text(badge > 9 ? '9+' : '$badge',
                        textAlign: TextAlign.center,
                        style: F.syne(size: 9.5, weight: FontWeight.w800, color: T.onAccent(T.red))),
                  ),
                ),
            ]),
          ),
        ),
      );
}

/// Phone-only pinned search row.
class _SearchDelegate extends SliverPersistentHeaderDelegate {
  final Color accent;
  final double width;
  _SearchDelegate(this.accent, this.width);

  static double heightFor(bool narrow) => narrow ? 58 : 56;
  double get _h => heightFor(width <= 768);

  @override
  double get minExtent => _h;
  @override
  double get maxExtent => _h;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(
        decoration: BoxDecoration(
          color: T.chrome,
          border: Border(bottom: BorderSide(color: T.bdr)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 7),
        child: MarketSearch(accent: accent),
      );

  @override
  bool shouldRebuild(covariant _SearchDelegate old) => old.accent != accent || old.width != width;
}

/// Pinned rail — divisions on top, then the categories inside the active one.
class _RailDelegate extends SliverPersistentHeaderDelegate {
  final AppState app;
  final Color accent;
  final double width;
  final bool narrow;
  _RailDelegate(this.app, this.accent, this.width, this.narrow);

  static double heightFor(bool narrow) => narrow ? 58 : 120;
  double get _height => heightFor(narrow);

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: T.chrome,
        border: Border(bottom: BorderSide(color: T.bdr)),
      ),
      alignment: Alignment.center,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: narrow
              // A phone cannot afford two sticky rows, so the division moves
              // into a leading pill that opens a menu.
              ? Row(
                  children: [
                    const SizedBox(width: 12),
                    _DivisionPill(app: app),
                    const SizedBox(width: 8),
                    Expanded(child: _CategoryRail(app: app, padStart: 0)),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 44, child: _DivisionRail(app: app)),
                    Container(height: 1, color: T.bdr),
                    SizedBox(height: 75, child: _CategoryRail(app: app)),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _RailDelegate old) =>
      old.app.activeCat != app.activeCat ||
      old.app.activeDivision != app.activeDivision ||
      old.accent != accent ||
      old.narrow != narrow ||
      old.width != width;
}

/// The eight top-level divisions.
class _DivisionRail extends StatelessWidget {
  final AppState app;
  const _DivisionRail({required this.app});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final d in divisions) ...[
            _DivTab(
              division: d,
              active: app.activeDivision == d.id,
              onTap: () => app.switchDivision(d.id),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _DivTab extends StatelessWidget {
  final Division division;
  final bool active;
  final VoidCallback onTap;
  const _DivTab({required this.division, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = T.dac(division.id);
    final count = catsByDivision[division.id]?.length ?? 0;
    return Tooltip(
      message: division.blurb,
      child: HoverFx(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: .14) : Colors.transparent,
            border: Border(bottom: BorderSide(color: active ? accent : Colors.transparent, width: 2)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(division.icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 7),
            Text(division.name,
                style: F.syne(size: 12.5, weight: FontWeight.w700, color: active ? accent : (h ? T.cream : T.mut))),
            const SizedBox(width: 6),
            Text('$count', style: F.mono(size: 9.5, color: active ? accent : T.faint)),
          ]),
        ),
      ),
    );
  }
}

/// Phone version of the division switcher.
class _DivisionPill extends StatelessWidget {
  final AppState app;
  const _DivisionPill({required this.app});

  @override
  Widget build(BuildContext context) {
    final d = divisionById[app.activeDivision] ?? divisions.first;
    final accent = T.dac(d.id);
    return PopupMenuButton<String>(
      tooltip: 'Division: ${d.name}',
      color: T.surf,
      elevation: 8,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: T.bdr),
      ),
      onSelected: app.switchDivision,
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          height: 30,
          child: Text('DIVISIONS', style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 1.5)),
        ),
        for (final x in divisions)
          PopupMenuItem(
            value: x.id,
            height: 42,
            child: Row(children: [
              Text(x.icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(x.name,
                    style: F.syne(
                        size: 13, weight: FontWeight.w700, color: x.id == app.activeDivision ? T.dac(x.id) : T.text)),
              ),
              Text('${catsByDivision[x.id]?.length ?? 0}', style: F.mono(size: 10, color: T.faint)),
            ]),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .12),
          border: Border.all(color: accent.withValues(alpha: .4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(d.icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Icon(Icons.keyboard_arrow_down, size: 15, color: T.mut),
        ]),
      ),
    );
  }
}

/// The scrolling row of category tabs for the ACTIVE division.
///
/// Stateful for two reasons, both about keeping the *other* categories present
/// in the user's mind once one is selected:
///   1. edge fades signal that the row continues past the viewport, which is
///      the only cue on a phone that more categories exist off-screen;
///   2. selecting a category scrolls that tab into view, so switching from the
///      footer or a deep link never leaves the rail parked somewhere unrelated.
class _CategoryRail extends StatefulWidget {
  final AppState app;
  final double? padStart;
  const _CategoryRail({required this.app, this.padStart});
  @override
  State<_CategoryRail> createState() => _CategoryRailState();
}

class _CategoryRailState extends State<_CategoryRail> with SingleTickerProviderStateMixin {
  final _sc = ScrollController();
  final _keys = {for (final c in catalogue) c.id: GlobalKey()};
  late String _lastCat = widget.app.activeCat;
  bool _more = false;
  bool _before = false;

  // ── Slow auto-scroll ──────────────────────────────────────────────
  // The rail drifts gently end-to-end so every category is seen without the
  // user having to discover that it scrolls. It ping-pongs rather than looping,
  // because a seamless loop would mean duplicating the tabs — and duplicate
  // category tabs are ambiguous to tap and break the per-tab keys.
  static const double _driftPxPerSecond = 7;
  static const double _edgeHoldSeconds = 0.5;

  sched.Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  double _hold = _edgeHoldSeconds; // settle before the first drift
  int _dir = 1;
  bool _paused = false;
  bool _reduceMotion = false;
  Timer? _resumeTimer;

  List<Cat> get _cats => catsByDivision[widget.app.activeDivision] ?? const [];

  @override
  void initState() {
    super.initState();
    _sc.addListener(_syncEdges);
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

    final pad = widget.padStart ?? (isNarrow(context) ? 16.0 : 20.0);
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
              padding: EdgeInsets.only(left: pad, right: pad),
              child: Row(
                children: [
                  for (final c in _cats) ...[
                    _CTab(
                      key: _keys[c.id],
                      cat: c,
                      active: widget.app.activeCat == c.id,
                      count: widget.app.knownCategoryCount(c.id),
                      onTap: () => widget.app.switchCat(c.id),
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
                  colors: [T.chrome, T.chrome.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
      );
}

class _CTab extends StatelessWidget {
  final Cat cat;
  final bool active;
  final int? count; // null = not fetched yet (this category hasn't been opened this session)
  final VoidCallback onTap;
  const _CTab({super.key, required this.cat, required this.active, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = T.ac(cat.id);
    final none = count == 0;
    final narrow = isNarrow(context);

    // Every tab wears its OWN category accent, not just the selected one, so
    // the row never flattens into grey and the alternatives stay visible.
    return HoverFx(
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: narrow ? 12 : 16, vertical: narrow ? 8 : 11),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: .16) : (h ? accent.withValues(alpha: .10) : T.card),
          border: Border.all(
            color: active ? accent : accent.withValues(alpha: h ? .65 : .34),
            width: active ? 1.6 : 1.2,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: active && !narrow
              ? [BoxShadow(color: accent.withValues(alpha: .14), blurRadius: 10, offset: const Offset(0, 3))]
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
            const SizedBox(width: 9),
            Text(cat.icon, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 7),
            Text(
              cat.name,
              style: F.syne(
                size: narrow ? 12.5 : 13.5,
                weight: FontWeight.w700,
                color: active ? accent : (h ? T.cream : T.text),
              ),
            ),
            const SizedBox(width: 9),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.accent, required this.onTap});
  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? T.cream : (h ? T.surf : T.card),
            border: Border.all(color: active ? T.cream : (h ? T.gold.withValues(alpha: .6) : T.bdhi)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label,
              style: F.syne(size: 12.5, weight: FontWeight.w600, color: active ? T.onAccent(T.cream) : T.text)),
        ),
      );
}
