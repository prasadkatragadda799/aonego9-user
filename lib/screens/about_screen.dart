import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../data/editorial.dart';
import '../state/app_state.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = isNarrow(context) ? 16.0 : 24.0;
    return PageFrame(
      title: 'About',
      body: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro(
              eyebrow: 'The house',
              title: 'A modeling agency that behaves like a production floor.',
              dek: 'AOneGo9 is three modules on one desk: a public marketplace, a vendor console, and a super-admin that never lets unverified work onto the floor.',
            ),
            const SizedBox(height: 12),
            Text(
              'You browse full books and packages before you reach out. Vendors keep their calendar and KYC in their own app. The admin desk verifies people, curates events, and publishes the digest. Nothing important is a rumour in a WhatsApp thread.',
              style: F.syne(size: 15, weight: FontWeight.w400, color: T.text, height: 1.75),
            ),
            const SizedBox(height: 32),
            Text('THE THREE MODULES',
                style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 2)),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, bc) {
              final cols = bc.maxWidth >= 840 ? 3 : 1;
              const gap = 14.0;
              final w = (bc.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final m in aboutModules) SizedBox(width: w, child: _ModuleCard(mod: m)),
                ],
              );
            }),
            const SizedBox(height: 36),
            Text('HOW A BOOKING MOVES',
                style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 2)),
            const SizedBox(height: 14),
            const _Steps(),
            const SizedBox(height: 36),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isNarrow(context) ? 20 : 28),
              decoration: BoxDecoration(
                color: T.card,
                border: Border.all(color: T.gold.withValues(alpha: .28)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Every listing is admin-verified.',
                      style: F.fraunces(size: 22, weight: FontWeight.w700, color: T.cream)),
                  const SizedBox(height: 8),
                  Text(
                    'KYC, packages and a public portfolio before a profile goes live. Scene work that needs a coordinator says so on the profile — not after you\'ve already briefed the talent.',
                    style: F.syne(size: 14, weight: FontWeight.w400, color: T.mut, height: 1.7),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      HoverFx(
                        onTap: () => context.read<AppState>().backToBrowse(),
                        builder: (h) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          decoration: BoxDecoration(color: T.gold, borderRadius: BorderRadius.circular(8)),
                          child: Text('Browse the floor', style: F.syne(size: 13, weight: FontWeight.w700, color: T.bg)),
                        ),
                      ),
                      HoverFx(
                        onTap: () => context.read<AppState>().setView('partners'),
                        builder: (h) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          decoration: BoxDecoration(
                            border: Border.all(color: h ? T.gold : T.bdr),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Who we partner with', style: F.syne(size: 13, weight: FontWeight.w700, color: T.gold)),
                        ),
                      ),
                    ],
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

class _ModuleCard extends StatelessWidget {
  final Map<String, String> mod;
  const _ModuleCard({required this.mod});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: T.card,
        border: Border.all(color: T.bdr),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mod['icon'] ?? '', style: const TextStyle(fontSize: 22, color: T.gold)),
          const SizedBox(height: 14),
          Text(mod['name'] ?? '', style: F.fraunces(size: 22, weight: FontWeight.w700, color: T.cream)),
          const SizedBox(height: 4),
          Text(mod['line'] ?? '', style: F.syne(size: 12, weight: FontWeight.w600, color: T.gold)),
          const SizedBox(height: 12),
          Expanded(
            child: Text(mod['copy'] ?? '',
                style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.6)),
          ),
        ],
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps();

  static const items = [
    ['01', 'Browse', 'Open a book. Read packages, scene rules and the city they serve.'],
    ['02', 'Inquire', 'Send a dated brief. The vendor and the admin desk both see the same reference.'],
    ['03', 'Hold', 'Pay the refundable advance when you want the slot locked.'],
    ['04', 'Shoot', 'The vendor console runs the day. You track status from your account.'],
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, bc) {
      final cols = bc.maxWidth >= 840 ? 4 : 2;
      const gap = 12.0;
      final w = (bc.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final s in items)
            SizedBox(
              width: w,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: T.card,
                  border: Border.all(color: T.bdr),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s[0], style: F.fraunces(size: 18, weight: FontWeight.w700, color: T.gold)),
                    const SizedBox(height: 8),
                    Text(s[1], style: F.syne(size: 14, weight: FontWeight.w700, color: T.cream)),
                    const SizedBox(height: 6),
                    Text(s[2], style: F.syne(size: 12.5, weight: FontWeight.w400, color: T.mut, height: 1.5)),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}
