import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' as sched;
import 'package:provider/provider.dart';
import '../data/directory.dart';
import '../data/taxonomy.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'common.dart';

/// The notification bar — "update notification bar, all sections".
///
/// Collapsed it is the accent band the site already had: a LIVE pill and a
/// drifting marquee of what's coming up. The difference is that it is now
/// interactive and it carries every division, not only platform events —
/// workshops, webinars and desk updates land in the same stream, each tagged
/// with its division and its city + state.
///
/// Expanded it becomes a panel: filter by division, then jump straight to the
/// thing itself. The old marquee was wrapped in [IgnorePointer], so a visitor
/// could read that a casting was open and had no way to act on it.
class UpdatesBar extends StatefulWidget {
  final Color accent;
  const UpdatesBar({super.key, required this.accent});

  @override
  State<UpdatesBar> createState() => _UpdatesBarState();
}

class _UpdatesBarState extends State<UpdatesBar> {
  bool _open = false;
  String _division = 'all';

  List<UpdateEntry> _visible(List<UpdateEntry> all) =>
      _division == 'all' ? all : all.where((u) => u.division == _division).toList();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final all = app.updateFeed;
    if (all.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _band(all),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _open ? _panel(app, all) : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }

  Widget _band(List<UpdateEntry> all) {
    final liveCount = all.where((u) => u.live).length;
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 33,
          color: widget.accent,
          child: Row(
            children: [
              // LIVE pill — red fill, white glyphs, as before.
              Container(
                color: T.red,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const _PulseDot(),
                  const SizedBox(width: 5),
                  Text(liveCount > 0 ? 'LIVE $liveCount' : 'LIVE',
                      style: F.syne(size: 10, weight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
                ]),
              ),
              Expanded(child: _Marquee(entries: all, paused: _open)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('${all.length} updates',
                      style: F.syne(size: 10, weight: FontWeight.w700, color: T.bg, letterSpacing: 1)),
                  const SizedBox(width: 5),
                  AnimatedRotation(
                    turns: _open ? .5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: T.bg),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panel(AppState app, List<UpdateEntry> all) {
    final rows = _visible(all);
    // Only offer a division chip when something is actually filed under it.
    final present = <String>{for (final u in all) if (u.division.isNotEmpty) u.division};

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: T.surf,
        border: Border(bottom: BorderSide(color: T.bdr)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isNarrow(context) ? 14 : 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('WHAT\'S COMING UP',
                        style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 2)),
                    const SizedBox(width: 10),
                    Expanded(child: Container(height: 1, color: T.bdr)),
                    const SizedBox(width: 10),
                    Text('📍 ${app.location}', style: F.mono(size: 10, color: T.dim)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _DivChip(
                      label: 'All divisions',
                      icon: '⚡',
                      active: _division == 'all',
                      accent: T.gold,
                      onTap: () => setState(() => _division = 'all'),
                    ),
                    for (final d in divisions)
                      if (present.contains(d.id))
                        _DivChip(
                          label: d.name,
                          icon: d.icon,
                          active: _division == d.id,
                          accent: T.dac(d.id),
                          onTap: () => setState(() => _division = d.id),
                        ),
                  ],
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text('Nothing scheduled in this division yet.',
                        style: F.syne(size: 12.5, weight: FontWeight.w400, color: T.mut)),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) => _UpdateRow(
                        entry: rows[i],
                        onTap: () => _goTo(app, rows[i]),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(children: [
                  _PanelLink(
                    label: 'All workshops & webinars →',
                    onTap: () {
                      setState(() => _open = false);
                      app.setView('sessions');
                    },
                  ),
                  const SizedBox(width: 18),
                  _PanelLink(
                    label: 'Event calendar →',
                    onTap: () {
                      setState(() => _open = false);
                      app.setView('events');
                    },
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goTo(AppState app, UpdateEntry e) {
    setState(() => _open = false);
    switch (e.kind) {
      case 'workshop':
      case 'webinar':
        app.setView('sessions');
      case 'event':
        app.setView('events');
      default:
        app.setView('newsletter');
    }
  }
}

class _UpdateRow extends StatelessWidget {
  final UpdateEntry entry;
  final VoidCallback onTap;
  const _UpdateRow({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = T.dac(entry.division);
    final narrow = isNarrow(context);
    return HoverFx(
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: h ? T.card : T.bg,
          border: Border.all(color: h ? accent.withValues(alpha: .5) : T.bdr),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(entry.emoji, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(entry.kindLabel.toUpperCase(),
                          style: F.syne(size: 8.5, weight: FontWeight.w700, color: accent, letterSpacing: 1)),
                    ),
                    if (entry.live) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: T.red.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text('FILLING',
                            style: F.syne(size: 8.5, weight: FontWeight.w700, color: T.redText, letterSpacing: 1)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(entry.title,
                      maxLines: narrow ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: F.syne(size: 12.5, weight: FontWeight.w700, color: h ? T.cream : T.text)),
                  if (entry.place.isNotEmpty || entry.date.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (entry.place.isNotEmpty) '📍 ${entry.place}',
                        if (entry.date.isNotEmpty) entry.date,
                      ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: F.mono(size: 10, color: T.dim),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: h ? accent : T.faint),
          ],
        ),
      ),
    );
  }
}

class _DivChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  const _DivChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: .16) : Colors.transparent,
            border: Border.all(color: active ? accent : (h ? accent.withValues(alpha: .5) : T.bdr)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(icon, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 6),
            Text(label,
                style: F.syne(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: active ? accent : (h ? T.text : T.mut))),
          ]),
        ),
      );
}

class _PanelLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PanelLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Text(label,
            style: F.syne(size: 12, weight: FontWeight.w700, color: h ? T.goldLight : T.gold)),
      );
}

/// The drifting headline strip inside the collapsed band.
class _Marquee extends StatefulWidget {
  final List<UpdateEntry> entries;
  final bool paused;
  const _Marquee({required this.entries, required this.paused});

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee> with SingleTickerProviderStateMixin {
  final _sc = ScrollController();
  sched.Ticker? _ticker;
  Duration _last = Duration.zero;

  /// Slow enough to read a full headline while it passes.
  static const double _pxPerSecond = 34;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _sc.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    var dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0 || widget.paused || !_sc.hasClients) return;
    // A throttled background tab produces huge deltas; clamp rather than skip,
    // so the strip never lurches and never stalls outright.
    if (dt > 1 / 30) dt = 1 / 30;

    final max = _sc.position.maxScrollExtent;
    if (max <= 0) return;
    // The list is doubled, so wrapping at the halfway point is seamless.
    final half = max / 2;
    var next = _sc.offset + _pxPerSecond * dt;
    if (next >= half) next -= half;
    _sc.jumpTo(next);
  }

  @override
  Widget build(BuildContext context) {
    final items = [...widget.entries, ...widget.entries];
    return IgnorePointer(
      child: ListView.builder(
        controller: _sc,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final e = items[i];
          final bits = [
            '${e.emoji} ${e.kindLabel.toUpperCase()}',
            e.title,
            if (e.place.isNotEmpty) e.place,
            if (e.date.isNotEmpty) e.date,
          ].join(' · ');
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text('$bits    ◆',
                  style: F.syne(size: 11, weight: FontWeight.w700, color: T.bg)),
            ),
          );
        },
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 1.0, end: 0.3).animate(_c),
        child: Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      );
}
