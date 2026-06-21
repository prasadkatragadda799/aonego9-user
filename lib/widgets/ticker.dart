import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../data/app_data.dart';

/// `.ticker` — accent band with a red LIVE pill and an infinitely
/// scrolling row of items (CSS tickAnim, translateX 0 → -50% over 34s).
class Ticker extends StatefulWidget {
  final Color accent;
  const Ticker({super.key, required this.accent});

  @override
  State<Ticker> createState() => _TickerState();
}

class _TickerState extends State<Ticker> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 34))..repeat();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _c.addListener(_tick);
  }

  void _tick() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) return;
    // Items are doubled, so scrolling through half == seamless loop.
    _scroll.jumpTo(max / 2 * _c.value);
  }

  @override
  void dispose() {
    _c.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [...tickerItems, ...tickerItems];
    return Container(
      height: 33,
      color: widget.accent,
      child: Stack(
        children: [
          // Scrolling row
          Padding(
            padding: const EdgeInsets.only(left: 112),
            child: IgnorePointer(
              child: ListView.builder(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (_, i) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text('${items[i]}    ◆    ',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600, color: T.bg)),
                  ),
                ),
              ),
            ),
          ),
          // LIVE pill
          Container(
            color: T.red,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(),
                const SizedBox(width: 5),
                const Text('LIVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.3).animate(_c),
      child: Container(
        width: 5,
        height: 5,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }
}
