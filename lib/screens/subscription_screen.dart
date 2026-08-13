import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/api_client.dart';
import '../data/upload_service.dart';
import '../data/user_repository.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

/// ── SUBSCRIPTION — plan grid, UPI-QR + receipt upload, admin-approval flow ──
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _repo = UserRepository();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _subscription; // active subscription, or null
  Map<String, dynamic>? _paymentInfo;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _repo.subscriptionPlans(),
        _repo.paymentInfo(),
        _repo.mySubscriptionRequests(),
      ]);
      Map<String, dynamic>? sub;
      try {
        sub = await _repo.currentSubscription();
      } catch (_) {
        sub = null;
      }
      if (!mounted) return;
      setState(() {
        _plans = results[0] as List<Map<String, dynamic>>;
        _paymentInfo = results[1] as Map<String, dynamic>;
        _requests = results[2] as List<Map<String, dynamic>>;
        _subscription = sub;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Could not load subscription plans — please try again.'; _loading = false; });
    }
  }

  Map<String, dynamic>? get _pendingRequest {
    for (final r in _requests) {
      if (r['status'] == 'pending') return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Container(
      color: T.bg,
      child: Column(children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(color: Color(0xF709090B), border: Border(bottom: BorderSide(color: T.bdr))),
          child: Row(children: [
            _Btn(label: '← Back to Account', onTap: () => app.setView('account')),
            const SizedBox(width: 12),
            const Expanded(child: Text('Subscription', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: T.text))),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _error != null
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!, style: F.syne(size: 13, weight: FontWeight.w500, color: T.mut)),
                        const SizedBox(height: 12),
                        _Btn(label: 'Retry', onTap: _loadAll),
                      ]),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 80),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _currentPlanCard(),
                            if (_pendingRequest != null) _pendingBanner(_pendingRequest!),
                            if (_subscription != null && (_subscription!['price'] as num? ?? 0) > 0) _upgradeBanner(),
                            const SizedBox(height: 4),
                            for (final p in _plans) _planCard(p),
                          ]),
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _currentPlanCard() {
    final sub = _subscription;
    return Blk(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const BlkHeader('Current Plan'),
        if (sub == null)
          Text('No active subscription — pick a plan below to get started.',
              style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.5))
        else ...[
          Row(children: [
            Expanded(
              child: Text(sub['plan_name']?.toString() ?? '—',
                  style: F.fraunces(size: 20, weight: FontWeight.w700, color: T.text)),
            ),
            Text('${sub['status'] ?? ''}'.toUpperCase(),
                style: F.syne(size: 10, weight: FontWeight.w700, color: T.gold, letterSpacing: 1)),
          ]),
          const SizedBox(height: 6),
          Text('₹${_fmtNum(sub['price'])} / plan', style: F.syne(size: 13, weight: FontWeight.w500, color: T.mut)),
          if (sub['renews_on'] != null) ...[
            const SizedBox(height: 3),
            Text('Renews on ${sub['renews_on']}', style: F.syne(size: 12, weight: FontWeight.w400, color: T.dim)),
          ],
        ],
      ]),
    );
  }

  Widget _pendingBanner(Map<String, dynamic> req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: T.gold.withOpacity(0.08),
        border: Border.all(color: T.gold.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(children: [
        const Text('⏳', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Your ${req['plan_name']} subscription is pending admin review.',
            style: F.syne(size: 12, weight: FontWeight.w600, color: T.text, height: 1.4),
          ),
        ),
      ]),
    );
  }

  Widget _upgradeBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: T.surf, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(9)),
      child: Text(
        "You're on the ${_subscription!['plan_name']} plan — upgrade for more.",
        style: F.syne(size: 12, weight: FontWeight.w600, color: T.mut),
      ),
    );
  }

  String _fmtNum(dynamic n) {
    final d = (n as num?)?.toDouble() ?? 0;
    return d.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  Widget _planCard(Map<String, dynamic> plan) {
    final price = (plan['price'] as num?)?.toDouble() ?? 0;
    final features = (plan['features'] as List?)?.cast<dynamic>() ?? const [];
    final recommended = plan['recommended'] == true;

    final currentPlanId = _subscription?['plan_id'];
    final currentPrice = (_subscription?['price'] as num?)?.toDouble();
    final isCurrent = currentPlanId != null && currentPlanId == plan['id'];
    final isUpgrade = !isCurrent && currentPrice != null && price > currentPrice;
    final pendingBlock = _pendingRequest != null;

    String label;
    bool disabled;
    if (isCurrent) {
      label = 'Current plan';
      disabled = true;
    } else if (pendingBlock) {
      label = isUpgrade ? 'Upgrade' : 'Subscribe';
      disabled = true;
    } else if (isUpgrade) {
      label = 'Upgrade';
      disabled = false;
    } else {
      label = 'Subscribe';
      disabled = false;
    }

    return Blk(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(plan['name']?.toString() ?? '', style: F.fraunces(size: 18, weight: FontWeight.w700, color: T.text)),
          ),
          if (recommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: T.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Text('RECOMMENDED', style: F.syne(size: 9, weight: FontWeight.w700, color: T.gold, letterSpacing: 1)),
            ),
        ]),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(price == 0 ? 'Free' : '₹${_fmtNum(price)}', style: F.fraunces(size: 22, weight: FontWeight.w700, color: T.gold)),
          if (price > 0) ...[
            const SizedBox(width: 4),
            Text('/ ${plan['period'] ?? 'mo'}', style: F.syne(size: 12, weight: FontWeight.w500, color: T.mut)),
          ],
        ]),
        const SizedBox(height: 12),
        for (final f in features)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('✓ ', style: TextStyle(color: T.grn, fontSize: 12, fontWeight: FontWeight.w700)),
              Expanded(child: Text(f.toString(), style: F.syne(size: 12, weight: FontWeight.w400, color: T.mut, height: 1.4))),
            ]),
          ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: HoverFx(
            onTap: disabled ? null : () => _onPlanTap(plan),
            builder: (h) => Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: disabled ? T.surf : (h ? T.goldLight : T.gold),
                borderRadius: BorderRadius.circular(8),
                border: disabled ? Border.all(color: T.bdr) : null,
              ),
              child: Text(label,
                  style: F.syne(size: 13, weight: FontWeight.w700, color: disabled ? T.dim : T.bg)),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _onPlanTap(Map<String, dynamic> plan) async {
    final price = (plan['price'] as num?)?.toDouble() ?? 0;
    if (price <= 0) {
      await _submit(plan, '');
      return;
    }
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _PaymentDialog(
        plan: plan,
        paymentInfo: _paymentInfo!,
        onSubmit: (receipt) async {
          Navigator.of(context).pop();
          await _submit(plan, receipt);
        },
      ),
    );
  }

  Future<void> _submit(Map<String, dynamic> plan, String receipt) async {
    final app = context.read<AppState>();
    try {
      await _repo.requestSubscription(plan['id'].toString(), receipt);
      await _loadAll();
      if (!mounted) return;
      app.showToast('Submitted for review', '${plan['name']} subscription request sent to admin', '📨');
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Could not submit your request — please try again.';
      app.showToast('Submission failed', msg, '⚠️');
    }
  }
}

