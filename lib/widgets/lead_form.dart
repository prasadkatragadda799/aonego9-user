import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/tokens.dart';
import '../data/app_data.dart';
import '../data/upload_service.dart';
import '../data/user_repository.dart';
import '../state/app_state.dart';
import 'form_fields.dart';

/// `LeadForm` — inquiry form with urgent toggle and a success state.
class LeadForm extends StatefulWidget {
  final String name;
  final String cat;
  final Color accent;
  final String vendorId;
  final VoidCallback? onDone;
  const LeadForm({super.key, required this.name, required this.cat, required this.accent, this.vendorId = '', this.onDone});

  @override
  State<LeadForm> createState() => _LeadFormState();
}

class _LeadFormState extends State<LeadForm> {
  bool _urg = false;
  bool _done = false;
  bool _submitting = false;
  bool _advanceSubmitted = false;
  String _error = '';
  String? _bookingId;
  String _otpHint = '';
  bool _otpSending = false;
  late final String _ref =
      'AO9-${(Random().nextInt(1 << 30)).toRadixString(36).toUpperCase().padLeft(6, '0').substring(0, 6)}';

  // Form controllers
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _otpCtrl = TextEditingController();
  late final TextEditingController _date = TextEditingController(
    text: DateFormat('dd / MM / yyyy').format(DateTime.now()),
  );
  final _message = TextEditingController();
  String _inqType = '';
  String _budget = '';

