import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/directory.dart';
import '../services/link_service.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/logo_mark.dart';

/// Partners — two logo walls, as the brief splits them:
///   · "our academic partners show to logo display"
///   · "our top brand partners show to logo display, types of categories
///      brand division"
///
/// The page used to be one flat grid of emoji tiles with no logos, no tiers
/// and no brand divisions. Academic partners now have their own wall, and the
/// brand wall groups by division with a filter across the top.
class PartnersScreen extends StatefulWidget {
  const PartnersScreen({super.key});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  String _division = 'All';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pad = isNarrow(context) ? 16.0 : 24.0;
    final academic = app.academicPartners;
    final brands = app.brandPartners;

    // Only offer divisions that actually have a partner behind them.
    final presentDivisions = <String>{for (final b in brands) b.division};
    final divisionChips = [
      'All',
      ...brandDivisions.where(presentDivisions.contains),
      ...presentDivisions.where((d) => !brandDivisions.contains(d)),
    ];
    final shownBrands =
        _division == 'All' ? brands : brands.where((b) => b.division == _division).toList();

    return PageFrame(
      title: 'Partners',
      maxWidth: 1180,
      body: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro(
              eyebrow: 'The room around the floor',
              title: 'Weeks, guilds, boards, houses, campuses.',
              dek: 'AOneGo9 sits next to the weeks, brands and institutions that already run this industry — '
                  'so a booking here can walk into a real call sheet.',
            ),
            const SizedBox(height: 30),

            // ── Brand partners ──
            _WallHeader(
              eyebrow: 'Top brand partners',
              title: 'Brands that book here',
              count: brands.length,
            ),
            const SizedBox(height: 14),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final d in divisionChips)
                _DivChip(
                  label: d,
                  active: _division == d,
                  onTap: () => setState(() => _division = d),
                ),
            ]),
            const SizedBox(height: 16),
            _LogoWall(partners: shownBrands, showDivision: _division == 'All'),

            const SizedBox(height: 44),

            // ── Academic partners ──
            _WallHeader(
              eyebrow: 'Our academic partners',
              title: 'Campuses feeding the pipeline',
              count: academic.length,
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text(
                'Schools, colleges, universities and academies whose graduating cohorts come onto the '
                'floor verified, with a portfolio the desk has already reviewed.',
                style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.65),
              ),
            ),
            const SizedBox(height: 18),
            _LogoWall(partners: academic, showDivision: true),

            const SizedBox(height: 44),
            const _PartnerLead(),
          ],
        ),
      ),
    );
  }
}

class _WallHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final int count;
  const _WallHeader({required this.eyebrow, required this.title, required this.count});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 16, height: 1.5, color: T.gold),
            const SizedBox(width: 9),
            Text(eyebrow.toUpperCase(),
                style: F.syne(size: 10, weight: FontWeight.w700, color: T.gold, letterSpacing: 2.2)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: T.gold.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('$count', style: F.mono(size: 10, color: T.gold)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Container(height: 1, color: T.bdr)),
          ]),
          const SizedBox(height: 10),
          Text(title,
              style: F.fraunces(size: 26, weight: FontWeight.w700, color: T.cream, letterSpacing: -0.6)),
        ],
      );
}

class _LogoWall extends StatelessWidget {
  final List<LogoPartner> partners;
  final bool showDivision;
  const _LogoWall({required this.partners, required this.showDivision});

  @override
  Widget build(BuildContext context) {
    if (partners.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Text('No partners published in this division yet.',
            style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut)),
      );
    }
    return LayoutBuilder(builder: (context, bc) {
      final cols = bc.maxWidth >= 1000 ? 4 : (bc.maxWidth >= 720 ? 3 : (bc.maxWidth >= 440 ? 2 : 1));
      const gap = 13.0;
      final w = (bc.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final p in partners)
          SizedBox(width: w, child: _PartnerCard(partner: p, showDivision: showDivision)),
      ]);
    });
  }
}

