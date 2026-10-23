import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'common.dart';

/// `.lcard` — a browse listing.
///
/// Two shapes over the same facts:
///
///   · the portfolio card (default) — AOneGo9 sells looks, rooms and crews,
///     so the work leads: a tall photo that can be swiped (or, on desktop,
///     plays through the book on hover) with story-style bars, then the facts;
///   · the directory row ([row]) — photo left, facts right, the dense list a
///     phone scrolls through, with the actions full-width underneath.
///
/// Either way the footer carries the moves a visitor actually makes: enquire
/// on the spot, open the full portfolio, or pass the profile on over
/// WhatsApp. The heart drops it into the shortlist.
///
/// Every interactive extra is a nullable callback, so the card renders on
/// its own (tests, previews) with no app state above it.
class ListingCard extends StatelessWidget {
  final Map<String, dynamic> item;

  /// Opens the full profile.
  final VoidCallback onView;

  /// Quick enquiry from the results; falls back to [onView].
  final VoidCallback? onEnquire;

  /// Share the profile (WhatsApp). Hidden when null.
  final VoidCallback? onShare;

  /// Heart toggle. Hidden when null.
  final VoidCallback? onShortlist;
  final bool shortlisted;

  /// City the card is being shown for — drives the "available here" line.
  final String? availIn;

  /// Directory row instead of the portfolio card.
  final bool row;

  const ListingCard({
    super.key,
    required this.item,
    required this.onView,
    this.onEnquire,
    this.onShare,
    this.onShortlist,
    this.shortlisted = false,
    this.availIn,
    this.row = false,
  });

  /// "Top rated" needs a few bookings behind it, or one 5★ from a friend
  /// would crown a brand-new profile.
  static String? ribbonFor(Map<String, dynamic> item) {
    final rating = (item['rating'] as num?)?.toDouble() ?? 0;
    final count = (item['reviewCount'] as num?)?.toInt() ?? 0;
    if (rating >= 4.5 && count >= 3) return 'Top rated';
    final plan = '${item['badge'] ?? ''}'.trim().toLowerCase();
    if (plan.isNotEmpty && plan != 'starter' && plan != 'free' && plan != 'basic') return 'Featured';
    if (item['isNew'] == true) return 'New face';
    return null;
  }

  /// ₹40,000 → "₹40k", ₹1,50,000 → "₹1.5L" — short enough for a meta row.
  static String priceShort(num p) {
    if (p >= 100000) {
      final l = p / 100000;
      return '₹${l == l.roundToDouble() ? l.toStringAsFixed(0) : l.toStringAsFixed(1)}L';
    }
    if (p >= 1000) {
      final k = p / 1000;
      return '₹${k == k.roundToDouble() ? k.toStringAsFixed(0) : k.toStringAsFixed(1)}k';
    }
    return '₹${p.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = T.ac(item['cat'] as String?);
    return HoverFx(
      onTap: onView,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, h && !row ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: T.card,
          border: Border.all(color: h ? accent.withValues(alpha: .5) : T.bdr),
          borderRadius: BorderRadius.circular(row ? 12 : 14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF15161A).withValues(alpha: h ? .12 : .045),
              blurRadius: h ? 26 : 10,
              offset: Offset(0, h ? 12 : 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: row ? _rowLayout(h, accent) : _cardLayout(h, accent),
      ),
    );
  }