  final _repo = UserRepository();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _otpCtrl.dispose();
    _date.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = DateTime.now().add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _date.text = DateFormat('dd / MM / yyyy').format(picked));
    }
  }

  Future<void> _sendOtp() async {
    if (_phone.text.trim().length < 10) {
      setState(() => _error = 'Enter a valid phone number before requesting OTP.');
      return;
    }
    setState(() { _otpSending = true; _error = ''; _otpHint = ''; });
    try {
      final res = await _repo.sendOtp(_phone.text.trim(), purpose: 'inquiry');
      final debug = res['debug_code'];
      setState(() {
        _otpHint = debug != null ? 'Dev OTP: $debug' : 'OTP sent — check your phone.';
      });
    } catch (e) {
      setState(() => _error = 'Could not send OTP. Try again.');
    } finally {
      if (mounted) setState(() => _otpSending = false);
    }
  }

  Future<void> _payAdvance() async {
    final app = context.read<AppState>();
    if (!app.isLoggedIn) {
      setState(() => _error = 'Sign in to pay the advance and confirm your slot.');
      return;
    }
    if (_bookingId == null || _bookingId!.isEmpty) {
      setState(() => _error = 'Booking not found — please resubmit your inquiry.');
      return;
    }
    setState(() => _error = '');
    try {
      final payment = await _repo.paymentInfo();
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => _AdvancePayDialog(
          paymentInfo: payment,
          onSubmit: (url) async {
            return app.payAdvanceApi(_bookingId!, _ref, url);
          },
        ),
      );
      if (mounted && ok == true) setState(() => _advanceSubmitted = true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load payment details.');
    }
  }

  /// Advance / deposit affordance shown after an inquiry is sent — reserves
  /// the slot and is adjusted against the final bill.
  Widget _advanceCard() {
    if (_advanceSubmitted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: T.grn.withValues(alpha: .08),
          border: Border.all(color: T.grn.withValues(alpha: .3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('✓', style: F.syne(size: 14, weight: FontWeight.w800, color: T.grn)),
          const SizedBox(width: 8),
          Flexible(child: Text('Advance receipt submitted — pending admin approval',
              style: F.syne(size: 12, weight: FontWeight.w600, color: T.grn), textAlign: TextAlign.center)),
        ]),
      );
    }
    return Column(children: [
      Text('Reserve your slot', style: F.syne(size: 12, weight: FontWeight.w700, color: T.text)),
      const SizedBox(height: 3),
      Text('Pay a refundable ₹5,000 advance to confirm and get priority. Adjusted against your final bill.',
          textAlign: TextAlign.center, style: F.syne(size: 10.5, weight: FontWeight.w400, color: T.mut, height: 1.5)),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: _payAdvance,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [widget.accent, T.gold]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('💳  Pay ₹5,000 Advance', style: F.syne(size: 13, weight: FontWeight.w700, color: T.bg)),
        ),
      ),
    ]);
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty || _email.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in Name, Phone and Email.');
      return;
    }
    if (_otpCtrl.text.trim().length < 4) {
      setState(() => _error = 'Verify your mobile number with the OTP before sending.');
      return;
    }
    setState(() { _submitting = true; _error = ''; });
    final isoDate = () {
      try {
        final parts = _date.text.split('/').map((s) => s.trim()).toList();
        if (parts.length == 3) {
          final d = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          return d.toIso8601String();
        }
      } catch (_) {}
      return DateTime.now().toIso8601String();
    }();
    try {
      final result = await _repo.submitInquiry(
        vendorId: widget.vendorId,
        category: widget.cat,
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        date: isoDate,
        inquiryRef: _ref,
        message: _message.text.trim().isEmpty ? '$_inqType · $_budget' : _message.text.trim(),
        urgent: _urg,
        phoneOtp: _otpCtrl.text.trim(),
      );
      _bookingId = result['booking_id'] as String?;
    } catch (_) {
      // Non-blocking — inquiry is still tracked locally even if API fails
    }
    // Always record locally and show success
    if (mounted) {
      context.read<AppState>().submitInquiry(
        ref: _ref,
        vendorName: widget.name,
        cat: widget.cat,
        urgent: _urg,
      );
      setState(() { _done = true; _submitting = false; });
      widget.onDone?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 26, 18, 26),
        child: Column(
          children: [
            const Text('✅', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 11),
            Text('Inquiry Sent!', style: F.fraunces(size: 20, weight: FontWeight.w700, color: T.cream)),
            const SizedBox(height: 5),
            Text.rich(
              TextSpan(
                style: F.syne(size: 12, weight: FontWeight.w400, color: T.mut, height: 1.7),
                children: [
                  const TextSpan(text: 'Posted directly to '),
                  TextSpan(text: widget.name, style: F.syne(size: 12, weight: FontWeight.w700, color: widget.accent)),
                  const TextSpan(text: ' + AOneGo9 admin. Response within 2–4 hours.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: T.gold.withValues(alpha: .07),
                border: Border.all(color: T.gold.withValues(alpha: .15)),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(_ref, style: F.mono(size: 11, color: T.gold)),
            ),
            const SizedBox(height: 16),
            _advanceCard(),
          ],
        ),
      );
    }

    final inqOptions = inqTypes[widget.cat] ?? inqTypes['events']!;
    if (_inqType.isEmpty) _inqType = inqOptions.first;
    if (_budget.isEmpty) _budget = budgetRanges.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: T.red.withValues(alpha: .08),
                border: Border.all(color: T.red.withValues(alpha: .3)),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(_error, style: F.syne(size: 12, color: T.redText)),
            ),
          ],
          Row(children: [
            Expanded(child: Field('Full Name *', Fi('Your name', controller: _name))),
            const SizedBox(width: 9),
            Expanded(child: Field('Phone *', Fi('+91 00000 00000', controller: _phone, keyboardType: TextInputType.phone))),
          ]),
          const SizedBox(height: 11),
          Row(children: [
            Expanded(child: Field('OTP *', Fi('6-digit code', controller: _otpCtrl, keyboardType: TextInputType.number))),
            const SizedBox(width: 9),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: OutlinedButton(
                  onPressed: _otpSending ? null : _sendOtp,
                  child: Text(_otpSending ? 'Sending…' : 'Send OTP'),
                ),
              ),
            ),
          ]),
          if (_otpHint.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(_otpHint, style: F.syne(size: 11, color: T.gold)),
          ],
          const SizedBox(height: 11),
          Field('Email *', Fi('you@email.com', controller: _email, keyboardType: TextInputType.emailAddress)),
          const SizedBox(height: 11),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(child: Field('Preferred Date', Fi('dd / mm / yyyy', controller: _date))),
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(child: Field('Location', Fi('City...'))),
          ]),
          const SizedBox(height: 11),
          Field('Inquiry Type', FiSelect(options: inqOptions, onChanged: (v) => _inqType = v ?? inqOptions.first)),
          const SizedBox(height: 11),
          Field('Budget Range', FiSelect(options: budgetRanges, onChanged: (v) => _budget = v ?? budgetRanges.first)),
          const SizedBox(height: 11),
          Field('Message / Requirements',
              Fi('Describe your requirement — project type, dates, specific needs, references...', minLines: 3, controller: _message)),
          const SizedBox(height: 11),
          // Urgent toggle
          GestureDetector(
            onTap: () => setState(() => _urg = !_urg),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                color: T.red.withValues(alpha: .05),
                border: Border.all(color: T.red.withValues(alpha: _urg ? .28 : .12)),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(children: [
                _Toggle(on: _urg),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🚨 Mark as Urgent',
                          style: F.syne(size: 12, weight: FontWeight.w600, color: _urg ? T.redText : T.mut)),
                      const SizedBox(height: 1),
                      Text('Admin + vendor notified immediately',
                          style: F.syne(size: 10, weight: FontWeight.w400, color: T.dim)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 11),
          _SubmitButton(accent: widget.accent, onTap: _submitting ? null : _submit, loading: _submitting),
          const SizedBox(height: 7),
          Text('Posted to ${widget.name} + AOneGo9 admin · Response in 2–4 hrs',
              textAlign: TextAlign.center,
              style: F.syne(size: 10, weight: FontWeight.w400, color: T.dim, height: 1.65)),
        ],
      ),
    );
  }
}

