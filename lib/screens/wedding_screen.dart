import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/taxonomy.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/division_fx.dart';
import '../widgets/market_search.dart';

/// Wedding planning — one page that gathers every category a wedding books,
/// laid out picture-first: a banner with the search over it, round shortcuts,
/// then "for the bride", a promo, "for the groom" and the pre-wedding shoot.
///
/// Every card opens real AOneGo9 results for the browsing location; nothing
/// here is a separate catalogue.
class WeddingScreen extends StatelessWidget {
  const WeddingScreen({super.key});

  // Festive ground that stays the same in both themes — a wedding page in
  // the app's neutral chrome read as a settings screen.
  static const _maroon = Color(0xFF7A1424);
  static const _rose = Color(0xFFF7D9DF);
  static const _marigold = Color(0xFFF2B33D);

  static const _circles = [
    ('venue', 'Banquets & Venues'),
    ('events', 'Catering & Decor'),
    ('photo', 'Photographers'),
    ('video', 'Wedding Films'),
    ('hotel', 'Guest Stays'),
    ('studio', 'Photo Studios'),
  ];

  static const _bride = [
    ('designer', 'Bridal Wear', '👰'),
    ('jewellery', 'Wedding Jewellery', '💍'),
    ('makeupArtist', 'Bridal Makeup Artists', '💄'),
    ('makeupStudio', 'Bridal Salons & Mehendi', '🌿'),
  ];

  static const _groom = [
    ('clothShop', 'Wedding Suits & Sherwani', '🤵'),
    ('makeupStudio', 'Grooming Salons', '💈'),
    ('jewellery', 'Groom Jewellery', '⌚'),
    ('events', 'Baraat & Entertainment', '🎺'),
  ];

  static const _pre = [
    ('photo', 'Pre-wedding Shoot', '📸'),
    ('video', 'Save-the-date Films', '🎬'),
    ('modelF', 'Bridal Models', '👗'),
    ('editVideo', 'Wedding Video Editors', '✂️'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final narrow = isNarrow(context);
    final pad = narrow ? 16.0 : 20.0;
    void open(String cat) => app.openResults(cat: cat);

    return Container(
      color: T.bg,
      child: Column(children: [
        const AppTopBar(title: 'Wedding Planning'),
        Expanded(
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _banner(context, app, pad),
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, 18, pad, 0),
                      child: LayoutBuilder(builder: (context, bc) {
                        final cols = bc.maxWidth >= 640 ? 6 : 3;
                        return Wrap(runSpacing: 16, children: [
                          for (final c in _circles)
                            SizedBox(
                              width: bc.maxWidth / cols,
                              child: _Circle(cat: c.$1, label: c.$2, onTap: () => open(c.$1)),
                            ),
                        ]);
                      }),
                    ),
                    _Band(
                      title: 'Wedding planning for the bride',
                      tint: _rose,
                      items: _bride,
                      onOpen: open,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, 22, pad, 0),
                      child: _Promo(onTap: () => open('photo')),
                    ),
                    _Band(
                      title: 'Wedding planning for the groom',
                      tint: const Color(0xFFFBE7CF),
                      items: _groom,
                      onOpen: open,
                    ),
                    _Band(
                      title: 'Pre-wedding planning',
                      tint: const Color(0xFFE6E1F5),
                      items: _pre,
                      onOpen: open,
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ),
          ]),
        ),
        if (narrow) const AppDock(),
      ]),
    );
  }

  Widget _banner(BuildContext context, AppState app, double pad) => SizedBox(
        height: isNarrow(context) ? 280 : 300,
        child: Stack(children: [
          Positioned.fill(
            bottom: 28,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_maroon, Color(0xFFB2364A), _marigold],
                ),
              ),
              child: Stack(children: [
                const Positioned.fill(
                  child: DivisionFx(divisionId: 'beauty', accent: _marigold, intensity: 2.2, fadeToward: Alignment.bottomLeft),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, 20, pad, 40),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 15, color: T.posterInk),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(app.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: F.syne(size: 12.5, weight: FontWeight.w700, color: T.posterInk)),
                      ),
                    ]),
                    const Spacer(),
                    const Text('💍 🪔 🌸', style: TextStyle(fontSize: 30)),
                    const SizedBox(height: 6),
                    Text('Plan the whole wedding in one place',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: F.fraunces(size: isNarrow(context) ? 21 : 24, weight: FontWeight.w700, color: T.posterInk, height: 1.15)),
                  ]),
                ),
              ]),
            ),
          ),
          Positioned(
            left: pad,
            right: pad,
            bottom: 0,
            child: Material(
              elevation: 6,
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: MarketSearch(accent: T.gold),
            ),
          ),
        ]),
      );
}

