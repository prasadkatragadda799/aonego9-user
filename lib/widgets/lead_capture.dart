import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'program_kit.dart';

/// Identity block (name, email, phone, city) + whatever the caller adds,
/// submitted to the leads desk under [kind].
///
/// Every programme form asks the same four questions first; keeping them in
/// one widget means one place for validation, pre-fill from the signed-in
/// account and the success state.
class LeadCapture extends StatefulWidget {
  final String kind;
  final String submitLabel;
  final String successTitle;
  final String successBody;

  /// Extra fields shown under the identity block.
  final List<Widget> extra;

  /// Extra payload merged into the submission. Return null to block submit
  /// (the caller shows its own message).
  final Map<String, dynamic>? Function()? payload;
  final bool requirePhone;
  final VoidCallback? onDone;

  /// Custom submission (e.g. a dedicated endpoint). Defaults to the leads desk.
  final Future<bool> Function(Map<String, dynamic> payload)? submit;
  const LeadCapture({
    super.key,
    required this.kind,
    required this.submitLabel,
    this.successTitle = 'Thank you — we have it',
    this.successBody = 'The AOneGo9 desk will get back to you within one working day.',
    this.extra = const [],
    this.payload,
    this.requirePhone = true,
    this.onDone,
    this.submit,
  });

  @override
  State<LeadCapture> createState() => _LeadCaptureState();
}

class _LeadCaptureState extends State<LeadCapture> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final Map<String, String> _errors = {};
  bool _busy = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final u = app.currentUser;
    if (u != null) {
      _name.text = '${u['name'] ?? ''}';
      _email.text = '${u['email'] ?? ''}';
      _phone.text = '${u['phone'] ?? ''}';
    }
    _city.text = '${u?['city'] ?? ''}'.isNotEmpty ? '${u!['city']}' : (app.location == 'All India' ? '' : app.location);
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Drop a field's error as soon as the visitor starts fixing it.
  void _clear(String key) {
    if (_errors.remove(key) != null) setState(() {});
  }

  Future<void> _submit() async {
    final app = context.read<AppState>();
    _errors.clear();
    if (_name.text.trim().length < 2) _errors['name'] = 'Enter your full name';
    if (!validEmail(_email.text)) _errors['email'] = 'Enter a valid email';
    if (widget.requirePhone && !validPhone(_phone.text)) _errors['phone'] = 'Enter a 10-digit mobile number';
    if (!widget.requirePhone && _phone.text.trim().isNotEmpty && !validPhone(_phone.text)) {
      _errors['phone'] = 'Enter a 10-digit mobile number';
    }
    if (_errors.isNotEmpty) {
      setState(() {});
      return;
    }
    final extra = widget.payload?.call();
    if (widget.payload != null && extra == null) return;
    setState(() => _busy = true);
    final body = {
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'city': _city.text.trim(),
      ...?extra,
    };
    final ok = widget.submit != null ? await widget.submit!(body) : await app.submitLead(widget.kind, body);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = ok;
    });
    if (!ok) {
      if (widget.submit == null) {
        app.showToast('Could not send', 'Check your connection and try again — your details are kept', '⚠️');
      }
    } else {
      widget.onDone?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: T.grn.withValues(alpha: .14), shape: BoxShape.circle),
          child: Icon(Icons.check_rounded, color: T.grn, size: 28),
        ),
        const SizedBox(height: 14),
        Text(widget.successTitle,
            textAlign: TextAlign.center, style: F.fraunces(size: 18, weight: FontWeight.w700, color: T.cream)),
        const SizedBox(height: 6),
        Text(widget.successBody,
            textAlign: TextAlign.center, style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.55)),
        const SizedBox(height: 16),
        OutlineBtn('Send another', onTap: () => setState(() => _done = false)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      FieldPair(
        LabeledInput(
            label: 'Full name',
            hint: 'Your name',
            controller: _name,
            error: _errors['name'],
            required: true,
            onChanged: (_) => _clear('name')),
        LabeledInput(
            label: 'Email',
            hint: 'you@example.com',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            error: _errors['email'],
            required: true,
            onChanged: (_) => _clear('email')),
      ),
      const SizedBox(height: 12),
      FieldPair(
        LabeledInput(
            label: 'Mobile',
            hint: '+91 98765 43210',
            controller: _phone,
            keyboardType: TextInputType.phone,
            error: _errors['phone'],
            required: widget.requirePhone,
            onChanged: (_) => _clear('phone')),
        LabeledInput(label: 'City', hint: 'Mumbai', controller: _city),
      ),
      for (final w in widget.extra) ...[const SizedBox(height: 12), w],
      const SizedBox(height: 18),
      PrimaryBtn(widget.submitLabel, onTap: _submit, busy: _busy, icon: Icons.send_rounded, expand: true),
      const SizedBox(height: 10),
      Text('We only use these details to reply to this request.',
          textAlign: TextAlign.center, style: F.syne(size: 11, weight: FontWeight.w500, color: T.dim)),
    ]);
  }
}