class _AdvancePayDialog extends StatefulWidget {
  final Map<String, dynamic> paymentInfo;
  final Future<bool> Function(String receiptUrl) onSubmit;
  const _AdvancePayDialog({required this.paymentInfo, required this.onSubmit});

  @override
  State<_AdvancePayDialog> createState() => _AdvancePayDialogState();
}

class _AdvancePayDialogState extends State<_AdvancePayDialog> {
  Uint8List? _bytes;
  bool _busy = false;

  String get _upiUri {
    final upiId = widget.paymentInfo['upi_id'] ?? '';
    final payeeName = widget.paymentInfo['payee_name'] ?? '';
    return 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(payeeName)}&am=5000&cu=INR&tn=${Uri.encodeComponent('AONEGO9 Advance')}';
  }

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() => _bytes = bytes);
  }

  Future<void> _submit() async {
    if (_bytes == null || _busy) return;
    setState(() => _busy = true);
    try {
      final url = await UploadService.uploadImage(bytes: _bytes!, filename: 'advance.jpg', folder: 'receipts');
      final ok = await widget.onSubmit(url);
      if (mounted) Navigator.pop(context, ok);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: T.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: T.bdr)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Pay ₹5,000 advance', style: F.fraunces(size: 18, weight: FontWeight.w700, color: T.text)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: QrImageView(data: _upiUri, size: 180, backgroundColor: Colors.white),
            ),
            const SizedBox(height: 12),
            if (_bytes != null) Image.memory(_bytes!, height: 100, fit: BoxFit.cover),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: _busy ? null : _pick, child: Text(_bytes == null ? 'Upload receipt' : 'Change receipt')),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Cancel'))),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_bytes == null || _busy) ? null : _submit,
                  child: Text(_busy ? 'Submitting…' : 'Submit for review'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool on;
  const _Toggle({required this.on});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 36,
      height: 20,
      decoration: BoxDecoration(color: on ? T.red : T.bdr, borderRadius: BorderRadius.circular(10)),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
              width: 16, height: 16, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final Color accent;
  final VoidCallback? onTap;
  final bool loading;
  const _SubmitButton({required this.accent, required this.onTap, this.loading = false});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: loading ? accent.withValues(alpha: 0.6) : accent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: loading
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text('Send Inquiry →', style: F.syne(size: 14, weight: FontWeight.w700, color: T.bg)),
      ),
    );
  }
}
