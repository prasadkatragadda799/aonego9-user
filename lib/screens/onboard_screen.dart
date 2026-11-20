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

/// List on AOneGo9 — onboarding for every profile type the platform serves:
/// artists, celebrities and experts, vendors and service providers, brands
/// and sponsors, agencies, organisations and event organisers, show
/// organisers, production houses, modelling agencies, media partners,
/// schools and academies, and colleges and universities.
///
/// Each type says what its panel does (inventory, ticketing, student records,
/// fee management…) so a business knows what it is signing up for.
class OnboardScreen extends StatefulWidget {
  const OnboardScreen({super.key});

  @override
  State<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<OnboardScreen> {
  String _group = 'all';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pad = isNarrow(context) ? 16.0 : 24.0;
    final picked = app.onboardType;
    var types = _group == 'all' ? profileTypes : profileTypes.where((p) => p.group == _group).toList();
    if (picked != null) {
      // Bring the type the visitor came for to the front.
      types = [...types.where((t) => t.id == picked), ...types.where((t) => t.id != picked)];
    }

    return PageFrame(
      title: 'List on AOneGo9',
      body: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 56),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const PageIntro(
            eyebrow: 'Onboarding · free to start',
            motif: 'spaces',
            title: 'Grow, promote and manage — in one place.',
            dek: 'Artists, businesses, brands, organisations, media and institutions each get a profile built for '
                'what they do, and a panel to run it: inventory, tickets, registrations, student records and more.',
          ),
          const SizedBox(height: 14),
          const AutoGrid(minItemWidth: 220, gap: 12, children: [
            _Pillar('📈', 'Grow', 'A verified profile in front of clients searching your city, state and country.'),
            _Pillar('📣', 'Promote', 'Ads, campaigns, social media management and promotional displays.'),
            _Pillar('🧭', 'Manage', 'Inventory, bookings, tickets, registrations and records in your panel.'),
            _Pillar('🤖', 'AI-assisted', 'Event planning, notebooks and smart suggestions built in.'),
          ]),
          const SectionTitle('Choose your profile type', dek: 'Pick the one that fits best — you can add categories later.'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            PickChip(label: 'All', active: _group == 'all', onTap: () => setState(() => _group = 'all')),
            for (final g in profileTypeGroups.entries)
              PickChip(label: g.value, active: _group == g.key, onTap: () => setState(() => _group = g.key)),
          ]),
          const SizedBox(height: 16),
          AutoGrid(
            minItemWidth: 300,
            maxCols: 3,
            children: [for (final t in types) _TypeCard(type: t, highlighted: t.id == picked)],
          ),
          const SectionTitle('How onboarding works'),
          const AutoGrid(minItemWidth: 200, gap: 12, children: [
            _Num(1, 'Apply', 'Tell us who you are and what you offer — goods, services or both.'),
            _Num(2, 'Verify', 'The verification desk checks your documents, work and links.'),
            _Num(3, 'Set up your panel', 'Add inventory, packages, events, courses or your roster.'),
            _Num(4, 'Go live', 'Your profile is listed, promoted and notified to the right audience.'),
          ]),
          const SizedBox(height: 22),
          PCard(
            child: Wrap(
              spacing: 14,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Already listed?', style: F.fraunces(size: 18, weight: FontWeight.w700, color: T.cream)),
                    const SizedBox(height: 4),
                    Text('Manage your inventory, bookings, events and subscription from the business panel.',
                        style: F.syne(size: 13, color: T.mut, height: 1.5)),
                  ]),
                ),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  PrimaryBtn('Open business panel', icon: Icons.storefront_outlined, onTap: () => app.setView('vendor-auth')),
                  OutlineBtn('See plans', icon: Icons.workspace_premium_outlined, onTap: () => app.setView('subscription')),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _Pillar extends StatelessWidget {
  final String icon;
  final String title;
  final String body;
  const _Pillar(this.icon, this.title, this.body);

  @override
  Widget build(BuildContext context) => PCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(title, style: F.syne(size: 14, weight: FontWeight.w800, color: T.cream)),
          const SizedBox(height: 4),
          Text(body, style: F.syne(size: 12, color: T.mut, height: 1.5)),
        ]),
      );
}

class _Num extends StatelessWidget {
  final int n;
  final String title;
  final String body;
  const _Num(this.n, this.title, this.body);

  @override
  Widget build(BuildContext context) => PCard(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: T.gold, shape: BoxShape.circle),
            child: Text('$n', style: F.syne(size: 13, weight: FontWeight.w800, color: T.onAccent(T.gold))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: F.syne(size: 13.5, weight: FontWeight.w800, color: T.cream)),
              const SizedBox(height: 3),
              Text(body, style: F.syne(size: 12, color: T.mut, height: 1.45)),
            ]),
          ),
        ]),
      );
}

