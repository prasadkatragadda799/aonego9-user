import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../data/app_data.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/ticker.dart';
import '../widgets/listing_card.dart';

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
          SliverPersistentHeader(pinned: true, delegate: _NavDelegate(app, accent, app.location)),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _hero(context, accent, catInfo, hero),
                    _catRail(app, accent),
                    _listBar(context, app, accent, catInfo, items.length),
                    _grid(context, app, accent, items, w),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
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

  Widget _catRail(AppState app, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            for (final c in cats) ...[
              _CTab(
                cat: c,
                active: app.activeCat == c['id'],
                count: app.availableInCat(app.location, c['id'] as String),
                onTap: () => app.switchCat(c['id'] as String),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _listBar(BuildContext context, AppState app, Color accent, Map cat, int count) {
    final fs = filters[app.activeCat] ?? ['All'];
    return Padding(
      padding: EdgeInsets.fromLTRB(isNarrow(context) ? 16 : 20, 16, isNarrow(context) ? 16 : 20, 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 10,
        spacing: 10,
        children: [
          Text('$count available · ${cat['name']} · 📍 ${app.location}', style: F.mono(size: 11, color: T.dim)),
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
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📍', style: const TextStyle(fontSize: 30)),
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
  _NavDelegate(this.app, this.accent, this.location);

  @override
  double get minExtent => 58;
  @override
  double get maxExtent => 58;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final narrow = isNarrow(context);
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
                // Logo
                GestureDetector(
                  onTap: () => app.switchCat('modelF'),
                  child: Text.rich(
                    TextSpan(
                      style: F.fraunces(size: 20, weight: FontWeight.w700, color: T.cream),
                      children: [
                        const TextSpan(text: 'AOne'),
                        TextSpan(text: 'Go9', style: F.fraunces(size: 20, weight: FontWeight.w700, color: T.gold)),
                        TextSpan(text: '.com', style: F.syne(size: 10, weight: FontWeight.w400, color: T.dim)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Location picker — the whole marketplace filters to this city.
                _LocationChip(app: app),
                const SizedBox(width: 8),
                // Links
                if (!narrow)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final c in cats)
                            _NavLink(cat: c, active: app.activeCat == c['id'], onTap: () => app.switchCat(c['id'] as String)),
                        ],
                      ),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 8),
                // Right
                if (!narrow) ...[
                  _GhostBtn(label: 'Vendor Portal', onTap: () => app.setView('vendor-auth')),
                  const SizedBox(width: 8),
                ],
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
      old.app.activeCat != app.activeCat || old.accent != accent || old.location != location;
}

class _NavLink extends StatelessWidget {
  final Map cat;
  final bool active;
  final VoidCallback onTap;
  const _NavLink({required this.cat, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text('${cat['icon']} ${cat['name']}',
              style: F.syne(size: 12, weight: FontWeight.w600, color: active ? T.ac(cat['id']) : (h ? T.text : T.mut))),
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
            color: T.gold.withOpacity(.06),
            border: Border.all(color: T.gold.withOpacity(.3)),
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
  final int count;
  final VoidCallback onTap;
  const _CTab({required this.cat, required this.active, required this.count, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final accent = T.ac(cat['id']);
    final none = count == 0;
    return HoverFx(
      onTap: onTap,
      builder: (h) => Opacity(
        opacity: none ? .5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: T.surf,
            border: Border.all(color: active ? accent : (h ? T.bdhi : T.bdr)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: active ? accent : (none ? T.bdr : T.grn), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('${cat['icon']} ${cat['name']}',
                  style: F.syne(size: 12, weight: FontWeight.w700, color: active ? accent : T.mut)),
              const SizedBox(width: 8),
              Text('$count', style: F.mono(size: 10, color: none ? T.dim : accent)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Location picker — switches the city the whole marketplace is filtered to.
class _LocationChip extends StatelessWidget {
  final AppState app;
  const _LocationChip({required this.app});
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Change location',
      color: T.surf,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: T.bdr)),
      position: PopupMenuPosition.under,
      onSelected: app.setLocation,
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          height: 30,
          child: Text('YOUR LOCATION', style: F.syne(size: 9, weight: FontWeight.w700, color: T.dim, letterSpacing: 1.5)),
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
                const SizedBox(width: 18),
                const Spacer(),
                Text('${app.availableIn(c)}', style: F.mono(size: 11, color: c == app.location ? T.gold : T.dim)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: T.gold.withOpacity(.06),
          border: Border.all(color: T.gold.withOpacity(.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 14, color: T.gold),
            const SizedBox(width: 6),
            Text(app.location, style: F.syne(size: 12, weight: FontWeight.w700, color: T.gold)),
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
