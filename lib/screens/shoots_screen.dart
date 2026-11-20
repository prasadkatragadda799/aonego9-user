import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/programs.dart';
import '../data/taxonomy.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/lead_capture.dart';
import '../widgets/program_kit.dart';
import 'campaigns_screen.dart' show CampaignCard, OfferCard;

/// Shoots — the two primary shoot categories (Artist Portfolio and Personal),
/// the crew a shoot needs, the roadmap the desk works to, and a structured
/// request form that collects everything a call sheet needs: type, crew,
/// dress code, brand collection, date and time zone.
class ShootsScreen extends StatelessWidget {
  const ShootsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pad = isNarrow(context) ? 16.0 : 24.0;
    final cat = shootCategories.firstWhere((c) => c.id == app.shootCategory, orElse: () => shootCategories.first);
    final campaigns = app.campaigns.where((c) => c.kind == cat.id || (cat.id == 'portfolio' && c.kind == 'brand')).take(3).toList();
    final offers = app.offers.take(2).toList();

    return PageFrame(
      title: 'Shoots',
      body: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 56),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const PageIntro(
            eyebrow: 'Portfolio & personal photography',
            motif: 'talent',
            title: 'Two ways to get in front of the camera.',
            dek: 'Artist portfolio shoots for models, actors and brands — or a personal shoot just for you. '
                'Tell us the look and the date; we bring the crew, the wardrobe and the schedule.',
          ),
          const SizedBox(height: 18),
          SegTabs(
            tabs: [for (final c in shootCategories) (c.id, c.title, c.icon)],
            active: cat.id,
            onChanged: app.setShootCategory,
          ),
          const SizedBox(height: 16),
          _CategoryCard(cat: cat),
          SectionTitle('Build your crew',
              dek: 'Every role is a live category on AOneGo9 — browse verified profiles in ${app.location}.'),
          AutoGrid(
            minItemWidth: 200,
            maxCols: 4,
            gap: 12,
            children: [for (final r in shootCrew) _CrewCard(role: r)],
          ),
          const SectionTitle('How a shoot runs', dek: 'The roadmap the AOneGo9 management team follows for every shoot.'),
          const _Roadmap(),
          SectionTitle('Request a ${cat.id == 'portfolio' ? 'portfolio' : 'personal'} shoot',
              dek: 'Two minutes. The desk replies with a crew, a quote and a call sheet.'),
          _ShootRequest(key: ValueKey(cat.id), cat: cat),
          SectionTitle(
            'Upcoming campaigns',
            dek: 'Register your interest city-wise and vote on what we shoot next.',
            action: 'All campaigns',
            onAction: () => app.openCampaigns(),
          ),
          if (campaigns.isEmpty)
            EmptyState(
              icon: Icons.campaign_outlined,
              title: 'No open campaigns right now',
              message: 'New portfolio and brand campaigns are announced here first. Turn on campaign updates to hear the moment one opens.',
              actionLabel: 'Notify me',
              onAction: () => app.setView('account'),
            )
          else
            AutoGrid(minItemWidth: 300, maxCols: 3, children: [for (final c in campaigns) CampaignCard(campaign: c)]),
          SectionTitle('Offers & coupons', action: 'All offers', onAction: () => app.openCampaigns('offers')),
          if (offers.isEmpty)
            EmptyState(
              icon: Icons.local_offer_outlined,
              title: 'No live offers at the moment',
              message: 'Coupons for shoots and artist services are posted here during campaigns.',
              actionLabel: 'See campaigns',
              onAction: () => app.openCampaigns(),
            )
          else
            AutoGrid(minItemWidth: 300, maxCols: 2, children: [for (final o in offers) OfferCard(offer: o)]),
          const SectionTitle('Need a hand?'),
          const _SupportRow(),
        ]),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ShootCategory cat;
  const _CategoryCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    final art = Container(
      width: narrow ? double.infinity : 180,
      height: narrow ? 110 : null,
      decoration: BoxDecoration(gradient: T.grPoster(cat.id == 'portfolio' ? 2 : 5)),
      alignment: Alignment.center,
      child: Text(cat.icon, style: TextStyle(fontSize: narrow ? 44 : 56)),
    );
    final copy = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(cat.title, style: F.fraunces(size: 21, weight: FontWeight.w700, color: T.cream)),
        const SizedBox(height: 6),
        Text(cat.tagline, style: F.syne(size: 13.5, weight: FontWeight.w400, color: T.mut, height: 1.55)),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final t in cat.types) Tag(t, color: T.text)]),
      ]),
    );
    return Container(
      decoration: BoxDecoration(color: T.card, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: narrow
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [art, copy])
          : IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [art, Expanded(child: copy)]),
            ),
    );
  }
}