class _TypeCard extends StatelessWidget {
  final ProfileType type;
  final bool highlighted;
  const _TypeCard({required this.type, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final cats = type.catIds.map(catOf).whereType<Cat>().toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: T.card,
        border: Border.all(color: highlighted ? T.gold : T.bdr, width: highlighted ? 1.5 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: T.gold.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)),
            child: Text(type.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(type.title, style: F.syne(size: 14.5, weight: FontWeight.w800, color: T.cream, height: 1.3))),
        ]),
        const SizedBox(height: 10),
        Text(type.who, style: F.syne(size: 12.5, color: T.mut, height: 1.5)),
        const SizedBox(height: 12),
        Text('YOUR PANEL', style: F.syne(size: 9.5, weight: FontWeight.w800, color: T.dim, letterSpacing: 1.4)),
        const SizedBox(height: 6),
        for (final f in type.panel)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.check_circle_rounded, size: 14, color: T.grn)),
              const SizedBox(width: 7),
              Expanded(child: Text(f, style: F.syne(size: 12.5, weight: FontWeight.w500, color: T.text, height: 1.4))),
            ]),
          ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: PrimaryBtn('Start onboarding', expand: true, onTap: () => showOnboardForm(context, type))),
          if (cats.isNotEmpty) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'See ${cats.first.name} on AOneGo9',
              child: OutlineBtn('Examples', onTap: () => app.openResults(cat: cats.first.id)),
            ),
          ],
        ]),
      ]),
    );
  }
}

/// The onboarding application for one profile type.
void showOnboardForm(BuildContext context, ProfileType type) {
  final cats = type.catIds.map(catOf).whereType<Cat>().map((c) => c.name).toList();
  showProgramDialog<void>(
    context,
    eyebrow: 'Onboarding',
    title: type.title,
    sub: type.who,
    body: (ctx) => _OnboardForm(type: type, cats: cats),
  );
}

class _OnboardForm extends StatefulWidget {
  final ProfileType type;
  final List<String> cats;
  const _OnboardForm({required this.type, required this.cats});

  @override
  State<_OnboardForm> createState() => _OnboardFormState();
}

class _OnboardFormState extends State<_OnboardForm> {
  final _org = TextEditingController();
  final _link = TextEditingController();
  final _about = TextEditingController();
  late String _cat = widget.cats.isEmpty ? '' : widget.cats.first;
  String _offers = 'Services';
  String _reach = 'City';
  String? _orgError;

  bool get _isPerson => widget.type.group == 'creators';

  @override
  void dispose() {
    for (final c in [_org, _link, _about]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LeadCapture(
      kind: 'onboard_${widget.type.id}',
      submitLabel: 'Submit application',
      successTitle: 'Application received',
      successBody: 'The verification desk reviews applications within two working days and will email your panel access.',
      payload: () {
        if (!_isPerson && _org.text.trim().length < 2) {
          setState(() => _orgError = 'Enter the business or organisation name');
          return null;
        }
        setState(() => _orgError = null);
        return {
          'profile_type': widget.type.id,
          'organisation': _org.text.trim(),
          if (_cat.isNotEmpty) 'category': _cat,
          if (!_isPerson) 'offers': _offers,
          'reach': _reach,
          'link': _link.text.trim(),
          'message': _about.text.trim(),
        };
      },
      extra: [
        LabeledInput(
          label: _isPerson ? 'Stage / professional name' : 'Business or organisation name',
          hint: _isPerson ? 'Optional' : 'Registered or brand name',
          controller: _org,
          error: _orgError,
          required: !_isPerson,
        ),
        if (widget.cats.length > 1)
          Field('Category', FiSelect(options: widget.cats, value: _cat, onChanged: (v) => setState(() => _cat = v ?? _cat))),
        if (!_isPerson)
          FieldPair(
            Field('We offer',
                FiSelect(options: const ['Services', 'Goods / products', 'Both'], value: _offers, onChanged: (v) => setState(() => _offers = v ?? _offers))),
            Field('We operate across',
                FiSelect(options: const ['City', 'State', 'All India', 'International'], value: _reach, onChanged: (v) => setState(() => _reach = v ?? _reach))),
          ),
        LabeledInput(
          label: _isPerson ? 'Instagram or portfolio link' : 'Website or Instagram',
          hint: '@handle or https://…',
          controller: _link,
        ),
        LabeledInput(
          label: 'About',
          hint: _isPerson ? 'Your work, experience and what you want to be booked for' : 'What you sell or offer, and to whom',
          controller: _about,
          minLines: 3,
        ),
      ],
    );
  }
}
