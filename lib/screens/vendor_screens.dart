import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
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
            decoration: const BoxDecoration(
              color: Color(0xF709090B),
              border: Border(bottom: BorderSide(color: T.bdr)),
            ),
            child: Row(children: [
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
                          color: T.gold.withOpacity(.12),
                          border: Border.all(color: T.gold.withOpacity(.25)),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🏪', style: TextStyle(fontSize: 34)),
                      ),
                      const SizedBox(height: 24),
                      Text('Use the AOneGo9 Vendor app', textAlign: TextAlign.center, style: F.fraunces(size: 28, weight: FontWeight.w700, color: T.cream)),
                      const SizedBox(height: 12),
                      Text(
                        'Profile, portfolio, bookings, earnings and KYC are managed in the dedicated vendor console — not inside the consumer marketplace.',
                        textAlign: TextAlign.center,
                        style: F.syne(size: 14, weight: FontWeight.w400, color: T.mut, height: 1.7),
                      ),
                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: () => context.read<AppState>().setView('browse'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: T.gold, borderRadius: BorderRadius.circular(9)),
                          child: Text('Back to Marketplace', style: F.syne(size: 14, weight: FontWeight.w700, color: T.bg)),
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
