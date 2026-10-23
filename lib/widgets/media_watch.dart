import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'ad_slot.dart' show AdStill;
import 'common.dart';
import 'reels_viewer.dart';

/// News & Media → Watch: the "streaming / OTT" shelf the sketch adds to the
/// media tab. A featured video up top, then rails — artists' reels, brand
/// films and ads, event videos — each playing in the full-screen reels
/// player from the card that was tapped.
class MediaWatch extends StatelessWidget {
  const MediaWatch({super.key});

  static const _rails = [
    ('artist', 'Artist reels', 'Photos and videos from AOneGo9 profiles'),
    ('ad', 'Brand films & ads', 'Campaigns from brands on AOneGo9'),
    ('event', 'Event videos', 'Shows, walks and open houses'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final all = buildReels(app);
    if (all.isEmpty) return const _EmptyWatch();

    final hero = all.firstWhere((r) => r.isVideo, orElse: () => all.first);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Hero(reel: hero, onPlay: () => showReelsViewer(context, items: all, start: all.indexOf(hero))),
      for (final rail in _rails)
        Builder(builder: (context) {
          final items = all.where((r) => r.kind == rail.$1).toList();
          if (items.isEmpty) return const SizedBox.shrink();
          return _Rail(title: rail.$2, sub: rail.$3, items: items);
        }),
    ]);
  }
}

class _Hero extends StatelessWidget {
  final ReelItem reel;
  final VoidCallback onPlay;
  const _Hero({required this.reel, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    return HoverFx(
      onTap: onPlay,
      builder: (h) => AspectRatio(
        aspectRatio: narrow ? 4 / 3 : 21 / 9,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Stack(fit: StackFit.expand, children: [
            AnimatedScale(
              scale: h ? 1.03 : 1,
              duration: const Duration(milliseconds: 400),
              child: AdStill(url: reel.imageUrl, bg: reel.bg, emoji: reel.emoji),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.transparent, Color(0xE6140A0B)],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(narrow ? 18 : 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(switch (reel.kind) { 'ad' => 'BRAND FILM', 'event' => 'EVENT', _ => 'NOW STREAMING' },
                    style: F.syne(size: 10.5, weight: FontWeight.w800, color: T.marigold, letterSpacing: 2)),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Text(reel.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: F.fraunces(size: narrow ? 22 : 30, weight: FontWeight.w700, color: T.posterInk, height: 1.15)),
                ),
                if (reel.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(reel.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: F.syne(size: 13, weight: FontWeight.w500, color: T.posterInkMuted)),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 9, 18, 9),
                  decoration: BoxDecoration(color: h ? const Color(0xFFFFB84A) : T.marigold, borderRadius: BorderRadius.circular(30)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.play_arrow_rounded, size: 20, color: Color(0xFF2A1404)),
                    const SizedBox(width: 4),
                    Text('Play', style: F.syne(size: 13.5, weight: FontWeight.w800, color: const Color(0xFF2A1404))),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  final String title;
  final String sub;
  final List<ReelItem> items;
  const _Rail({required this.title, required this.sub, required this.items});

  @override
  Widget build(BuildContext context) {
    final w = isNarrow(context) ? 200.0 : 248.0;
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: F.fraunces(size: 19, weight: FontWeight.w700, color: T.cream)),
        const SizedBox(height: 2),
        Text(sub, style: F.syne(size: 12.5, weight: FontWeight.w500, color: T.mut)),
        const SizedBox(height: 12),
        SizedBox(
          height: w * 9 / 16 + 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (c, i) => SizedBox(
              width: w,
              child: _Thumb(reel: items[i], onTap: () => showReelsViewer(c, items: items, start: i)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Thumb extends StatelessWidget {
  final ReelItem reel;
  final VoidCallback onTap;
  const _Thumb({required this.reel, required this.onTap});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: h ? T.gold : Colors.transparent, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(fit: StackFit.expand, children: [
                AdStill(url: reel.imageUrl, bg: reel.bg, emoji: reel.emoji),
                Center(
                  child: AnimatedOpacity(
                    opacity: h || reel.isVideo ? 1 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: .55), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                ),
                if (reel.kind == 'ad')
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: .55), borderRadius: BorderRadius.circular(3)),
                      child: Text('AD', style: F.syne(size: 9, weight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
                    ),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text(reel.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: F.syne(size: 13, weight: FontWeight.w700, color: h ? T.gold : T.cream)),
          const SizedBox(height: 2),
          Text(reel.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: F.syne(size: 11.5, weight: FontWeight.w500, color: T.mut)),
        ]),
      );
}

class _EmptyWatch extends StatelessWidget {
  const _EmptyWatch();

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(gradient: T.grPoster(1), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        const Text('📺', style: TextStyle(fontSize: 46)),
        const SizedBox(height: 12),
        Text('AOneGo9 streaming starts here',
            textAlign: TextAlign.center, style: F.fraunces(size: 21, weight: FontWeight.w700, color: T.posterInk)),
        const SizedBox(height: 8),
        Text('Artists\' reels, brand films and event videos appear on this shelf as they are published.',
            textAlign: TextAlign.center, style: F.syne(size: 13, weight: FontWeight.w400, color: T.posterInkMuted, height: 1.5)),
        const SizedBox(height: 18),
        Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
          HoverFx(
            onTap: () => app.openConnect('apply'),
            builder: (h) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: h ? const Color(0xFFFFB84A) : T.marigold, borderRadius: BorderRadius.circular(30)),
              child: Text('Add your reels →', style: F.syne(size: 13, weight: FontWeight.w800, color: const Color(0xFF2A1404))),
            ),
          ),
          HoverFx(
            onTap: () => app.setView('advertise'),
            builder: (h) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: h ? .16 : .08),
                border: Border.all(color: Colors.white.withValues(alpha: .3)),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text('Run a brand film', style: F.syne(size: 13, weight: FontWeight.w800, color: T.posterInk)),
            ),
          ),
        ]),
      ]),
    );
  }
}
