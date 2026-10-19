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
import '../widgets/digest_strip.dart';
import '../widgets/division_fx.dart';
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
  final _floorKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Tapping a tile in the category grid switches category and then brings
  /// the results into view, under the pinned headers rather than behind them.
  void _openCat(AppState app, String id) {
    app.switchCat(id);
    _scrollToResults();
  }

  void _openDivision(AppState app, String id) {
    app.switchDivision(id);
    _scrollToResults();
  }

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

    final page = CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverToBoxAdapter(child: UpdatesBar(accent: accent)),
          // On a phone the brand bar scrolls away and only search stays
          // pinned — vertical space is the scarcest thing on that screen, and
          // the dock at the bottom carries the menu and account instead.
          SliverPersistentHeader(pinned: !narrow, delegate: _NavDelegate(app, accent, app.location, w)),
          // Below the nav's threshold the field gets its own pinned row rather
          // than being dropped — search is the primary way into a
          // sixteen-category marketplace.
          if (!searchFitsInNav(context))
            SliverPersistentHeader(pinned: true, delegate: _SearchDelegate(accent, w)),
          SliverToBoxAdapter(child: _hero(context, app)),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Auto-advancing spotlight: ads (video / photo), events,
                    // workshops and digest stories, each tapping through to
                    // its booking or detail; house posts fill it otherwise.
                    SpotlightReel(onOpenDivision: (id) => _openDivision(app, id)),
                    _DivisionExplorer(
                      key: _floorKey,
                      app: app,
                      onPickCat: (id) => _openCat(app, id),
                      onPickDivision: (id) => _openDivision(app, id),
                    ),
                    const DigestStrip(),
                    const SizedBox(height: 8),
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
                  onFloor: () => _scrollTo(_floorKey),
                ),
              ],
            )
          : page,
    );
  }

  /// White hero band: headline, place, trust points.
  Widget _hero(BuildContext context, AppState app) {
    final w = screenW(context);
    final narrow = isNarrow(context);
    final pad = narrow ? 16.0 : 20.0;
    final hSize = w < 380 ? 22.0 : (narrow ? 25.0 : (w < 1024 ? 30.0 : 34.0));
    final place = app.location == 'All India' ? 'across India' : 'in ${app.location}';

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeUp(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 22, height: 2, color: T.gold),
            const SizedBox(width: 10),
            Flexible(
              child: Text('MODELING AGENCY & PRODUCTION HOUSE',
                  style: F.syne(
                      size: w < 380 ? 9.5 : 10.5, weight: FontWeight.w800, color: T.gold, letterSpacing: w < 380 ? 1.1 : 2)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        FadeUp(
          delay: const Duration(milliseconds: 60),
          child: Text.rich(
            TextSpan(
              style: F.fraunces(size: hSize, weight: FontWeight.w700, color: T.cream, height: 1.2, letterSpacing: -.4),
              children: [
                const TextSpan(text: 'Cast talent, book crews & find venues '),
                TextSpan(text: place, style: TextStyle(color: T.gold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        FadeUp(
          delay: const Duration(milliseconds: 120),
          child: Text(
            narrow
                ? 'Read the book before you reach out.'
                : 'Read the book before you reach out — ${catalogue.length} categories across ${divisions.length} '
                    'divisions, from models and photographers to studios, makeup, fashion and venues.',
            style: F.syne(size: narrow ? 14 : 14.5, weight: FontWeight.w400, color: T.mut, height: 1.6),
          ),
        ),
        SizedBox(height: narrow ? 16 : 16),
        if (narrow)
          // Phone: three numbers in a strip read faster than a paragraph.
          FadeUp(
            delay: const Duration(milliseconds: 180),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: T.surf,
                borderRadius: BorderRadius.circular(6),
              ),
              child: IntrinsicHeight(
                child: Row(children: [
                  _HeroStat(value: '${divisions.length}', label: 'Divisions'),
                  VerticalDivider(color: T.bdr, width: 1, thickness: 1),
                  _HeroStat(value: '${catalogue.length}', label: 'Categories'),
                  VerticalDivider(color: T.bdr, width: 1, thickness: 1),
                  const _HeroStat(value: '✓', label: 'Desk-verified'),
                ]),
              ),
            ),
          )
        else
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TrustChip(icon: Icons.verified_outlined, label: 'Desk-verified profiles'),
              _TrustChip(icon: Icons.photo_library_outlined, label: 'Full portfolios first'),
              _TrustChip(icon: Icons.send_outlined, label: 'Brief them directly'),
            ],
          ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: T.card,
        border: Border(bottom: BorderSide(color: T.bdr)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, narrow ? 20 : 32, pad, narrow ? 16 : 28),
            // Ad creatives now play in the spotlight reel below, so the hero
            // is copy only — one place for promoted content, not two. Full
            // width so the copy stays left-aligned instead of being centred.
            child: SizedBox(width: double.infinity, child: copy),
          ),
        ),
      ),
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
                app.filteredToNothing
                    ? 'Nothing matches that here'
                    : 'Nothing in this category in ${app.location} yet',
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

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(value, style: F.fraunces(size: 20, weight: FontWeight.w700, color: T.gold, height: 1.2)),
          const SizedBox(height: 2),
          Text(label, style: F.syne(size: 11, weight: FontWeight.w600, color: T.mut)),
        ]),
      );
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(right: 14),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: T.gold),
          const SizedBox(width: 6),
          Text(label, style: F.syne(size: 12.5, weight: FontWeight.w600, color: T.text)),
        ]),
      );
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

