import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../data/app_data.dart';
import '../state/app_state.dart';
import 'form_fields.dart';

/// `LeadForm` — inquiry form with urgent toggle and a success state.
class LeadForm extends StatefulWidget {
  final String name;
  final String cat;
  final Color accent;
  final VoidCallback? onDone;
  const LeadForm({super.key, required this.name, required this.cat, required this.accent, this.onDone});

  @override
  State<LeadForm> createState() => _LeadFormState();
}

class _LeadFormState extends State<LeadForm> {
  bool _urg = false;
  bool _done = false;
  bool _advancePaid = false;
  late final String _ref =
      'AO9-${(Random().nextInt(1 << 30)).toRadixString(36).toUpperCase().padLeft(6, '0').substring(0, 6)}';

  void _payAdvance() {
    context.read<AppState>().payAdvance(_ref);
    setState(() => _advancePaid = true);
  }

  /// Advance / deposit affordance shown after an inquiry is sent — reserves
  /// the slot and is adjusted against the final bill.
  Widget _advanceCard() {
    if (_advancePaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: T.grn.withOpacity(.08),
          border: Border.all(color: T.grn.withOpacity(.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('✓', style: F.syne(size: 14, weight: FontWeight.w800, color: T.grn)),
          const SizedBox(width: 8),
          Flexible(child: Text('Advance of ₹5,000 paid — slot reserved',
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

  void _submit() {
    // Record the inquiry so it is trackable, and raise the vendor/admin
    // "Requested" booking that carries this same reference.
    context.read<AppState>().submitInquiry(
          ref: _ref,
          vendorName: widget.name,
          cat: widget.cat,
          urgent: _urg,
        );
    setState(() => _done = true);
    widget.onDone?.call();
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
                color: T.gold.withOpacity(.07),
                border: Border.all(color: T.gold.withOpacity(.15)),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Field('Full Name *', const Fi('Your name'))),
            const SizedBox(width: 9),
            Expanded(child: Field('Phone *', const Fi('+91 00000 00000'))),
          ]),
          const SizedBox(height: 11),
          Field('Email *', const Fi('you@email.com', keyboardType: TextInputType.emailAddress)),
          const SizedBox(height: 11),
          Row(children: [
            Expanded(child: Field('Preferred Date', const Fi('dd / mm / yyyy'))),
            const SizedBox(width: 9),
            Expanded(child: Field('Location', const Fi('City...'))),
          ]),
          const SizedBox(height: 11),
          Field('Inquiry Type', FiSelect(options: inqOptions)),
          const SizedBox(height: 11),
          Field('Budget Range', const FiSelect(options: budgetRanges)),
          const SizedBox(height: 11),
          Field('Message / Requirements',
              const Fi('Describe your requirement — project type, dates, specific needs, references...', minLines: 3)),
          const SizedBox(height: 11),
          // Urgent toggle
          GestureDetector(
            onTap: () => setState(() => _urg = !_urg),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                color: T.red.withOpacity(.05),
                border: Border.all(color: T.red.withOpacity(_urg ? .28 : .12)),
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
                          style: F.syne(size: 12, weight: FontWeight.w600, color: _urg ? T.red : T.mut)),
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
          _SubmitButton(accent: widget.accent, onTap: _submit),
          const SizedBox(height: 7),
          Text('Posted to ${widget.name} + AOneGo9 admin · Response in 2–4 hrs',
              textAlign: TextAlign.center,
              style: F.syne(size: 10, weight: FontWeight.w400, color: T.dim, height: 1.65)),
        ],
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
  final VoidCallback onTap;
  const _SubmitButton({required this.accent, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
        child: Text('Send Inquiry →', style: F.syne(size: 14, weight: FontWeight.w700, color: T.bg)),
      ),
    );
  }
}