  Widget _cardLayout(bool h, Color accent) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3.6,
            child: _PortfolioPeek(item: item, hovered: h, accent: accent, compact: false, heart: _heart(compact: false)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: _facts(accent, compact: false),
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 16), child: _actions(accent)),
        ],
      );

  Widget _rowLayout(bool h, Color accent) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(
                    width: 108,
                    height: 136,
                    child: _PortfolioPeek(item: item, hovered: h, accent: accent, compact: true, heart: _heart(compact: true)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: _facts(accent, compact: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _actions(accent),
          ],
        ),
      );

  Widget? _heart({required bool compact}) {
    if (onShortlist == null) return null;
    return _HeartBtn(on: shortlisted, onTap: onShortlist!, size: compact ? 30 : 36);
  }

  List<Widget> _facts(Color accent, {required bool compact}) {
    final tags = ((item['tags'] as List?) ?? const []).map((t) => '$t').where((t) => t.trim().isNotEmpty).toList();
    final rating = (item['rating'] as num?)?.toDouble() ?? 0;
    final reviews = (item['reviewCount'] as num?)?.toInt() ?? 0;
    final tagline = (item['tagline'] as String?)?.trim() ?? '';
    final loc = (item['loc'] ?? '').toString();
    final price = item['fromPrice'] is num ? item['fromPrice'] as num : null;

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(item['name'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: F.fraunces(size: compact ? 15.5 : 17, weight: FontWeight.w600, color: T.cream, height: 1.25)),
          ),
          if (item['verified'] == true) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: 'Verified by the AOneGo9 desk',
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.verified_rounded, size: compact ? 16 : 18, color: T.logoCyan),
              ),
            ),
          ],
        ],
      ),
      SizedBox(height: compact ? 6 : 8),
      // Score first, as a filled pill — the thing a directory reader scans
      // for — then the proof behind it and, when known, the entry price.
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          if (rating > 0)
            Container(
              padding: const EdgeInsets.fromLTRB(7, 3, 6, 3),
              decoration: BoxDecoration(color: T.grn, borderRadius: BorderRadius.circular(5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(rating.toStringAsFixed(1),
                    style: F.syne(size: 12, weight: FontWeight.w800, color: Colors.white, height: 1.1)),
                const SizedBox(width: 2),
                const Icon(Icons.star_rounded, size: 13, color: Colors.white),
              ]),
            )
          else
            Text('Not rated yet', style: F.syne(size: 12, weight: FontWeight.w600, color: T.dim)),
          Text(reviews > 0 ? '$reviews ${reviews == 1 ? 'booking' : 'bookings'}' : 'Open to first booking',
              style: F.syne(size: 12, weight: FontWeight.w500, color: T.mut)),
          if (price != null)
            Text('From ${priceShort(price)}', style: F.syne(size: 12, weight: FontWeight.w700, color: accent)),
        ],
      ),
      if (loc.isNotEmpty) ...[
        SizedBox(height: compact ? 6 : 8),
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
        SizedBox(height: compact ? 6 : 10),
        Text(tagline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: F.syne(size: 12.5, weight: FontWeight.w400, color: T.dim, height: 1.45)),
      ],
      if (tags.isNotEmpty && !compact) ...[
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in tags.take(3))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(t,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: F.syne(size: 11, weight: FontWeight.w600, color: accent)),
              ),
          ],
        ),
      ],
    ];
  }

  Widget _actions(Color accent) => Row(
        children: [
          Expanded(
            flex: 5,
            child: _Btn(label: 'Enquire', icon: Icons.send_rounded, filled: true, onTap: onEnquire ?? onView),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: _Btn(label: 'Portfolio', icon: Icons.photo_library_outlined, filled: false, onTap: onView),
          ),
          if (onShare != null) ...[
            const SizedBox(width: 8),
            _ShareBtn(onTap: onShare!),
          ],
        ],
      );
}

/// The photo block — swipeable, and on desktop it plays through the book
/// while the pointer rests on the card. Story bars along the top say how
/// many looks there are, the same language the home page's reel speaks.
class _PortfolioPeek extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool hovered;
  final Color accent;
  final bool compact;
  final Widget? heart;
  const _PortfolioPeek({
    required this.item,
    required this.hovered,
    required this.accent,
    required this.compact,
    required this.heart,
  });

  @override
  State<_PortfolioPeek> createState() => _PortfolioPeekState();
}

class _PortfolioPeekState extends State<_PortfolioPeek> {
  final _page = PageController();
  Timer? _timer;
  int _at = 0;

  List<String> get _urls {
    final seen = <String>{};
    return [
      (widget.item['avatarUrl'] as String?)?.trim() ?? '',
      ...((widget.item['galleryUrls'] as List?) ?? const []).map((e) => '$e'.trim()),
    ].where((u) => u.isNotEmpty && seen.add(u)).take(6).toList();
  }