class _PaymentDialog extends StatefulWidget {
  final Map<String, dynamic> plan;
  final Map<String, dynamic> paymentInfo;
  final Future<void> Function(String receiptDataUri) onSubmit;
  const _PaymentDialog({required this.plan, required this.paymentInfo, required this.onSubmit});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  Uint8List? _imageBytes;
  bool _submitting = false;

  String get _upiUri {
    final upiId = widget.paymentInfo['upi_id'] ?? '';
    final payeeName = widget.paymentInfo['payee_name'] ?? '';
    final price = (widget.plan['price'] as num?)?.toDouble() ?? 0;
    final note = 'AONEGO9 ${widget.plan['name']}';
    return 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(payeeName)}&am=${price.toStringAsFixed(0)}&cu=INR&tn=${Uri.encodeComponent(note)}';
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    } catch (_) {
      if (mounted) {
        context.read<AppState>().showToast('Could not pick image', 'Please try again', '⚠️');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Dialog(
      backgroundColor: T.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: T.bdr)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pay via UPI', style: F.fraunces(size: 18, weight: FontWeight.w700, color: T.text)),
              const SizedBox(height: 4),
              Text('${plan['name']} · ₹${(plan['price'] as num).toStringAsFixed(0)}',
                  style: F.syne(size: 12, weight: FontWeight.w500, color: T.mut)),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: QrImageView(data: _upiUri, size: 200, backgroundColor: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Scan with any UPI app · ${widget.paymentInfo['upi_id'] ?? ''}',
                    style: F.syne(size: 11, weight: FontWeight.w400, color: T.dim)),
              ),
              const SizedBox(height: 18),
              if (_imageBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_imageBytes!, height: 120, fit: BoxFit.cover, width: double.infinity),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: HoverFx(
                  onTap: _submitting ? null : _pickImage,
                  builder: (h) => Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(border: Border.all(color: h ? T.bdhi : T.bdr), borderRadius: BorderRadius.circular(8)),
                    child: Text(_imageBytes == null ? 'Upload payment receipt' : 'Change receipt',
                        style: F.syne(size: 13, weight: FontWeight.w600, color: T.text)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: HoverFx(
                  onTap: (_imageBytes == null || _submitting) ? null : _handleSubmit,
                  builder: (h) => Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: (_imageBytes == null || _submitting) ? T.surf : (h ? T.goldLight : T.gold),
                      borderRadius: BorderRadius.circular(8),
                      border: (_imageBytes == null || _submitting) ? Border.all(color: T.bdr) : null,
                    ),
                    child: _submitting
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Submit for review',
                            style: F.syne(size: 13, weight: FontWeight.w700, color: (_imageBytes == null) ? T.dim : T.bg)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: F.syne(size: 12, weight: FontWeight.w500, color: T.mut)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_imageBytes == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final url = await UploadService.uploadImage(
        bytes: _imageBytes!,
        filename: 'receipt.jpg',
        folder: 'receipts',
      );
      await widget.onSubmit(url);
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        context.read<AppState>().showToast('Upload failed', 'Please try again', '⚠️');
      }
    }
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
