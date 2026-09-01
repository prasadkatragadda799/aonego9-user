import 'package:flutter/material.dart';
import '../theme/tokens.dart';
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
    final id = item['id'] as String? ?? '';
    final gradIndex = id.isEmpty ? 0 : id.hashCode.abs() % 6;
    final tags = (item['tags'] as List?) ?? const [];

    return HoverFx(
      onTap: onView,
      builder: (hovering) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, hovering ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: T.card,
          border: Border.all(color: hovering ? accent.withValues(alpha: .25) : T.bdr),
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
                  if (((item['avatarUrl'] as String?)?.trim() ?? '').isNotEmpty)
                    Image.network(
                      (item['avatarUrl'] as String).trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(gradient: T.gr(gradIndex)),
                        alignment: Alignment.center,
                        child: Text(item['emoji'] ?? '', style: const TextStyle(fontSize: 80)),
                      ),
                    )
                  else
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
                            style: F.syne(size: 10, weight: FontWeight.w700, color: T.bg, letterSpacing: .5)),
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
                            style: F.syne(size: 10, weight: FontWeight.w700, color: T.bg)),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: F.fraunces(size: 19, weight: FontWeight.w700, color: Colors.white, height: 1.15)),
                        const SizedBox(height: 2),
                        Text('📍 ${item['loc'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
              decoration: BoxDecoration(border: Border(top: BorderSide(color: T.bdr))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 18,
                    child: availIn == null
                        ? const SizedBox.shrink()
                        : Builder(builder: (_) {
                            final loc = (item['loc'] ?? '').toString().toLowerCase();
                            final panIndia = loc.contains('pan india') || loc.contains('all india');
                            return Row(children: [
                              Container(width: 6, height: 6, decoration: BoxDecoration(color: T.grn, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(panIndia ? 'Serves all India' : 'Available in $availIn',
                                  style: F.syne(size: 10.5, weight: FontWeight.w600, color: T.grn)),
                            ]);
                          }),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    height: 34,
                    child: Text(
                      (item['tagline'] as String?)?.trim().isNotEmpty == true ? item['tagline'] : ' ',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: F.syne(size: 12, weight: FontWeight.w400, color: T.dim, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 15, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        ((item['rating'] as num?)?.toDouble() ?? 0).toStringAsFixed(1),
                        style: F.fraunces(size: 14, weight: FontWeight.w700, color: accent),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('(${item['reviewCount'] ?? 0})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: F.syne(size: 10, weight: FontWeight.w400, color: T.dim)),
                      ),
                      _CardCta(accent: accent, onTap: onView, compact: screenW(context) < 400),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 26,
                    child: tags.isEmpty
                        ? const SizedBox.shrink()
                        : ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final t in tags.take(4))
                                Container(
                                  margin: const EdgeInsets.only(right: 5),
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: T.surf,
                                    border: Border.all(color: T.bdr),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text('$t', style: F.syne(size: 10, weight: FontWeight.w400, color: T.dim)),
                                ),
                            ],
                          ),
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

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: T.scrim,
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: F.syne(size: 10, weight: FontWeight.w700, color: color, letterSpacing: 1.5)),
    );
  }
}

class _CardCta extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;
  final bool compact;
  const _CardCta({required this.accent, required this.onTap, this.compact = false});
  @override
  Widget build(BuildContext context) {
    return HoverFx(
      onTap: onTap,
      builder: (h) => Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 6),
        decoration: BoxDecoration(
          color: h ? accent.withValues(alpha: .07) : Colors.transparent,
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(compact ? 'View →' : 'View Profile →',
            style: F.syne(size: 12, weight: FontWeight.w700, color: accent)),
      ),
    );
  }
}
