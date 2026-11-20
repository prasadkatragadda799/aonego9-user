import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/programs.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'common.dart';

/// Profile-specific notification streams — artist updates, vendor updates,
/// the customer's own portfolio updates, events, education, offers, news and
/// sponsored promotions. Saved on the device and synced to the account.
class NotificationPrefsPanel extends StatelessWidget {
  const NotificationPrefsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final on = app.notificationPrefs.values.where((v) => v).length;
    return Blk(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const BlkHeader('Notifications'),
        Text('$on of ${notificationStreams.length} streams on. Choose what reaches you as an artist, vendor or customer.',
            style: F.syne(size: 12.5, weight: FontWeight.w400, color: T.mut, height: 1.5)),
        const SizedBox(height: 10),
        for (final e in notificationStreams.entries)
          _PrefRow(
            label: e.value.split(' — ').first,
            detail: e.value.contains(' — ') ? e.value.split(' — ').last : '',
            on: app.notificationPrefs[e.key] ?? true,
            onChanged: (v) => app.setNotificationPref(e.key, v),
          ),
      ]),
    );
  }
}

class _PrefRow extends StatelessWidget {
  final String label;
  final String detail;
  final bool on;
  final ValueChanged<bool> onChanged;
  const _PrefRow({required this.label, required this.detail, required this.on, required this.onChanged});

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: F.syne(size: 13, weight: FontWeight.w700, color: T.text)),
                if (detail.isNotEmpty) Text(detail, style: F.syne(size: 11.5, color: T.dim, height: 1.4)),
              ]),
            ),
            Switch(
              value: on,
              onChanged: onChanged,
              activeThumbColor: T.onAccent(T.gold),
              activeTrackColor: T.gold,
              inactiveThumbColor: T.dim,
              inactiveTrackColor: T.surf,
            ),
          ]),
        ),
      );
}

/// Shortcuts to the account's planning tools.
class AccountShortcuts extends StatelessWidget {
  const AccountShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = [
      ('📓', 'Planning notebooks', '${app.notebooks.length} saved', () => app.setView('planner')),
      ('📸', 'Book a shoot', 'Portfolio or personal', () => app.openShoots()),
      ('🗳️', 'Campaigns & coupons', '${app.campaigns.length} open', () => app.openCampaigns()),
      ('🏢', 'List a business', 'Onboarding', () => app.openOnboard()),
    ];
    return Blk(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const BlkHeader('Shortcuts'),
        LayoutBuilder(builder: (context, bc) {
          final cols = bc.maxWidth >= 520 ? 2 : 1;
          final w = (bc.maxWidth - 10 * (cols - 1)) / cols;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (final it in items)
              SizedBox(
                width: w,
                child: HoverFx(
                  onTap: it.$4,
                  builder: (h) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: T.surf,
                      border: Border.all(color: h ? T.gold : T.bdr),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(children: [
                      Text(it.$1, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(it.$2, style: F.syne(size: 13, weight: FontWeight.w700, color: T.cream)),
                          Text(it.$3, style: F.syne(size: 11, color: T.dim)),
                        ]),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: h ? T.gold : T.faint),
                    ]),
                  ),
                ),
              ),
          ]);
        }),
      ]),
    );
  }
}
