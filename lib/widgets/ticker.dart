import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';

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
    final apiEvents = context.watch<AppState>().tickerEvents;
    if (apiEvents.isEmpty) {
      return const SizedBox.shrink();
    }
    final liveItems = apiEvents
        .map((e) => '${e['on_poster'] == true ? '🔴' : '📅'} ${e['title']} · ${e['city']} · ${e['date']}')
        .toList();
    final items = [...liveItems, ...liveItems];
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
                        style: F.syne(size: 11, weight: FontWeight.w700, color: T.bg)),
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
                Text('LIVE',
                    style: F.syne(
                        size: 10, weight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
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
