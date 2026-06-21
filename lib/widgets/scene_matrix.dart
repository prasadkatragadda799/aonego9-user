import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'common.dart';

/// `SceneMatrix` — professional scene availability, grouped status cards.
class SceneMatrix extends StatelessWidget {
  final List<Map<String, dynamic>> sceneData;
  final Color accent;
  const SceneMatrix({super.key, required this.sceneData, required this.accent});

  @override
  Widget build(BuildContext context) {
    // Build groups: an item with 'group' starts a new group.
    final groups = <Map<String, dynamic>>[];
    Map<String, dynamic>? current;
    for (final item in sceneData) {
      if (item.containsKey('group')) {
        current = {'title': item['group'], 'items': <Map<String, dynamic>>[]};
        groups.add(current);
      } else if (current != null) {
        (current['items'] as List).add(item);
      }
    }

    final twoCol = !isNarrow(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intro
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: T.gold.withOpacity(.04),
            border: Border.all(color: T.gold.withOpacity(.1)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            'A professional listing of content and on-screen work availability for legitimate productions. Verified and restricted categories require production credentials, admin approval, and relevant documentation before any inquiry is forwarded.',
            style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.72),
          ),
        ),
        const SizedBox(height: 22),
        for (final grp in groups) ...[
          _GroupTitle(grp['title']),
          const SizedBox(height: 10),
          _CardWrap(
            twoCol: twoCol,
            children: [for (final s in (grp['items'] as List).cast<Map<String, dynamic>>()) _SceneCard(s, accent)],
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        // Notice
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            color: T.gold.withOpacity(.04),
            border: Border.all(color: T.gold.withOpacity(.12)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text.rich(
            TextSpan(
              style: F.syne(size: 11, weight: FontWeight.w400, color: T.mut, height: 1.7),
              children: [
                TextSpan(text: 'Verified & Restricted scene inquiry process —', style: F.syne(size: 11, weight: FontWeight.w700, color: T.gold)),
                const TextSpan(
                    text: ' Client submits verified production credentials (production house registration, director name + contact) · AOneGo9 admin reviews and approves the production · NDA signed digitally by all parties · Inquiry forwarded to talent · Rates, scope, and conditions negotiated privately. All intimate scene work conducted per industry standards with a certified intimacy coordinator present on set.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupTitle extends StatelessWidget {
  final String text;
  const _GroupTitle(this.text);
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(text.toUpperCase(),
              style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 1.8)),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: T.bdr)),
        ],
      );
}

/// Responsive 1/2-column wrap mirroring `.scene-cards`.
class _CardWrap extends StatelessWidget {
  final bool twoCol;
  final List<Widget> children;
  const _CardWrap({required this.twoCol, required this.children});
  @override
  Widget build(BuildContext context) {
    if (!twoCol) {
      return Column(
        children: [
          for (final c in children) Padding(padding: const EdgeInsets.only(bottom: 10), child: c),
        ],
      );
    }
    return LayoutBuilder(builder: (context, bc) {
      const gap = 10.0;
      final w = (bc.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final c in children) SizedBox(width: w, child: c)],
      );
    });
  }
}

class _SceneCard extends StatelessWidget {
  final Map<String, dynamic> s;
  final Color accent;
  const _SceneCard(this.s, this.accent);

  @override
  Widget build(BuildContext context) {
    final status = (s['status'] ?? 'avail') as String;
    Color border, bg, iconBg, reqColor = T.dim;
    double opacity = 1;
    switch (status) {
      case 'verified':
        border = T.gold.withOpacity(.25);
        bg = T.gold.withOpacity(.04);
        iconBg = T.gold.withOpacity(.15);
        reqColor = T.gold;
        break;
      case 'restricted':
        border = T.red.withOpacity(.2);
        bg = T.red.withOpacity(.04);
        iconBg = T.red.withOpacity(.12);
        reqColor = T.red;
        break;
      case 'no':
        border = T.bdr;
        bg = Colors.transparent;
        iconBg = T.bdr;
        opacity = .38;
        break;
      default: // avail
        border = T.grn.withOpacity(.22);
        bg = T.grn.withOpacity(.03);
        iconBg = T.grn.withOpacity(.18);
    }

    final reqs = (s['reqs'] as List?)?.cast<String>() ?? const [];

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(6)),
                  alignment: Alignment.center,
                  child: Text(s['icon'] ?? '', style: const TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s['label'] ?? '',
                          style: F.syne(size: 13, weight: FontWeight.w700, color: T.text, height: 1.3)),
                      if (s['badge'] != null) ...[
                        const SizedBox(height: 3),
                        _Badge(text: s['badge'], v2: s['badgeClass'] == 'v2'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(s['desc'] ?? '', style: F.syne(size: 11, weight: FontWeight.w400, color: T.mut, height: 1.55)),
            if (reqs.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final r in reqs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('→ ', style: TextStyle(fontSize: 9, color: reqColor)),
                      Expanded(child: Text(r, style: F.syne(size: 10, weight: FontWeight.w400, color: T.dim))),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final bool v2;
  const _Badge({required this.text, required this.v2});
  @override
  Widget build(BuildContext context) {
    final c = v2 ? T.red : T.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(v2 ? .1 : .12),
        border: Border.all(color: c.withOpacity(v2 ? .22 : .25)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(text, style: F.syne(size: 8, weight: FontWeight.w700, color: c, letterSpacing: .8)),
    );
  }
}
