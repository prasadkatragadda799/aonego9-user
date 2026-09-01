import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pad = isNarrow(context) ? 16.0 : 24.0;
    final events = app.platformEvents;
    return PageFrame(
      title: 'Events',
      body: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro(
              eyebrow: 'On the calendar',
              title: 'Castings, open houses, weeks.',
              dek: 'Live and upcoming AOneGo9 events. Anything marked on the poster also runs in the red LIVE bar at the top of browse.',
            ),
            const SizedBox(height: 8),
            if (app.eventsLoading && events.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: T.gold)),
              )
            else if (events.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Text('No events posted yet — the desk will put the next week here.',
                    style: F.syne(size: 14, weight: FontWeight.w400, color: T.mut)),
              )
            else
              LayoutBuilder(builder: (context, bc) {
                final cols = bc.maxWidth >= 840 ? 2 : 1;
                const gap = 16.0;
                final w = (bc.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final e in events) SizedBox(width: w, child: _EventCard(event: e)),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final onPoster = event['on_poster'] == true;
    final date = '${event['date'] ?? ''}';
    final end = '${event['end_date'] ?? ''}';
    final dateLine = end.isNotEmpty && end != date ? '$date  →  $end' : date;
    final bg = (event['bg'] as num?)?.toInt() ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: T.card,
        border: Border.all(color: onPoster ? T.gold.withValues(alpha: .4) : T.bdr),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: AspectRatio(
              aspectRatio: 0.72,
              child: GradientArt(
                bgIndex: bg,
                emoji: event['emoji']?.toString() ?? '📅',
                emojiSize: 32,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Pill(text: '${event['status'] ?? 'upcoming'}'.toUpperCase(), gold: false),
                      if (onPoster) const _Pill(text: 'ON POSTER', gold: true),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(event['title']?.toString() ?? '',
                      style: F.fraunces(size: 18, weight: FontWeight.w700, color: T.cream, height: 1.2)),
                  const SizedBox(height: 8),
                  Text(dateLine, style: F.mono(size: 11, color: T.gold)),
                  const SizedBox(height: 6),
                  Text(
                    [event['venue'], event['city']].where((s) => (s ?? '').toString().isNotEmpty).join('  ·  '),
                    style: F.syne(size: 12.5, weight: FontWeight.w500, color: T.mut),
                  ),
                  if ((event['blurb'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(event['blurb'].toString(),
                        style: F.syne(size: 13, weight: FontWeight.w400, color: T.dim, height: 1.5)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final bool gold;
  const _Pill({required this.text, required this.gold});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: gold ? T.gold.withValues(alpha: .12) : T.surf,
        border: Border.all(color: gold ? T.gold.withValues(alpha: .4) : T.bdr),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: F.syne(size: 9.5, weight: FontWeight.w700, color: gold ? T.gold : T.dim, letterSpacing: 1.2)),
    );
  }
}