/// "Browse the floor" — every category, grouped under its division.
///
/// Each division is a block with its own accent and its own ambient motion
/// ([DivisionFx]) — a spotlight over Talent, film rolling under Production,
/// a playhead over Post & Design, and so on — so the eight rooms are told
/// apart before a word is read.
///
///   phone   two-up grid of compact blocks; a tap opens that division's
///           categories in a bottom sheet
///   wider   panels with the motion in a header band and the categories as
///           chips underneath
class _DivisionExplorer extends StatelessWidget {
  final AppState app;
  final ValueChanged<String> onPickCat;
  final ValueChanged<String> onPickDivision;
  const _DivisionExplorer({super.key, required this.app, required this.onPickCat, required this.onPickDivision});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    final pad = narrow ? 16.0 : 20.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, narrow ? 22 : 30, pad, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Browse the floor',
                        style: F.fraunces(size: narrow ? 20 : 22, weight: FontWeight.w700, color: T.cream)),
                    const SizedBox(height: 2),
                    Text(
                        narrow
                            ? 'Pick a division to see its categories'
                            : '${divisions.length} divisions · ${catalogue.length} categories',
                        style: F.syne(size: 12.5, weight: FontWeight.w500, color: T.dim)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, bc) {
            if (bc.maxWidth < 640) {
              const gap = 10.0;
              final cardW = (bc.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var i = 0; i < divisions.length; i++)
                    SizedBox(
                      width: cardW,
                      child: FadeUp(
                        delay: Duration(milliseconds: 40 * i),
                        offset: 12,
                        child: _DivisionBlock(
                          division: divisions[i],
                          active: app.activeDivision == divisions[i].id,
                          onTap: () => _openSheet(context, divisions[i]),
                        ),
                      ),
                    ),
                ],
              );
            }
            final cols = bc.maxWidth >= 1080 ? 4 : (bc.maxWidth >= 760 ? 3 : 2);
            const gap = 14.0;
            final cardW = (bc.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < divisions.length; i++)
                  SizedBox(
                    width: cardW,
                    child: FadeUp(
                      delay: Duration(milliseconds: 50 * i),
                      offset: 14,
                      child: _DivisionPanel(
                        division: divisions[i],
                        app: app,
                        onPickCat: onPickCat,
                        onPickDivision: onPickDivision,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _openSheet(BuildContext context, Division d) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: T.card,
      barrierColor: T.scrim,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      clipBehavior: Clip.antiAlias,
      builder: (sheetCtx) => _DivisionSheet(
        division: d,
        app: app,
        onPickCat: (id) {
          Navigator.of(sheetCtx).pop();
          onPickCat(id);
        },
        onPickDivision: (id) {
          Navigator.of(sheetCtx).pop();
          onPickDivision(id);
        },
      ),
    );
  }
}

/// Phone block: motion behind, icon, name, how many categories inside.
class _DivisionBlock extends StatefulWidget {
  final Division division;
  final bool active;
  final VoidCallback onTap;
  const _DivisionBlock({required this.division, required this.active, required this.onTap});

  @override
  State<_DivisionBlock> createState() => _DivisionBlockState();
}

