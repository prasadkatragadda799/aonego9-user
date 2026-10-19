import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'common.dart';

/// `.lcard` — a browse listing, as a portfolio card.
///
/// AOneGo9 sells looks, rooms and crews, so the work leads: a tall photo with
/// the category stripe and the badge on it, then a body that reads top-down —
/// name and verification, the score, where they work, the pitch, tags — and
/// a footer with the two moves a visitor makes: send a brief, or read the
/// full portfolio. Fluid width; the grid decides how many sit side by side.
class ListingCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onView;
  /// City the card is being shown for — drives the "available here" line.
  final String? availIn;
  const ListingCard({super.key, required this.item, required this.onView, this.availIn});

  @override
  Widget build(BuildContext context) {
    final accent = T.ac(item['cat'] as String?);
    return HoverFx(
      onTap: onView,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, h ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: T.card,
          border: Border.all(color: h ? accent.withValues(alpha: .45) : T.bdr),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF15161A).withValues(alpha: h ? .12 : .05),
              blurRadius: h ? 26 : 10,
              offset: Offset(0, h ? 12 : 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(aspectRatio: 4 / 3.4, child: _photo(h, accent)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: _facts(accent),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: _actions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photo(bool h, Color accent) {
    final id = item['id'] as String? ?? '';
    final gradIndex = id.isEmpty ? 0 : id.hashCode.abs() % 6;
    final url = (item['avatarUrl'] as String?)?.trim() ?? '';
    Widget fallback() => Container(
          decoration: BoxDecoration(gradient: T.gr(gradIndex)),
          alignment: Alignment.center,
          child: AnimatedScale(
            scale: h ? 1.06 : 1,
            duration: const Duration(milliseconds: 320),
            child: Text(item['emoji'] ?? '', style: const TextStyle(fontSize: 72)),
          ),
        );
    final badge = (item['badge'] ?? '').toString().trim();
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url.isNotEmpty)
          AnimatedScale(
            scale: h ? 1.04 : 1,
            duration: const Duration(milliseconds: 320),
            child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback()),
          )
        else
          fallback(),
        // Category stripe — the card's identity at a glance.
        Align(alignment: Alignment.topCenter, child: Container(height: 3, color: accent)),
        if (badge.isNotEmpty)
          Positioned(
            left: 12,
            top: 14,
            right: 60,
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .94),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(badge.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: F.syne(size: 9.5, weight: FontWeight.w800, color: accent, letterSpacing: 1.4)),
              ),
            ),
          ),
        if (item['isNew'] == true)
          Positioned(
            right: 12,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xE615161A), borderRadius: BorderRadius.circular(2)),
              child: Text('NEW',
                  style: F.syne(size: 9.5, weight: FontWeight.w800, color: T.logoAmber, letterSpacing: 1.4)),
            ),
          ),
      ],
    );
  }

  List<Widget> _facts(Color accent) {
    final tags = (item['tags'] as List?) ?? const [];
    final rating = (item['rating'] as num?)?.toDouble() ?? 0;
    final reviews = item['reviewCount'] ?? 0;
    final tagline = (item['tagline'] as String?)?.trim() ?? '';
    final loc = (item['loc'] ?? '').toString();

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(item['name'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: F.fraunces(size: 17, weight: FontWeight.w600, color: T.cream, height: 1.25)),
          ),
          if (item['verified'] == true) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Verified by the AOneGo9 desk',
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: T.gold, shape: BoxShape.circle),
                child: Icon(Icons.check_rounded, size: 12, color: T.onAccent(T.gold)),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 6),
      // Score as gold type with a hairline divider — no filled badge.
      Row(children: [
        Icon(Icons.star_rounded, size: 16, color: T.gold),
        const SizedBox(width: 3),
        Text(rating.toStringAsFixed(1), style: F.syne(size: 13, weight: FontWeight.w800, color: T.cream)),
        Container(width: 1, height: 12, color: T.bdr, margin: const EdgeInsets.symmetric(horizontal: 8)),
        Flexible(
          child: Text('$reviews ${reviews == 1 ? 'review' : 'reviews'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: F.syne(size: 12, weight: FontWeight.w500, color: T.mut)),
        ),
      ]),
      if (loc.isNotEmpty) ...[
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.place_outlined, size: 14, color: accent),
          const SizedBox(width: 4),
          Expanded(
            child: Text(loc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: F.syne(size: 12.5, weight: FontWeight.w500, color: T.mut)),
          ),
        ]),
      ],
      if (availIn != null) ...[
        const SizedBox(height: 4),
        Builder(builder: (_) {
          final l = loc.toLowerCase();
          final panIndia = l.contains('pan india') || l.contains('all india');
          return Text(panIndia ? '● Serves all India' : '● Taking work in $availIn',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: F.syne(size: 11.5, weight: FontWeight.w600, color: T.grn));
        }),
      ],
      if (tagline.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(tagline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: F.syne(size: 12.5, weight: FontWeight.w400, color: T.dim, height: 1.45)),
      ],
      if (tags.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(
          tags.take(4).map((t) => '#$t').join('  '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: F.syne(size: 11.5, weight: FontWeight.w600, color: accent),
        ),
      ],
    ];
  }

  /// Both actions open the profile — that is where the brief form, the
  /// portfolio and the contact links live. The primary one is named for what
  /// the visitor is actually about to do.
  Widget _actions() => Row(
        children: [
          Expanded(child: _Btn(label: 'Send a Brief', icon: Icons.send_rounded, filled: true, onTap: onView)),
          const SizedBox(width: 8),
          Expanded(child: _Btn(label: 'Portfolio', icon: Icons.photo_library_outlined, filled: false, onTap: onView)),
        ],
      );
}

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.icon, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) {
          final ink = T.cream;
          final fg = filled ? T.onAccent(ink) : ink;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: filled ? (h ? T.gold : ink) : (h ? T.surf : T.card),
              border: Border.all(color: filled ? (h ? T.gold : ink) : T.bdhi),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 14, color: filled && h ? T.onAccent(T.gold) : fg),
                const SizedBox(width: 6),
                Text(label,
                    style: F.syne(
                        size: 12.5, weight: FontWeight.w700, color: filled && h ? T.onAccent(T.gold) : fg, letterSpacing: .2)),
              ]),
            ),
          );
        },
      );
}