class _CrewCard extends StatelessWidget {
  final CrewRole role;
  const _CrewCard({required this.role});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final accent = T.ac(role.catId);
    return Semantics(
      button: true,
      label: 'Browse ${role.label}',
      child: HoverFx(
        onTap: () => app.openResults(cat: role.catId),
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: h ? accent.withValues(alpha: .08) : T.card,
            border: Border.all(color: h ? accent : T.bdr),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: accent.withValues(alpha: .14), borderRadius: BorderRadius.circular(9)),
              child: Text(role.icon, style: const TextStyle(fontSize: 19)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(role.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: F.syne(size: 13, weight: FontWeight.w700, color: T.cream)),
                const SizedBox(height: 2),
                Text(catOf(role.catId)?.name ?? '', style: F.syne(size: 11, weight: FontWeight.w500, color: T.dim)),
              ]),
            ),
            Icon(Icons.arrow_forward_rounded, size: 16, color: h ? accent : T.faint),
          ]),
        ),
      ),
    );
  }
}

/// Roadmap — a horizontal stepper on wide screens, a vertical one on phones.
class _Roadmap extends StatelessWidget {
  const _Roadmap();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, bc) {
      final wide = bc.maxWidth >= 900;
      if (wide) {
        return PCard(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < shootRoadmap.length; i++)
              Expanded(child: _Step(i: i, step: shootRoadmap[i], last: i == shootRoadmap.length - 1, horizontal: true)),
          ]),
        );
      }
      return PCard(
        child: Column(children: [
          for (var i = 0; i < shootRoadmap.length; i++)
            _Step(i: i, step: shootRoadmap[i], last: i == shootRoadmap.length - 1, horizontal: false),
        ]),
      );
    });
  }
}

class _Step extends StatelessWidget {
  final int i;
  final RoadmapStep step;
  final bool last;
  final bool horizontal;
  const _Step({required this.i, required this.step, required this.last, required this.horizontal});

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: T.gold.withValues(alpha: .12), border: Border.all(color: T.gold), shape: BoxShape.circle),
      child: Text(step.icon, style: const TextStyle(fontSize: 16)),
    );
    final label = Text('STEP ${i + 1}', style: F.mono(size: 9.5, color: T.gold));
    final title = Text(step.title, style: F.syne(size: 13.5, weight: FontWeight.w800, color: T.cream));
    final detail = Text(step.detail, style: F.syne(size: 11.5, weight: FontWeight.w400, color: T.mut, height: 1.5));
    if (horizontal) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          dot,
          if (!last) Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 6), color: T.bdhi)),
        ]),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            label,
            const SizedBox(height: 3),
            title,
            const SizedBox(height: 4),
            detail,
          ]),
        ),
      ]);
    }
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Column(children: [
          dot,
          if (!last) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: T.bdhi)),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 16, top: 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              label,
              const SizedBox(height: 3),
              title,
              const SizedBox(height: 4),
              detail,
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ShootRequest extends StatefulWidget {
  final ShootCategory cat;
  const _ShootRequest({super.key, required this.cat});

  @override
  State<_ShootRequest> createState() => _ShootRequestState();
}

