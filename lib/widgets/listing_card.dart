import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../data/app_data.dart';
import 'common.dart';

/// `.lcard` — a browse-grid listing card.
class ListingCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onView;
  /// City the card is being shown for — drives the "available here" line.
  final String? availIn;
  const ListingCard({super.key, required this.item, required this.onView, this.availIn});

  @override
  Widget build(BuildContext context) {
    final accent = T.ac(item['cat'] as String?);
    final idx = profiles.indexWhere((p) => p['id'] == item['id']);
    final gradIndex = idx >= 0 ? idx : 0;
    final tags = (item['tags'] as List?) ?? const [];

    return HoverFx(
      onTap: onView,
      builder: (hovering) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, hovering ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: T.card,
          border: Border.all(color: hovering ? accent.withOpacity(.25) : T.bdr),
          borderRadius: BorderRadius.circular(13),
          boxShadow: hovering
              ? const [BoxShadow(color: Color(0x99000000), blurRadius: 48, offset: Offset(0, 20))]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Image ──
            SizedBox(
              height: 248,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(gradient: T.gr(gradIndex)),
                    alignment: Alignment.center,
                    child: AnimatedScale(
                      scale: hovering ? 1.06 : 1,
                      duration: const Duration(milliseconds: 350),
                      child: Text(item['emoji'] ?? '', style: const TextStyle(fontSize: 80)),
                    ),
                  ),
                  // bottom gradient scrim
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: .68,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xF2000000)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // top accent reveal bar on hover
                  if (hovering)
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(height: 2, color: accent),
                    ),
                  // badge top-left
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _Pill(
                      text: (item['badge'] ?? '').toString().toUpperCase(),
                      color: accent,
                    ),
                  ),
                  // verified top-right
                  if (item['verified'] == true)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4)),
                        child: Text('✓ VERIFIED',
                            style: F.syne(size: 9, weight: FontWeight.w700, color: T.bg, letterSpacing: .5)),
                      ),
                    ),
                  if (item['isNew'] == true)
                    Positioned(
                      top: 38,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: T.grn, borderRadius: BorderRadius.circular(3)),
                        child: Text('NEW',
                            style: F.syne(size: 8, weight: FontWeight.w700, color: T.bg)),
                      ),
                    ),
                  // name + loc
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item['name'] ?? '',
                            style: F.fraunces(size: 19, weight: FontWeight.w700, color: Colors.white, height: 1.15)),
                        const SizedBox(height: 2),
                        Text('📍 ${item['loc'] ?? ''}',
                            style: F.syne(size: 11, weight: FontWeight.w600, color: accent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Body ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: T.bdr))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (availIn != null) ...[
                    Builder(builder: (_) {
                      final loc = (item['loc'] ?? '').toString().toLowerCase();
                      final panIndia = loc.contains('pan india') || loc.contains('all india');
                      return Row(children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: T.grn, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(panIndia ? 'Serves all India' : 'Available in $availIn',
                            style: F.syne(size: 10.5, weight: FontWeight.w600, color: T.grn)),
                      ]);
                    }),
                    const SizedBox(height: 9),
                  ],
                  Text(item['tagline'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: F.syne(size: 12, weight: FontWeight.w400, color: T.dim)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('★' * ((item['rating'] as num?)?.floor() ?? 0),
                              style: TextStyle(fontSize: 11, color: accent, letterSpacing: 1)),
                          const SizedBox(width: 5),
                          Text('${item['rating']}',
                              style: F.fraunces(size: 14, weight: FontWeight.w700, color: accent)),
                          const SizedBox(width: 4),
                          Text('(${item['reviewCount']})', style: F.syne(size: 10, weight: FontWeight.w400, color: T.dim)),
                        ],
                      ),
                      _CardCta(accent: accent, onTap: onView),
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        for (final t in tags)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: T.surf, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(3)),
                            child: Text('$t', style: F.syne(size: 10, weight: FontWeight.w400, color: T.dim)),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xE009090B),
        border: Border.all(color: Colors.white.withOpacity(.1)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: F.syne(size: 9, weight: FontWeight.w700, color: color, letterSpacing: 1.5)),
    );
  }
}

class _CardCta extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;
  const _CardCta({required this.accent, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return HoverFx(
      onTap: onTap,
      builder: (h) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: h ? accent.withOpacity(.07) : Colors.transparent,
          border: Border.all(color: Colors.white.withOpacity(.08)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('View Profile →', style: F.syne(size: 12, weight: FontWeight.w700, color: accent)),
      ),
    );
  }
}