class _PartnerCard extends StatelessWidget {
  final LogoPartner partner;
  final bool showDivision;
  const _PartnerCard({required this.partner, required this.showDivision});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final hasSite = partner.website.isNotEmpty;
    return HoverFx(
      onTap: hasSite
          ? () async {
              final ok = await LinkService.open(partner.website);
              if (!ok) app.showToast('Could not open', partner.website, '⚠️');
            }
          : null,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        // The min-height exists to keep a multi-column grid on one baseline.
        // In a single column it only adds dead space under short taglines.
        constraints: BoxConstraints(minHeight: isNarrow(context) ? 0 : 216),
        decoration: BoxDecoration(
          color: T.card,
          border: Border.all(color: h ? T.gold.withValues(alpha: .45) : T.bdr),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          LogoMark(name: partner.name, logoUrl: partner.logoUrl, size: 54, bg: partner.bg),
          const SizedBox(height: 14),
          Text(partner.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: F.fraunces(size: 17, weight: FontWeight.w700, color: T.cream, height: 1.18)),
          if (showDivision && partner.division.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(partner.division.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: F.syne(size: 9.5, weight: FontWeight.w700, color: T.gold, letterSpacing: 1.3)),
          ],
          const SizedBox(height: 9),
          Text(partner.tagline,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: F.syne(size: 12, weight: FontWeight.w400, color: T.mut, height: 1.55)),
          const Spacer(),
          const SizedBox(height: 10),
          Row(children: [
            if (partner.city.isNotEmpty)
              Expanded(child: Text('📍 ${partner.city}', style: F.mono(size: 10, color: T.dim))),
            if (hasSite)
              Icon(Icons.north_east_rounded, size: 13, color: h ? T.gold : T.faint),
          ]),
        ]),
      ),
    );
  }
}

class _DivChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _DivChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? T.gold.withValues(alpha: .14) : Colors.transparent,
            border: Border.all(color: active ? T.gold : (h ? T.bdhi : T.bdr)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: F.syne(
                  size: 11.5,
                  weight: FontWeight.w700,
                  color: active ? T.gold : (h ? T.text : T.mut))),
        ),
      );
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
  String _tier = 'Brand partner';
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _org, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Container(
      padding: EdgeInsets.all(isNarrow(context) ? 18 : 26),
      decoration: BoxDecoration(
        color: T.surf,
        border: Border.all(color: _sent ? T.grn.withValues(alpha: .35) : T.bdr),
        borderRadius: BorderRadius.circular(14),
      ),
      child: _sent
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Partnership note received',
                  style: F.fraunces(size: 22, weight: FontWeight.w700, color: T.cream)),
              const SizedBox(height: 8),
              Text('The partnerships desk verifies credentials before anything is announced. '
                  'You will hear back on the email you gave.',
                  style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.65)),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Partner with AOneGo9', style: F.fraunces(size: 24, weight: FontWeight.w700, color: T.cream)),
              const SizedBox(height: 6),
              Text(
                'Weeks, labels, tourism boards, houses, campuses. Tell us who you are — credentials first — '
                'and the desk will follow up.',
                style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.6),
              ),
              const SizedBox(height: 18),
              Field('Partnership type',
                  FiSelect(
                    options: const ['Brand partner', 'Academic partner', 'Industry body / guild', 'Media partner'],
                    value: _tier,
                    onChanged: (v) => _tier = v ?? _tier,
                  )),
              const SizedBox(height: 10),
              Field('Your name', Fi('Full name', controller: _name)),
              const SizedBox(height: 10),
              Field('Work email', Fi('you@house.com', keyboardType: TextInputType.emailAddress, controller: _email)),
              const SizedBox(height: 10),
              Field('Phone', Fi('+91 …', keyboardType: TextInputType.phone, controller: _phone)),
              const SizedBox(height: 10),
              Field('Organisation', Fi('Week, guild, studio, board, campus', controller: _org)),
              const SizedBox(height: 10),
              Field('What you want to partner on',
                  Fi('Casting week, venue circuit, campaign, campus intake…', controller: _note, minLines: 3)),
              const SizedBox(height: 16),
              HoverFx(
                onTap: _busy
                    ? null
                    : () async {
                        if (_name.text.trim().isEmpty ||
                            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(_email.text.trim()) ||
                            _org.text.trim().isEmpty) {
                          app.showToast('Credentials incomplete',
                              'Name, a valid work email and organisation are required', '⚠️');
                          return;
                        }
                        setState(() => _busy = true);
                        final ok = await app.submitLead('partner', {
                          'tier': _tier,
                          'name': _name.text.trim(),
                          'email': _email.text.trim(),
                          'phone': _phone.text.trim(),
                          'organisation': _org.text.trim(),
                          'message': _note.text.trim(),
                        });
                        if (!mounted) return;
                        setState(() {
                          _busy = false;
                          _sent = ok;
                        });
                        if (!ok) {
                          app.showToast('Could not send', 'Check your connection and try again', '⚠️');
                        }
                      },
                builder: (h) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: _busy ? T.goldDark : (h ? T.goldLight : T.gold),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_busy ? 'Sending…' : 'Send partnership note →',
                      style: F.syne(size: 13, weight: FontWeight.w700, color: T.bg)),
                ),
              ),
            ]),
    );
  }
}
