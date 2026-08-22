import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../data/editorial.dart';
import '../state/app_state.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

class PartnersScreen extends StatelessWidget {
  const PartnersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = isNarrow(context) ? 16.0 : 24.0;
    return PageFrame(
      title: 'Partnered with',
      body: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro(
              eyebrow: 'The room around the floor',
              title: 'Weeks, guilds, boards, houses.',
              dek: 'AOneGo9 sits next to the weeks and production rooms that already run this industry — so a booking here can walk into a real call sheet.',
            ),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, bc) {
              final cols = bc.maxWidth >= 960
                  ? 4
                  : bc.maxWidth >= 640
                      ? 2
                      : 1;
              const gap = 14.0;
              final w = (bc.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final p in seedPartners) SizedBox(width: w, child: _PartnerCard(partner: p)),
                ],
              );
            }),
            const SizedBox(height: 40),
            const _PartnerLead(),
          ],
        ),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final Partner partner;
  const _PartnerCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    return HoverFx(
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 230,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: T.card,
          border: Border.all(color: h ? T.gold.withValues(alpha: .4) : T.bdr),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: T.gr(partner.bg),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: T.bdr),
              ),
              child: Text(partner.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 14),
            Text(partner.name, style: F.fraunces(size: 18, weight: FontWeight.w700, color: T.cream, height: 1.15)),
            const SizedBox(height: 4),
            Text(partner.role.toUpperCase(),
                style: F.syne(size: 10, weight: FontWeight.w700, color: T.gold, letterSpacing: 1.4)),
            const SizedBox(height: 10),
            Expanded(
              child: Text(partner.blurb, style: F.syne(size: 12.5, weight: FontWeight.w400, color: T.mut, height: 1.55)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerLead extends StatefulWidget {
  const _PartnerLead();
  @override
  State<_PartnerLead> createState() => _PartnerLeadState();
}

class _PartnerLeadState extends State<_PartnerLead> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _org = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _org.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Container(
      padding: EdgeInsets.all(isNarrow(context) ? 18 : 24),
      decoration: BoxDecoration(
        color: T.surf,
        border: Border.all(color: T.bdr),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Partner with AOneGo9', style: F.fraunces(size: 24, weight: FontWeight.w700, color: T.cream)),
          const SizedBox(height: 6),
          Text(
            'Weeks, labels, tourism boards, houses. Tell us who you are — credentials first — and the desk will follow up.',
            style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.6),
          ),
          const SizedBox(height: 18),
          Field('Your name', Fi('Full name', controller: _name)),
          const SizedBox(height: 10),
          Field('Work email', Fi('you@house.com', keyboardType: TextInputType.emailAddress, controller: _email)),
          const SizedBox(height: 10),
          Field('Phone', Fi('+91 …', keyboardType: TextInputType.phone, controller: _phone)),
          const SizedBox(height: 10),
          Field('Organisation', Fi('Week, guild, studio, board', controller: _org)),
          const SizedBox(height: 10),
          Field('What you want to partner on', Fi('Casting week, venue circuit, campaign…', controller: _note, minLines: 3)),
          const SizedBox(height: 16),
          HoverFx(
            onTap: _busy
                ? null
                : () async {
                    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty || _org.text.trim().isEmpty) {
                      app.showToast('Credentials incomplete', 'Name, work email and organisation are required', '⚠️');
                      return;
                    }
                    setState(() => _busy = true);
                    await app.contributeNewsletter({
                      'kind': 'partner',
                      'author_name': _name.text.trim(),
                      'author_email': _email.text.trim(),
                      'author_phone': _phone.text.trim(),
                      'organisation': _org.text.trim(),
                      'body': _note.text.trim(),
                      'title': 'Partner inquiry — ${_org.text.trim()}',
                    });
                    if (!mounted) return;
                    setState(() => _busy = false);
                    _note.clear();
                  },
            builder: (h) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(color: T.gold, borderRadius: BorderRadius.circular(8)),
              child: Text(_busy ? 'Sending…' : 'Send partnership note →',
                  style: F.syne(size: 13, weight: FontWeight.w700, color: T.bg)),
            ),
          ),
        ],
      ),
    );
  }
}
