import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/geo.dart';
import '../data/programs.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/lead_capture.dart';
import '../widgets/program_kit.dart';

/// Campaigns & offers — upcoming AOneGo9 campaigns with city-wise interest
/// registration, voting, participant counts and a report, plus the offers
/// and coupons that promote them.
class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  String _kind = 'all';
  bool _nearMe = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pad = isNarrow(context) ? 16.0 : 24.0;
    final onOffers = app.campaignsTab == 'offers';

    var campaigns = app.campaigns;
    if (_kind != 'all') campaigns = campaigns.where((c) => c.kind == _kind).toList();
    if (_nearMe) {
      campaigns = campaigns
          .where((c) => c.city.isEmpty || GeoIndex.matches(selected: app.location, listingCity: c.city))
          .toList();
    }

    return PageFrame(
      title: 'Campaigns & offers',
      body: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 56),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const PageIntro(
            eyebrow: 'Upcoming campaigns',
            motif: 'fashion',
            title: 'Vote on what we shoot next.',
            dek: 'Register your interest in an upcoming portfolio, personal or brand campaign in your city, '
                'vote on themes and finalists, and use the coupons that come with them.',
          ),
          const SizedBox(height: 18),
          SegTabs(
            tabs: const [
              ('campaigns', 'Campaigns', '📣'),
              ('offers', 'Offers & coupons', '🎟️'),
            ],
            active: app.campaignsTab,
            onChanged: app.setCampaignsTab,
          ),
          const SizedBox(height: 18),
          if (onOffers) ..._offers(app) else ..._campaigns(app, campaigns),
        ]),
      ),
    );
  }

  List<Widget> _campaigns(AppState app, List<Campaign> list) {
    final loading = app.programsLoading && app.campaigns.isEmpty;
    return [
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        for (final k in const [('all', 'All'), ('portfolio', 'Artist portfolio'), ('personal', 'Personal'), ('brand', 'Brand promotion')])
          PickChip(label: k.$2, active: _kind == k.$1, onTap: () => setState(() => _kind = k.$1)),
        Container(width: 1, height: 22, color: T.bdr, margin: const EdgeInsets.symmetric(horizontal: 4)),
        PickChip(
          label: 'Near ${app.location}',
          icon: '📍',
          active: _nearMe,
          onTap: () => setState(() => _nearMe = !_nearMe),
        ),
      ]),
      const SizedBox(height: 16),
      if (loading)
        const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
      else if (list.isEmpty)
        EmptyState(
          icon: Icons.campaign_outlined,
          title: app.campaigns.isEmpty ? 'No campaigns announced yet' : 'Nothing matches these filters',
          message: app.campaigns.isEmpty
              ? 'Upcoming portfolio, personal and brand campaigns are announced here first — with voting and city-wise sign-ups.'
              : 'Try another campaign type or turn off the location filter.',
          actionLabel: app.campaigns.isEmpty ? 'Book a shoot instead' : 'Clear filters',
          onAction: app.campaigns.isEmpty
              ? () => app.openShoots()
              : () => setState(() {
                    _kind = 'all';
                    _nearMe = false;
                  }),
        )
      else ...[
        AutoGrid(minItemWidth: 300, maxCols: 3, children: [for (final c in list) CampaignCard(campaign: c)]),
        _CityReport(campaigns: app.campaigns),
      ],
      const SectionTitle('Want to run a campaign?',
          dek: 'Brands, designers and organisations can run a campaign on AOneGo9 — we handle sign-ups, voting and the shoot.'),
      Wrap(spacing: 10, runSpacing: 10, children: [
        PrimaryBtn('Talk to the desk', icon: Icons.campaign_outlined, onTap: () => app.setView('advertise')),
        OutlineBtn('List your brand', icon: Icons.storefront_outlined, onTap: () => app.openOnboard('brand')),
      ]),
    ];
  }

  List<Widget> _offers(AppState app) {
    final loading = app.programsLoading && app.offers.isEmpty;
    return [
      if (loading)
        const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
      else if (app.offers.isEmpty)
        EmptyState(
          icon: Icons.local_offer_outlined,
          title: 'No live offers right now',
          message: 'Coupons for portfolio shoots, campaigns and artist services appear here. Turn on offer notifications so you never miss one.',
          actionLabel: 'Turn on offer alerts',
          onAction: () => app.setView('account'),
        )
      else
        AutoGrid(minItemWidth: 300, maxCols: 3, children: [for (final o in app.offers) OfferCard(offer: o)]),
      const SizedBox(height: 18),
      PCard(
        child: Row(children: [
          const Text('💡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Quote the coupon code in your inquiry or shoot request — the desk applies it to the quote.',
              style: F.syne(size: 13, weight: FontWeight.w500, color: T.mut, height: 1.5),
            ),
          ),
        ]),
      ),
    ];
  }
}