class _Circle extends StatelessWidget {
  final String cat;
  final String label;
  final VoidCallback onTap;
  const _Circle({required this.cat, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = catOf(cat);
    final accent = T.ac(cat);
    return HoverFx(
      onTap: onTap,
      builder: (h) => Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [accent.withValues(alpha: .45), accent.withValues(alpha: .12)]),
            border: Border.all(color: h ? accent : accent.withValues(alpha: .35), width: 2),
          ),
          child: Text(c?.icon ?? '✦', style: const TextStyle(fontSize: 32)),
        ),
        const SizedBox(height: 7),
        Text(label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: F.syne(size: 12, weight: FontWeight.w600, color: h ? accent : T.text, height: 1.25)),
      ]),
    );
  }
}

class _Band extends StatelessWidget {
  final String title;
  final Color tint;
  final List<(String, String, String)> items;
  final ValueChanged<String> onOpen;
  const _Band({required this.title, required this.tint, required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final pad = isNarrow(context) ? 16.0 : 20.0;
    return Container(
      margin: const EdgeInsets.only(top: 26),
      padding: EdgeInsets.fromLTRB(pad, 20, pad, 22),
      color: T.isLight ? tint.withValues(alpha: .55) : tint.withValues(alpha: .06),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: F.fraunces(size: 20, weight: FontWeight.w700, color: T.cream)),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, bc) {
          final cols = bc.maxWidth >= 640 ? 4 : 2;
          const gap = 12.0;
          final w = (bc.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(spacing: gap, runSpacing: gap, children: [
            for (var i = 0; i < items.length; i++)
              SizedBox(
                width: w,
                child: _PhotoCard(cat: items[i].$1, label: items[i].$2, emoji: items[i].$3, bg: i, onTap: () => onOpen(items[i].$1)),
              ),
          ]);
        }),
      ]),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final String cat;
  final String label;
  final String emoji;
  final int bg;
  final VoidCallback onTap;
  const _PhotoCard({required this.cat, required this.label, required this.emoji, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = T.ac(cat);
    return Semantics(
      button: true,
      label: label,
      child: HoverFx(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, h ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: T.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: h ? accent : T.bdr),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(fit: StackFit.expand, children: [
                DecoratedBox(decoration: BoxDecoration(gradient: T.grPoster(bg + 2))),
                DivisionFx(divisionId: catOf(cat)?.division ?? 'beauty', accent: accent, intensity: h ? 2 : 1.4, fadeToward: Alignment.bottomCenter),
                Center(child: Text(emoji, style: TextStyle(fontSize: h ? 62 : 56))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 10, 12),
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: F.syne(size: 13, weight: FontWeight.w700, color: T.cream)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Promo extends StatelessWidget {
  final VoidCallback onTap;
  const _Promo({required this.onTap});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          height: 150,
          decoration: BoxDecoration(
            color: WeddingScreen._maroon,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: h ? WeddingScreen._marigold : Colors.transparent, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(children: [
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Choose the best photographers',
                      maxLines: 2,
                      style: F.syne(size: 16, weight: FontWeight.w800, color: T.posterInk, height: 1.2)),
                  const SizedBox(height: 4),
                  Text('to capture your special moments',
                      maxLines: 2,
                      style: F.syne(size: 12.5, weight: FontWeight.w500, color: T.posterInkMuted)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Flexible(
                      child: Text('Explore now',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: F.syne(size: 13, weight: FontWeight.w800, color: WeddingScreen._marigold)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_circle_right_rounded, size: 18, color: WeddingScreen._marigold),
                  ]),
                ]),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.centerRight,
                    radius: 1,
                    colors: [Color(0xFFE0A33A), Color(0xFF7A1424)],
                  ),
                ),
                alignment: Alignment.center,
                child: const Text('📸', style: TextStyle(fontSize: 54)),
              ),
            ),
          ]),
        ),
      );
}
