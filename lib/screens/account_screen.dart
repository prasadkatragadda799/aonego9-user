import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../data/user_repository.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// ── ACCOUNT — logged-in customer's profile + booking history ──
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _repo = UserRepository();
  List<Map<String, dynamic>>? _bookings; // null = loading, [] = none/failed
  Map<String, dynamic>? _subscription; // null = none/loading — see _subLoaded
  bool _subLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadSubscription();
  }

  Future<void> _load() async {
    try {
      final b = await _repo.myBookings();
      if (mounted) setState(() => _bookings = b);
    } catch (_) {
      if (mounted) setState(() => _bookings = []);
    }
  }

  Future<void> _loadSubscription() async {
    try {
      final s = await _repo.currentSubscription();
      if (mounted) setState(() { _subscription = s; _subLoaded = true; });
    } catch (_) {
      if (mounted) setState(() => _subLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.currentUser ?? {};
    return Container(
      color: T.bg,
      child: Column(children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(color: Color(0xF709090B), border: Border(bottom: BorderSide(color: T.bdr))),
          child: Row(children: [
            _Btn(label: '← Back to Browse', onTap: app.backToBrowse),
            const SizedBox(width: 12),
            Expanded(child: Text('My Account', style: F.syne(size: 13, weight: FontWeight.w700, color: T.text))),
            _Btn(label: 'Log Out', onTap: app.logoutUser),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 80),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Blk(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const BlkHeader('Profile'),
                      _row('Name', user['name']?.toString() ?? '—'),
                      _row('Email', user['email']?.toString() ?? '—'),
                      _row('Phone', user['phone']?.toString() ?? '—'),
                      _row('City', user['city']?.toString() ?? '—'),
                    ]),
                  ),
                  HoverFx(
                    onTap: () => context.read<AppState>().setView('subscription'),
                    builder: (h) => Blk(
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            const BlkHeader('Subscription'),
                            Text(
                              !_subLoaded
                                  ? 'Loading…'
                                  : (_subscription != null ? '${_subscription!['plan_name']} plan · ${_subscription!['status']}' : 'No active subscription'),
                              style: F.syne(size: 13, weight: FontWeight.w600, color: T.text),
                            ),
                            const SizedBox(height: 4),
                            Text('Manage Subscription', style: F.syne(size: 12, weight: FontWeight.w600, color: T.gold)),
                          ]),
                        ),
                        Icon(Icons.chevron_right, color: h ? T.text : T.mut),
                      ]),
                    ),
                  ),
                  Blk(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const BlkHeader('My Bookings'),
                      if (_bookings == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      else if (_bookings!.isEmpty)
                        Text('No bookings yet — inquiries you send become bookings once a vendor responds.',
                            style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.5))
                      else
                        for (final b in _bookings!) _bookingCard(b),
                    ]),
                  ),
                  if (app.inquiries.isNotEmpty)
                    Blk(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const BlkHeader('Recent Inquiries'),
                        for (final i in app.inquiries)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(children: [
                              Expanded(
                                child: Text('${i.vendorName} · ${i.ref}',
                                    style: F.syne(size: 13, weight: FontWeight.w600, color: T.text)),
                              ),
                              Text(i.status, style: F.syne(size: 12, weight: FontWeight.w600, color: T.gold)),
                            ]),
                          ),
                      ]),
                    ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          SizedBox(width: 90, child: Text(label, style: F.syne(size: 12, weight: FontWeight.w400, color: T.dim))),
          Expanded(child: Text(value, style: F.syne(size: 13, weight: FontWeight.w600, color: T.text))),
        ]),
      );

  Widget _bookingCard(Map<String, dynamic> b) {
    final amount = (b['amount'] as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: T.surf, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(9)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(b['service']?.toString() ?? 'Booking', style: F.syne(size: 13, weight: FontWeight.w700, color: T.text)),
            const SizedBox(height: 3),
            Text('${b['date'] ?? ''} · ${b['location'] ?? ''}', style: F.syne(size: 11, weight: FontWeight.w400, color: T.dim)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹${amount.toStringAsFixed(0)}', style: F.fraunces(size: 15, weight: FontWeight.w700, color: T.gold)),
          const SizedBox(height: 3),
          Text('${b['status'] ?? ''}'.toUpperCase(), style: F.syne(size: 10, weight: FontWeight.w700, color: T.mut, letterSpacing: 1)),
        ]),
      ]),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(border: Border.all(color: h ? T.bdhi : T.bdr), borderRadius: BorderRadius.circular(6)),
          child: Text(label, style: F.syne(size: 12, weight: FontWeight.w600, color: h ? T.text : T.mut)),
        ),
      );
}