/// A campaign — art, status, counts and the three actions.
class CampaignCard extends StatelessWidget {
  final Campaign campaign;
  const CampaignCard({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final c = campaign;
    final voted = app.myVote(c.id);
    final interested = app.hasRegisteredInterest(c.id);
    final kindLabel = switch (c.kind) { 'personal' => 'Personal shoot', 'brand' => 'Brand promotion', _ => 'Artist portfolio' };
    final meta = [c.city, c.date].where((s) => s.isNotEmpty).join('  ·  ');

    return Container(
      decoration: BoxDecoration(color: T.card, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AspectRatio(
          aspectRatio: 16 / 8,
          child: Stack(fit: StackFit.expand, children: [
            if (c.imageUrl.isNotEmpty)
              Image.network(c.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => GradientArt(bgIndex: c.bg, emoji: c.emoji, emojiSize: 40))
            else
              GradientArt(bgIndex: c.bg, emoji: c.emoji, emojiSize: 40),
            Positioned(
              left: 10,
              top: 10,
              child: Wrap(spacing: 6, children: [
                Tag(kindLabel, color: T.gold, solid: true),
                if (c.isClosed) Tag('Closed', color: T.dim, solid: true) else if (c.status == 'voting') Tag('Voting', color: T.grn, solid: true),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.title, style: F.fraunces(size: 17, weight: FontWeight.w700, color: T.cream, height: 1.25)),
            if (c.brand.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('with ${c.brand}', style: F.syne(size: 12, weight: FontWeight.w600, color: T.gold)),
            ],
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(meta, style: F.mono(size: 10.5, color: T.dim)),
            ],
            if (c.blurb.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(c.blurb, maxLines: 3, overflow: TextOverflow.ellipsis, style: F.syne(size: 12.5, color: T.mut, height: 1.5)),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: StatTile('${c.participants + (interested ? 1 : 0)}', 'Participants')),
              const SizedBox(width: 8),
              Expanded(child: StatTile('${c.votes + (voted != null ? 1 : 0)}', 'Votes')),
            ]),
            if (c.deadline.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Sign-ups close ${c.deadline}', style: F.syne(size: 11, weight: FontWeight.w600, color: T.redText)),
            ],
            const SizedBox(height: 14),
            if (!c.isClosed)
              Row(children: [
                Expanded(
                  child: interested
                      ? OutlineBtn('Registered ✓', expand: true, onTap: () => _report(context, c))
                      : PrimaryBtn('I\'m interested', expand: true, onTap: () => _interest(context, c)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlineBtn(voted != null ? 'Voted' : 'Vote',
                      icon: voted != null ? Icons.how_to_vote_rounded : Icons.how_to_vote_outlined,
                      expand: true,
                      onTap: voted != null ? () => _report(context, c) : () => _vote(context, c)),
                ),
              ]),
            const SizedBox(height: 8),
            Center(
              child: HoverFx(
                onTap: () => _report(context, c),
                builder: (h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('View report →', style: F.syne(size: 12, weight: FontWeight.w700, color: h ? T.goldLight : T.gold)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  void _interest(BuildContext context, Campaign c) {
    final app = context.read<AppState>();
    String role = c.kind == 'personal' ? 'Customer' : 'Artist / model';
    showProgramDialog<void>(
      context,
      eyebrow: 'Register interest',
      title: c.title,
      sub: 'Tell us where you are — city-wise interest decides where the campaign shoots.',
      body: (ctx) => StatefulBuilder(
        builder: (ctx, set) => LeadCapture(
          kind: 'campaign_interest',
          submitLabel: 'Register my interest',
          successTitle: 'You\'re on the list',
          successBody: 'We\'ll message you before sign-ups open in your city.',
          payload: () => {'role': role},
          submit: (body) => app.registerCampaignInterest(c, body),
          extra: [
            Field(
              'I am a',
              FiSelect(
                options: const ['Artist / model', 'Customer', 'Photographer / crew', 'Brand / sponsor'],
                value: role,
                onChanged: (v) => set(() => role = v ?? role),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _vote(BuildContext context, Campaign c) {
    final app = context.read<AppState>();
    if (c.options.isEmpty) {
      app.voteCampaign(c, '');
      return;
    }
    showProgramDialog<void>(
      context,
      eyebrow: 'Cast your vote',
      title: c.title,
      sub: 'One vote per person. Results are published in the campaign report.',
      body: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final o in c.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlineBtn(o, expand: true, icon: Icons.how_to_vote_outlined, onTap: () async {
              Navigator.of(ctx).maybePop();
              await app.voteCampaign(c, o);
            }),
          ),
      ]),
    );
  }

  void _report(BuildContext context, Campaign c) {
    showProgramDialog<void>(
      context,
      eyebrow: 'Campaign report',
      title: c.title,
      body: (ctx) => _CampaignReport(campaign: c),
    );
  }
}

class _CampaignReport extends StatelessWidget {
  final Campaign campaign;
  const _CampaignReport({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    final cities = c.cityInterest.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final opts = c.optionVotes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final cityMax = cities.isEmpty ? 0 : cities.first.value;
    final optMax = opts.isEmpty ? 0 : opts.first.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: StatTile('${c.participants}', 'Participants')),
        const SizedBox(width: 8),
        Expanded(child: StatTile('${c.votes}', 'Votes')),
        const SizedBox(width: 8),
        Expanded(child: StatTile('${c.cityInterest.length}', 'Cities')),
      ]),
      const SizedBox(height: 18),
      const BlkHeader('Interest by city'),
      if (cities.isEmpty)
        Text('No city-wise sign-ups yet.', style: F.syne(size: 12.5, color: T.dim))
      else
        for (final e in cities.take(10)) BarRow(label: e.key, value: e.value, max: cityMax),
      if (opts.isNotEmpty) ...[
        const SizedBox(height: 14),
        const BlkHeader('Votes by option'),
        for (final e in opts) BarRow(label: e.key, value: e.value, max: optMax, color: T.grn),
      ],
    ]);
  }
}

/// Aggregate city-wise interest across all campaigns — the R&D view.
class _CityReport extends StatelessWidget {
  final List<Campaign> campaigns;
  const _CityReport({required this.campaigns});

  @override
  Widget build(BuildContext context) {
    final totals = <String, int>{};
    for (final c in campaigns) {
      c.cityInterest.forEach((k, v) => totals[k] = (totals[k] ?? 0) + v);
    }
    if (totals.isEmpty) return const SizedBox.shrink();
    final rows = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final max = rows.first.value;
    final participants = campaigns.fold<int>(0, (a, c) => a + c.participants);
    final votes = campaigns.fold<int>(0, (a, c) => a + c.votes);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionTitle('City-wise interest', dek: 'Where artists and customers want the next shoots — across every open campaign.'),
      PCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: StatTile('${campaigns.length}', 'Campaigns')),
            const SizedBox(width: 8),
            Expanded(child: StatTile('$participants', 'Participants')),
            const SizedBox(width: 8),
            Expanded(child: StatTile('$votes', 'Votes')),
          ]),
          const SizedBox(height: 16),
          for (final e in rows.take(10)) BarRow(label: e.key, value: e.value, max: max),
        ]),
      ),
    ]);
  }
}

/// An offer with a copyable coupon code.
class OfferCard extends StatelessWidget {
  final Offer offer;
  const OfferCard({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final o = offer;
    return Container(
      decoration: BoxDecoration(color: T.card, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            width: 92,
            decoration: BoxDecoration(gradient: T.grPoster(o.bg)),
            padding: const EdgeInsets.all(10),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(o.emoji, style: const TextStyle(fontSize: 26)),
              if (o.discount.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(o.discount,
                    textAlign: TextAlign.center,
                    style: F.fraunces(size: 15, weight: FontWeight.w800, color: T.posterInk, height: 1.1)),
              ],
            ]),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.title, style: F.syne(size: 14, weight: FontWeight.w800, color: T.cream)),
                if (o.blurb.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(o.blurb, maxLines: 3, overflow: TextOverflow.ellipsis, style: F.syne(size: 12, color: T.mut, height: 1.45)),
                ],
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  if (o.appliesTo.isNotEmpty) Tag(o.appliesTo, color: T.text),
                  if (o.validTill.isNotEmpty) Tag('Till ${o.validTill}', color: T.redText),
                ]),
                if (o.code.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _CodeBox(code: o.code),
                ],
                if (o.terms.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(o.terms, style: F.syne(size: 10.5, color: T.dim, height: 1.4)),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  final String code;
  const _CodeBox({required this.code});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Semantics(
      button: true,
      label: 'Copy coupon code $code',
      child: HoverFx(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: code));
          app.showToast('Code copied', '$code — quote it in your inquiry', '🎟️');
        },
        builder: (h) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: T.gold.withValues(alpha: h ? .16 : .08),
            border: Border.all(color: T.gold.withValues(alpha: .55)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: Text(code, overflow: TextOverflow.ellipsis, style: F.mono(size: 12.5, color: T.gold))),
            const SizedBox(width: 8),
            Icon(Icons.copy_rounded, size: 14, color: T.gold),
          ]),
        ),
      ),
    );
  }
}