class _ShootRequestState extends State<_ShootRequest> {
  late String _type = widget.cat.types.first;
  final Set<String> _crew = {'Photographer', 'Makeup artist'};
  String _dress = dressCodes.first;
  String _tz = shootTimeZones.first;
  DateTime? _date;
  final _brand = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _brand.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _isBrand => _type.toLowerCase().contains('brand') || _type.toLowerCase().contains('campaign') || _type.toLowerCase().contains('lookbook');

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }

  String get _dateLabel {
    final d = _date;
    if (d == null) return 'Pick a date';
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return PCard(
      padding: EdgeInsets.all(isNarrow(context) ? 16 : 22),
      child: LeadCapture(
        kind: 'shoot_booking',
        submitLabel: 'Send shoot request',
        successTitle: 'Shoot request received',
        successBody: 'The management team will send a crew shortlist, a quote and a call sheet. '
            'Track replies under Account → Messages.',
        payload: () {
          if (_date == null) {
            context.read<AppState>().showToast('Pick a shoot date', 'A tentative date is enough — it can move later', '🗓️');
            return null;
          }
          return {
            'shoot_category': widget.cat.id,
            'shoot_type': _type,
            'crew': _crew.toList(),
            'dress_code': _dress,
            'date': _date!.toIso8601String().substring(0, 10),
            'time_zone': _tz,
            if (_brand.text.trim().isNotEmpty) 'brand_collection': _brand.text.trim(),
            'message': _notes.text.trim(),
          };
        },
        extra: [
          const Fl('Shoot type'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in widget.cat.types) PickChip(label: t, active: _type == t, onTap: () => setState(() => _type = t)),
          ]),
          const SizedBox(height: 4),
          const Fl('Crew needed'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in shootCrew)
              PickChip(
                label: r.label,
                icon: r.icon,
                active: _crew.contains(r.label),
                onTap: () => setState(() => _crew.contains(r.label) ? _crew.remove(r.label) : _crew.add(r.label)),
              ),
          ]),
          FieldPair(
            Field('Dress code', FiSelect(options: dressCodes, value: _dress, onChanged: (v) => setState(() => _dress = v ?? _dress))),
            Field('Time zone', FiSelect(options: shootTimeZones, value: _tz, onChanged: (v) => setState(() => _tz = v ?? _tz))),
          ),
          Field(
            'Shoot date',
            Semantics(
              button: true,
              label: 'Shoot date: $_dateLabel',
              child: HoverFx(
                onTap: _pickDate,
                builder: (h) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: T.surf,
                    border: Border.all(color: h ? T.gold : T.bdr),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(children: [
                    Icon(Icons.event_rounded, size: 16, color: T.dim),
                    const SizedBox(width: 8),
                    Text(_dateLabel, style: F.syne(size: 13, color: _date == null ? T.dim : T.text)),
                  ]),
                ),
              ),
            ),
          ),
          if (_isBrand)
            LabeledInput(
              label: 'Brand / collection',
              hint: 'Brand, designer or showroom collection being promoted',
              controller: _brand,
            ),
          LabeledInput(
            label: 'Anything else',
            hint: 'References, mood, location ideas, usage (social, print, campaign)…',
            controller: _notes,
            minLines: 3,
          ),
        ],
      ),
    );
  }
}

class _SupportRow extends StatelessWidget {
  const _SupportRow();

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final items = [
      (Icons.support_agent_rounded, 'Contact the management team', 'Questions about a shoot or campaign', () => app.openConnect('contact')),
      (Icons.confirmation_number_outlined, 'Raise a help-desk request', 'Tracked ticket with a reply in your account', () => app.setView('account')),
      (Icons.chat_bubble_outline_rounded, 'Chat & messages', 'Talk to your crew and the desk', () => app.setView('account')),
      (Icons.notifications_active_outlined, 'Get shoot updates', 'Notifications for your portfolio and campaigns', () => app.setView('account')),
    ];
    return AutoGrid(
      minItemWidth: 230,
      gap: 12,
      children: [
        for (final it in items)
          Semantics(
            button: true,
            label: it.$2,
            child: HoverFx(
              onTap: it.$4,
              builder: (h) => AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: T.card,
                  border: Border.all(color: h ? T.gold : T.bdr),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(it.$1, size: 20, color: T.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(it.$2, style: F.syne(size: 13, weight: FontWeight.w700, color: T.cream)),
                      const SizedBox(height: 3),
                      Text(it.$3, style: F.syne(size: 11.5, weight: FontWeight.w400, color: T.dim, height: 1.4)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
      ],
    );
  }
}