  @override
  void didUpdateWidget(covariant _PortfolioPeek old) {
    super.didUpdateWidget(old);
    if (widget.hovered == old.hovered) return;
    _timer?.cancel();
    if (widget.hovered && _urls.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 1300), (_) {
        if (!_page.hasClients) return;
        final next = (_at + 1) % _urls.length;
        _page.animateToPage(next, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
      });
    } else if (!widget.hovered && _at != 0 && _page.hasClients) {
      _page.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  Widget _fallback() {
    final id = '${widget.item['id'] ?? ''}';
    return Container(
      decoration: BoxDecoration(gradient: T.gr(id.isEmpty ? 0 : id.hashCode.abs() % 6)),
      alignment: Alignment.center,
      child: AnimatedScale(
        scale: widget.hovered ? 1.06 : 1,
        duration: const Duration(milliseconds: 320),
        child: Text('${widget.item['emoji'] ?? '✦'}', style: TextStyle(fontSize: widget.compact ? 44 : 72)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = _urls;
    final ribbon = ListingCard.ribbonFor(widget.item);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (urls.isEmpty)
          _fallback()
        else
          PageView.builder(
            controller: _page,
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _at = i),
            itemBuilder: (_, i) => Image.network(
              urls[i],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            ),
          ),
        // A soft floor so the ribbon and bars read on any photo.
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Colors.black.withValues(alpha: urls.isEmpty ? 0 : .28), Colors.transparent],
              ),
            ),
          ),
        ),
        // Category stripe — the card's identity at a glance.
        Align(alignment: Alignment.topCenter, child: Container(height: 3, color: widget.accent)),
        if (urls.length > 1)
          Positioned(
            left: 10,
            right: 10,
            top: 9,
            child: IgnorePointer(
              child: Row(children: [
                for (var i = 0; i < urls.length; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: i == _at ? .95 : .4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        if (ribbon != null)
          Positioned(
            left: widget.compact ? 6 : 12,
            bottom: widget.compact ? 6 : 12,
            right: widget.compact ? 6 : 60,
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: widget.compact ? 6 : 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: ribbon == 'New face' ? const Color(0xE615161A) : Colors.white.withValues(alpha: .95),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(ribbon.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: F.syne(
                          size: widget.compact ? 8.5 : 9.5,
                          weight: FontWeight.w800,
                          color: ribbon == 'New face' ? T.logoAmber : widget.accent,
                          letterSpacing: 1.2)),
                ),
              ),
            ),
          ),
        if (widget.heart != null)
          Positioned(top: urls.length > 1 ? 18 : 10, right: widget.compact ? 6 : 10, child: widget.heart!),
      ],
    );
  }
}

class _HeartBtn extends StatelessWidget {
  final bool on;
  final VoidCallback onTap;
  final double size;
  const _HeartBtn({required this.on, required this.onTap, required this.size});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: on ? 'Remove from shortlist' : 'Add to shortlist',
        child: HoverFx(
          onTap: onTap,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: h ? 1 : .92),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .15), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: AnimatedScale(
              scale: on ? 1.12 : (h ? 1.06 : 1),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: size * .52, color: on ? T.maroon : const Color(0xFF3A2A28)),
            ),
          ),
        ),
      );
}

class _ShareBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _ShareBtn({required this.onTap});

  static const _wa = Color(0xFF1FA855);

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Share on WhatsApp',
        child: HoverFx(
          onTap: onTap,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: h ? _wa : _wa.withValues(alpha: .1),
              border: Border.all(color: _wa.withValues(alpha: .5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.chat_rounded, size: 17, color: h ? Colors.white : _wa),
          ),
        ),
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
          final fill = h ? T.goldDark : T.gold;
          final fg = filled ? T.onAccent(fill) : T.cream;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: filled ? fill : (h ? T.surf : T.card),
              border: Border.all(color: filled ? fill : T.bdhi),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
                Text(label, style: F.syne(size: 12.5, weight: FontWeight.w700, color: fg, letterSpacing: .2)),
              ]),
            ),
          );
        },
      );
}
