import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/taxonomy.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'common.dart';
import 'division_fx.dart';

/// ─────────────────────────────────────────────────────────────────
/// HUB PARTS — the picture-first page format the client signed off on
/// for Wedding Planning, shared so Artists and Vendors read the same way:
///
///   HubBanner     festive ground, location, headline, a search bar
///                 riding over its bottom edge
///   HubCircle     round category shortcut
///   HubBand       a tinted band of picture cards under a title
///   HubPromo      the wide "explore now" promo
/// ─────────────────────────────────────────────────────────────────

class HubBanner extends StatelessWidget {
  final List<Color> colors;
  final String motif;
  final Color motifAccent;
  final String emojis;
  final String title;

  /// Sits over the banner's bottom edge — a search field.
  final Widget search;
  const HubBanner({
    super.key,
    required this.colors,
    required this.motif,
    required this.motifAccent,
    required this.emojis,
    required this.title,
    required this.search,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final narrow = isNarrow(context);
    final pad = narrow ? 16.0 : 20.0;
    return SizedBox(
      height: narrow ? 280 : 300,
      child: Stack(children: [
        Positioned.fill(
          bottom: 28,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
            ),
            child: Stack(children: [
              Positioned.fill(
                child: DivisionFx(divisionId: motif, accent: motifAccent, intensity: 2.2, fadeToward: Alignment.bottomLeft),
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
                  Text(emojis, style: const TextStyle(fontSize: 30)),
                  const SizedBox(height: 6),
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: F.fraunces(size: narrow ? 21 : 24, weight: FontWeight.w700, color: T.posterInk, height: 1.15)),
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
            child: search,
          ),
        ),
      ]),
    );
  }
}

class HubCircle extends StatelessWidget {
  final String cat;
  final String label;
  final VoidCallback onTap;
  const HubCircle({super.key, required this.cat, required this.label, required this.onTap});

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

/// A grid of [HubCircle]s: six across on a wide screen, three on a phone.
class HubCircles extends StatelessWidget {
  final List<(String, String)> items;
  final ValueChanged<String> onOpen;
  const HubCircles({super.key, required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, bc) {
        final cols = bc.maxWidth >= 640 ? 6 : 3;
        return Wrap(runSpacing: 16, children: [
          for (final c in items)
            SizedBox(width: bc.maxWidth / cols, child: HubCircle(cat: c.$1, label: c.$2, onTap: () => onOpen(c.$1))),
        ]);
      });
}

class HubBand extends StatelessWidget {
  final String title;
  final Color tint;
  final List<(String, String, String)> items;
  final ValueChanged<String> onOpen;
  const HubBand({super.key, required this.title, required this.tint, required this.items, required this.onOpen});

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
                child: HubPhotoCard(
                    cat: items[i].$1, label: items[i].$2, emoji: items[i].$3, bg: i, onTap: () => onOpen(items[i].$1)),
              ),
          ]);
        }),
      ]),
    );
  }
}

class HubPhotoCard extends StatelessWidget {
  final String cat;
  final String label;
  final String emoji;
  final int bg;
  final VoidCallback onTap;
  const HubPhotoCard({super.key, required this.cat, required this.label, required this.emoji, required this.bg, required this.onTap});

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
                DivisionFx(
                    divisionId: catOf(cat)?.division ?? 'beauty',
                    accent: accent,
                    intensity: h ? 2 : 1.4,
                    fadeToward: Alignment.bottomCenter),
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

class HubPromo extends StatelessWidget {
  final String title;
  final String sub;
  final String cta;
  final String emoji;
  final Color ground;
  final Color accent;

  /// Warm light behind the emoji; defaults to the accent dimmed toward the ground.
  final Color? glow;
  final VoidCallback onTap;
  const HubPromo({
    super.key,
    required this.title,
    required this.sub,
    required this.emoji,
    required this.onTap,
    this.cta = 'Explore now',
    this.ground = const Color(0xFF7A1424),
    this.accent = const Color(0xFFF2B33D),
    this.glow,
  });

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          height: 150,
          decoration: BoxDecoration(
            color: ground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: h ? accent : Colors.transparent, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(children: [
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(title, maxLines: 2, style: F.syne(size: 16, weight: FontWeight.w800, color: T.posterInk, height: 1.2)),
                  const SizedBox(height: 4),
                  Text(sub, maxLines: 2, style: F.syne(size: 12.5, weight: FontWeight.w500, color: T.posterInkMuted)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Flexible(
                      child: Text(cta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: F.syne(size: 13, weight: FontWeight.w800, color: accent)),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_circle_right_rounded, size: 18, color: accent),
                  ]),
                ]),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.centerRight,
                    radius: 1,
                    colors: [glow ?? Color.lerp(accent, ground, .25)!, ground],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 54)),
              ),
            ),
          ]),
        ),
      );
}