class _DivisionBlockState extends State<_DivisionBlock> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.division;
    final accent = T.dac(d.id);
    final count = catsByDivision[d.id]?.length ?? 0;
    return Semantics(
      button: true,
      label: '${d.name}, $count categories',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? .96 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            height: 128,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent.withValues(alpha: .10), T.card],
              ),
              border: Border.all(color: widget.active ? accent : accent.withValues(alpha: .22), width: widget.active ? 1.5 : 1),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DivisionFx(
                      divisionId: d.id, accent: accent, intensity: _down ? 1.5 : 1, fadeToward: Alignment.bottomCenter),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: T.card,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: accent.withValues(alpha: .18), blurRadius: 10, offset: const Offset(0, 3))],
                          ),
                          child: Text(d.icon, style: const TextStyle(fontSize: 17)),
                        ),
                        const Spacer(),
                        if (widget.active)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3)),
                            child: Text('OPEN',
                                style: F.syne(size: 8.5, weight: FontWeight.w800, color: T.onAccent(accent), letterSpacing: 1)),
                          ),
                      ]),
                      const Spacer(),
                      Text(d.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: F.fraunces(size: 14.5, weight: FontWeight.w600, color: T.cream, height: 1.2)),
                      const SizedBox(height: 2),
                      Row(children: [
                        // Flexible: on a 320px phone with large system text
                        // the count and arrow did not fit side by side.
                        Expanded(
                          child: Text('$count ${count == 1 ? 'category' : 'categories'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: F.syne(size: 11.5, weight: FontWeight.w600, color: accent)),
                        ),
                        Icon(Icons.arrow_forward_rounded, size: 15, color: accent),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing one division's categories as large tap rows.
class _DivisionSheet extends StatelessWidget {
  final Division division;
  final AppState app;
  final ValueChanged<String> onPickCat;
  final ValueChanged<String> onPickDivision;
  const _DivisionSheet({required this.division, required this.app, required this.onPickCat, required this.onPickDivision});

  @override
  Widget build(BuildContext context) {
    final accent = T.dac(division.id);
    final cats = catsByDivision[division.id] ?? const <Cat>[];
    final maxH = MediaQuery.of(context).size.height * .82;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 124,
              child: Stack(children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accent.withValues(alpha: .16), T.card],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DivisionFx(
                      divisionId: division.id, accent: accent, intensity: 1.3, fadeToward: Alignment.bottomLeft),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: T.bdhi, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 12, 14),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: T.card, shape: BoxShape.circle, boxShadow: [
                        BoxShadow(color: accent.withValues(alpha: .22), blurRadius: 14, offset: const Offset(0, 4)),
                      ]),
                      child: Text(division.icon, style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(division.name, style: F.fraunces(size: 20, weight: FontWeight.w700, color: T.cream)),
                          Text(division.blurb,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: F.syne(size: 12.5, weight: FontWeight.w400, color: T.mut, height: 1.4)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: T.mut),
                    ),
                  ]),
                ),
              ]),
            ),
            Container(height: 1, color: T.bdr),
            for (final c in cats)
              _SheetRow(
                cat: c,
                active: app.activeCat == c.id,
                count: app.knownCategoryCount(c.id),
                onTap: () => onPickCat(c.id),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: T.cream,
                    foregroundColor: T.onAccent(T.cream),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () => onPickDivision(division.id),
                  child: Text('Open ${division.name}', style: F.syne(size: 14, weight: FontWeight.w700, color: T.onAccent(T.cream))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final Cat cat;
  final bool active;
  final int? count;
  final VoidCallback onTap;
  const _SheetRow({required this.cat, required this.active, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = T.ac(cat.id);
    return Material(
      color: active ? accent.withValues(alpha: .07) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withValues(alpha: .12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: T.bdr))),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: accent.withValues(alpha: .10), borderRadius: BorderRadius.circular(8)),
              child: Text(cat.icon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cat.name, style: F.syne(size: 15, weight: FontWeight.w700, color: active ? accent : T.cream)),
                if (count != null)
                  Text('$count listed', style: F.syne(size: 12, weight: FontWeight.w500, color: T.dim)),
              ]),
            ),
            if (active)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text('Viewing', style: F.syne(size: 11.5, weight: FontWeight.w700, color: accent)),
              ),
            Icon(Icons.chevron_right_rounded, color: active ? accent : T.faint),
          ]),
        ),
      ),
    );
  }
}

