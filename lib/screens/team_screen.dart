import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/directory.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';

/// "Our team member — all section."
///
/// Grouped by desk rather than listed flat, because the useful question a
/// visitor has here is "who do I talk to about X", not "how many people work
/// there".
class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pad = isNarrow(context) ? 16.0 : 24.0;

    // Preserve the canonical desk order, then append any desk the backend
    // introduced that this build doesn't know about.
    final byDesk = <String, List<TeamMember>>{};
    for (final m in app.team) {
      byDesk.putIfAbsent(m.desk, () => []).add(m);
    }
    final ordered = [
      ...teamDesks.where(byDesk.containsKey),
      ...byDesk.keys.where((d) => !teamDesks.contains(d)),
    ];

    return PageFrame(
      title: 'Our team',
      maxWidth: 1180,
      body: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro(
              eyebrow: 'The people behind the floor',
              title: 'Every listing clears a desk before it clears the door.',
              dek: 'AOneGo9 is not an automated directory. Casting, production, verification and editorial '
                  'are run by people who have worked the sets they are booking for.',
            ),
            const SizedBox(height: 24),
            for (final desk in ordered) ...[
              Row(children: [
                Container(width: 16, height: 1.5, color: T.gold),
                const SizedBox(width: 9),
                Text(desk.toUpperCase(),
                    style: F.syne(size: 10.5, weight: FontWeight.w700, color: T.gold, letterSpacing: 2)),
                const SizedBox(width: 10),
                Expanded(child: Container(height: 1, color: T.bdr)),
                const SizedBox(width: 10),
                Text('${byDesk[desk]!.length}', style: F.mono(size: 10, color: T.dim)),
              ]),
              const SizedBox(height: 14),
              LayoutBuilder(builder: (context, bc) {
                final cols = bc.maxWidth >= 1000 ? 4 : (bc.maxWidth >= 720 ? 3 : (bc.maxWidth >= 440 ? 2 : 1));
                const gap = 13.0;
                final w = (bc.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(spacing: gap, runSpacing: gap, children: [
                  for (final m in byDesk[desk]!) SizedBox(width: w, child: _MemberCard(member: m)),
                ]);
              }),
              const SizedBox(height: 30),
            ],
            Container(
              padding: EdgeInsets.all(isNarrow(context) ? 20 : 28),
              decoration: BoxDecoration(
                color: T.surf,
                border: Border.all(color: T.bdr),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Want a desk here?', style: F.fraunces(size: 23, weight: FontWeight.w700, color: T.cream)),
                const SizedBox(height: 8),
                Text(
                  'We hire from the industry, not around it. Casting, production, verification, '
                  'editorial and partnerships all take applications.',
                  style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.65),
                ),
                const SizedBox(height: 16),
                HoverFx(
                  onTap: () => app.openConnect('join'),
                  builder: (h) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: h ? T.goldLight : T.gold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Join us →', style: F.syne(size: 13, weight: FontWeight.w700, color: T.bg)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final TeamMember member;
  const _MemberCard({required this.member});

  String get _initials {
    final parts = member.name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return HoverFx(
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: T.card,
          border: Border.all(color: h ? T.gold.withValues(alpha: .45) : T.bdr),
          borderRadius: BorderRadius.circular(13),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          AspectRatio(
            // Portrait crop in the multi-column grid, where cards sit on one
            // baseline. In a single phone column that same ratio makes a
            // full-width band ~275px tall — mostly empty when the member has
            // no photo yet — so it flattens out.
            aspectRatio: isNarrow(context) ? 1.9 : 1.25,
            child: member.photoUrl.trim().isEmpty
                ? _monogram()
                : Image.network(
                    member.photoUrl.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _monogram(),
                    loadingBuilder: (_, child, p) => p == null ? child : _monogram(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 15),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: F.fraunces(size: 16.5, weight: FontWeight.w700, color: T.cream)),
              const SizedBox(height: 4),
              Text(member.role,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: F.syne(size: 11, weight: FontWeight.w700, color: T.gold, height: 1.35)),
              if (member.bio.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(member.bio,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: F.syne(size: 11.5, weight: FontWeight.w400, color: T.mut, height: 1.55)),
              ],
              if (member.city.isNotEmpty) ...[
                const SizedBox(height: 9),
                Text('📍 ${member.city}', style: F.mono(size: 10, color: T.dim)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _monogram() => Container(
        decoration: BoxDecoration(gradient: T.gr(member.bg)),
        alignment: Alignment.center,
        child: Text(_initials,
            style: F.fraunces(size: 30, weight: FontWeight.w700, color: T.gold.withValues(alpha: .75))),
      );
}
