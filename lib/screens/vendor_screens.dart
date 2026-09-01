import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';

/// Redirect screen — vendors manage their business in the dedicated vendor app,
/// not inside the consumer marketplace.
class VendorPortalScreen extends StatelessWidget {
  const VendorPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: T.bg,
      child: Column(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: T.chrome,
              border: Border(bottom: BorderSide(color: T.bdr)),
            ),
            child: Row(children: [
              const MenuBtn(),
              const SizedBox(width: 10),
              HoverFx(
                onTap: () => context.read<AppState>().setView('browse'),
                builder: (h) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: h ? T.bdhi : T.bdr),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('← Back to Browse', style: F.syne(size: 12, weight: FontWeight.w600, color: h ? T.text : T.mut)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Vendor Console', style: F.syne(size: 13, weight: FontWeight.w700, color: T.text))),
            ]),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: T.gold.withValues(alpha: .12),
                          border: Border.all(color: T.gold.withValues(alpha: .25)),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🏪', style: TextStyle(fontSize: 34)),
                      ),
                      const SizedBox(height: 24),
                      Text('Use the AOneGo9 Vendor app', textAlign: TextAlign.center, style: F.fraunces(size: 28, weight: FontWeight.w700, color: T.cream)),
                      const SizedBox(height: 12),
                      Text(
                        'Profile, bio data, gallery, brand work, packages, bookings and KYC are managed in '
                        'the dedicated AOneGo9 Vendor console — not inside the consumer marketplace.',
                        textAlign: TextAlign.center,
                        style: F.syne(size: 14, weight: FontWeight.w400, color: T.mut, height: 1.7),
                      ),
                      const SizedBox(height: 24),
                      // Not yet listed? The application is the actual next step —
                      // this screen used to be a dead end that only offered "go back".
                      GestureDetector(
                        onTap: () => context.read<AppState>().openConnect('apply'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: T.gold, borderRadius: BorderRadius.circular(9)),
                          child: Text('Apply to list your business →',
                              style: F.syne(size: 14, weight: FontWeight.w700, color: T.bg)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => context.read<AppState>().setView('browse'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: T.bdr),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text('Back to Marketplace',
                              style: F.syne(size: 13.5, weight: FontWeight.w600, color: T.mut)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