/// Tablet / desktop panel: animated header band, then category chips.
class _DivisionPanel extends StatefulWidget {
  final Division division;
  final AppState app;
  final ValueChanged<String> onPickCat;
  final ValueChanged<String> onPickDivision;
  const _DivisionPanel({required this.division, required this.app, required this.onPickCat, required this.onPickDivision});

  @override
  State<_DivisionPanel> createState() => _DivisionPanelState();
}

class _DivisionPanelState extends State<_DivisionPanel> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final division = widget.division;
    final app = widget.app;
    final accent = T.dac(division.id);
    final cats = catsByDivision[division.id] ?? const <Cat>[];
    final activeHere = app.activeDivision == division.id;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minHeight: 208),
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: T.card,
          border: Border.all(color: (activeHere || _hover) ? accent.withValues(alpha: .55) : T.bdr),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: _hover ? .16 : 0),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            HoverFx(
              onTap: () => widget.onPickDivision(division.id),
              builder: (h) => SizedBox(
                height: 104,
                child: Stack(children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accent.withValues(alpha: .12), T.card],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DivisionFx(
                        divisionId: division.id,
                        accent: accent,
                        intensity: _hover ? 1.6 : 1,
                        fadeToward: Alignment.topLeft),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: T.card, shape: BoxShape.circle, boxShadow: [
                            BoxShadow(color: accent.withValues(alpha: .2), blurRadius: 10, offset: const Offset(0, 3)),
                          ]),
                          child: Text(division.icon, style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(division.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: F.fraunces(size: 15.5, weight: FontWeight.w600, color: h ? accent : T.cream)),
                              const SizedBox(height: 2),
                              Text(division.blurb,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: F.syne(size: 11.5, weight: FontWeight.w400, color: T.mut, height: 1.35)),
                            ],
                          ),
                        ),
                        AnimatedSlide(
                          duration: const Duration(milliseconds: 180),
                          offset: Offset(h ? .25 : 0, 0),
                          child: Icon(Icons.arrow_forward_rounded, size: 16, color: h ? accent : T.faint),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in cats)
                    _CatChip(
                      cat: c,
                      active: app.activeCat == c.id,
                      count: app.knownCategoryCount(c.id),
                      onTap: () => widget.onPickCat(c.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final Cat cat;
  final bool active;
  final int? count;
  final VoidCallback onTap;
  const _CatChip({required this.cat, required this.active, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = T.ac(cat.id);
    return HoverFx(
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? accent : (h ? accent.withValues(alpha: .08) : T.surf),
          border: Border.all(color: active ? accent : (h ? accent.withValues(alpha: .4) : T.bdr)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(cat.icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(cat.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: F.syne(
                    size: 12,
                    weight: FontWeight.w600,
                    color: active ? T.onAccent(accent) : (h ? accent : T.text))),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text('$count', style: F.mono(size: 10.5, color: active ? T.onAccent(accent) : T.dim)),
          ],
        ]),
      ),
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

  static const double height = 58;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

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
                SizedBox(width: narrow ? 8 : 14),
                if (showSearch)
                  Expanded(child: MarketSearch(accent: accent))
                else
                  const Spacer(),
                const SizedBox(width: 12),
                if (showVendorBtn) ...[
                  GhostBtn(label: 'Vendor Portal', onTap: () => app.setView('vendor-auth')),
                  const SizedBox(width: 8),
                ],
                // Capped so a long first name shortens instead of pushing the
                // bar past the edge of a 320px phone. (Flexible would split the
                // free space with the Spacer and float the button inward.)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: narrow ? 120 : 170),
                  child: GhostBtn(
                    label: app.isLoggedIn
                        ? (app.currentUser?['name']?.toString().split(' ').first ?? 'Account')
                        : 'Sign In',
                    onTap: () => app.setView('account'),
                    compact: narrow,
                  ),
                ),
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
      old.app.isLoggedIn != app.isLoggedIn;
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
                style: F.syne(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: active ? accent : (h ? T.cream : T.mut))),
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
          child: Text('DIVISIONS',
              style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 1.5)),
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
                        size: 13,
                        weight: FontWeight.w700,
                        color: x.id == app.activeDivision ? T.dac(x.id) : T.text)),
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
          color: active
              ? accent.withValues(alpha: .16)
              : (h ? accent.withValues(alpha: .10) : T.card),
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
              style: F.syne(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: active ? T.onAccent(T.cream) : T.text)),
        ),
      );
}
