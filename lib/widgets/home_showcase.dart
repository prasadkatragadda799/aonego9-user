import 'dart:async';

import 'package:flutter/material.dart';
import '../data/directory.dart';
import '../data/taxonomy.dart';
import '../screens/events_screen.dart' show showEventBooking;
import '../screens/sessions_screen.dart' show showSessionRegister;
import '../services/link_service.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'ad_slot.dart' show AdStill, AdVideo, openAdCreative;
import 'common.dart';
import 'division_fx.dart';
import 'home_sections.dart' show HomeHeading;
import 'logo_mark.dart';

/// ─────────────────────────────────────────────────────────────────
/// HOME SHOWCASE — the blocks the client's second home sketch adds,
/// each slotted in among the existing sections rather than replacing them:
///
///   [AdvertiseBanner]   "Advertise your business" — the top box
///   [PartnerLogoStrip]  brand & partner logos, sliding; a tap opens the site
///   [EventPosterShow]   posters & video — live events, fashion walks,
///                       workshops — sliding
///   [IndustryExperts]   celebrities, actors, models — promoted profiles
///                       first, then the best-rated talent; video plays,
///                       DP and name on every card
///
/// Every block has an honest empty state that sells the slot instead of
/// inventing content: "your brand here", "your profile here".
/// ─────────────────────────────────────────────────────────────────

double _pad(BuildContext c) => isNarrow(c) ? 16.0 : 20.0;

/// ── Advertise your business ──────────────────────────────────────
class AdvertiseBanner extends StatelessWidget {
  final AppState app;
  const AdvertiseBanner({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(_pad(context), 14, _pad(context), 0),
      child: HoverFx(
        onTap: () => app.setView('advertise'),
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A0C12), T.maroon, Color(0xFF6B2A0A)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: h ? T.marigold : Colors.transparent, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            Positioned.fill(
              child: DivisionFx(divisionId: 'crew', accent: T.marigold, intensity: h ? 1.9 : 1.2, fadeToward: Alignment.centerLeft),
            ),
            if (!narrow)
              Positioned(
                right: 28,
                top: 0,
                bottom: 0,
                child: IgnorePointer(child: Center(child: _AdStack(lifted: h))),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(narrow ? 18 : 26, narrow ? 18 : 24, narrow ? 18 : 300, narrow ? 18 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('AONEGO9  ·  ADVERTISE',
                      style: F.syne(size: 10.5, weight: FontWeight.w800, color: T.marigold, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text('Advertise your business',
                      style: F.fraunces(size: narrow ? 22 : 28, weight: FontWeight.w700, color: T.posterInk, height: 1.15)),
                  const SizedBox(height: 6),
                  Text('Photo & video ads, profile promotion and Instagram campaigns — shot and run by our team.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: F.syne(size: 13, weight: FontWeight.w400, color: T.posterInkMuted, height: 1.5)),
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    for (final c in const ['📸 Photo ads', '🎬 Video ads', '⭐ Promote profile'])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .08),
                          border: Border.all(color: Colors.white.withValues(alpha: .18)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(c, style: F.syne(size: 11.5, weight: FontWeight.w600, color: T.posterInk)),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: h ? const Color(0xFFFFB84A) : T.marigold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Get started →',
                          style: F.syne(size: 12.5, weight: FontWeight.w800, color: const Color(0xFF2A1404))),
                    ),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Three fanned "ad" cards — what the advertiser is buying, drawn rather
/// than described.
class _AdStack extends StatelessWidget {
  final bool lifted;
  const _AdStack({required this.lifted});

  Widget _card(String emoji, String label, int bg) => Container(
        width: 92,
        height: 128,
        decoration: BoxDecoration(
          gradient: T.grPoster(bg),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .25)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 8),
          Text(label, style: F.syne(size: 10, weight: FontWeight.w800, color: T.marigold, letterSpacing: 1.2)),
        ]),
      );

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 240,
        height: 170,
        child: Stack(alignment: Alignment.center, children: [
          AnimatedRotation(
            turns: lifted ? -.045 : -.03,
            duration: const Duration(milliseconds: 260),
            child: Transform.translate(offset: Offset(lifted ? -76 : -62, 8), child: _card('📸', 'PHOTO', 3)),
          ),
          AnimatedRotation(
            turns: lifted ? .045 : .03,
            duration: const Duration(milliseconds: 260),
            child: Transform.translate(offset: Offset(lifted ? 76 : 62, 8), child: _card('⭐', 'PROFILE', 5)),
          ),
          AnimatedScale(
            scale: lifted ? 1.06 : 1,
            duration: const Duration(milliseconds: 260),
            child: _card('🎬', 'VIDEO', 1),
          ),
        ]),
      );
}

/// ── Auto-sliding rail ────────────────────────────────────────────
/// A horizontal row that advances on its own, loops, and holds still under
/// a cursor or a finger (and for visitors who asked the OS for less motion).
/// When everything already fits on screen it is just a still row.
class _AutoRail extends StatefulWidget {
  final int count;
  final double itemWidth;
  final double height;
  final Duration every;
  final Widget Function(BuildContext, int) builder;
  const _AutoRail({
    required this.count,
    required this.itemWidth,
    required this.height,
    required this.builder,
    this.every = const Duration(milliseconds: 3200),
  });

  @override
  State<_AutoRail> createState() => _AutoRailState();
}

class _AutoRailState extends State<_AutoRail> {
  static const _loopBase = 10000;
  static const _gap = 12.0;
  PageController? _pc;
  double? _fraction;
  Timer? _timer;
  bool _held = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.every, (_) {
      final pc = _pc;
      if (_held || pc == null || !pc.hasClients || !mounted) return;
      if (MediaQuery.of(context).disableAnimations) return;
      pc.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, bc) {
        final pad = _pad(context);
        final slot = widget.itemWidth + _gap;
        final fits = slot * widget.count - _gap <= bc.maxWidth - pad * 2;
        if (fits) {
          return SizedBox(
            height: widget.height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: pad),
              itemCount: widget.count,
              separatorBuilder: (_, __) => const SizedBox(width: _gap),
              itemBuilder: (c, i) => SizedBox(width: widget.itemWidth, child: widget.builder(c, i)),
            ),
          );
        }
        final fraction = (slot / (bc.maxWidth - pad)).clamp(.1, 1.0);
        if (_pc == null || _fraction != fraction) {
          final at = _pc?.hasClients == true ? (_pc!.page ?? _loopBase.toDouble()).round() : _loopBase;
          _pc?.dispose();
          _fraction = fraction;
          _pc = PageController(initialPage: at, viewportFraction: fraction);
        }
        return Container(
          height: widget.height,
          padding: EdgeInsets.only(left: pad),
          child: Listener(
            onPointerDown: (_) => _held = true,
            onPointerUp: (_) => _held = false,
            onPointerCancel: (_) => _held = false,
            child: MouseRegion(
              onEnter: (_) => _held = true,
              onExit: (_) => _held = false,
              child: PageView.builder(
                controller: _pc,
                padEnds: false,
                itemBuilder: (c, p) => Padding(
                  padding: const EdgeInsets.only(right: _gap),
                  child: widget.builder(c, p % widget.count),
                ),
              ),
            ),
          ),
        );
      });
}

/// ── Brand & partner logos ────────────────────────────────────────
class PartnerLogoStrip extends StatelessWidget {
  final AppState app;
  const PartnerLogoStrip({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final partners = [...app.brandPartners, ...app.academicPartners];
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _pad(context)),
          child: HomeHeading('Our brands & partners', action: 'All partners', onAction: () => app.setView('partners')),
        ),
        const SizedBox(height: 12),
        if (partners.isEmpty)
          // No partner has been published yet — sell the wall instead.
          _AutoRail(
            count: 5,
            itemWidth: 148,
            height: 84,
            builder: (_, i) => _YourLogoTile(onTap: () => app.setView('advertise')),
          )
        else
          _AutoRail(
            count: partners.length,
            itemWidth: 148,
            height: 84,
            every: const Duration(milliseconds: 2200),
            builder: (_, i) => _LogoTile(partner: partners[i], app: app),
          ),
      ]),
    );
  }
}

class _LogoTile extends StatelessWidget {
  final LogoPartner partner;
  final AppState app;
  const _LogoTile({required this.partner, required this.app});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: partner.website.isEmpty ? partner.name : '${partner.name} — open site',
        child: HoverFx(
          onTap: () async {
            if (partner.website.isEmpty) {
              app.setView('partners');
              return;
            }
            final ok = await LinkService.open(partner.website);
            if (!ok) app.showToast('Couldn\'t open the site', partner.website, '⚠️');
          },
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: T.card,
              border: Border.all(color: h ? T.gold : T.bdr),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              LogoMark(name: partner.name, logoUrl: partner.logoUrl, size: 44, bg: partner.bg, padding: const EdgeInsets.all(5)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(partner.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: F.syne(size: 12, weight: FontWeight.w700, color: T.cream, height: 1.25)),
              ),
            ]),
          ),
        ),
      );
}

class _YourLogoTile extends StatelessWidget {
  final VoidCallback onTap;
  const _YourLogoTile({required this.onTap});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: h ? T.gold.withValues(alpha: .06) : T.card,
            border: Border.all(color: h ? T.gold : T.bdhi),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_business_outlined, size: 20, color: T.gold),
            const SizedBox(height: 4),
            Text('Your brand here', style: F.syne(size: 12, weight: FontWeight.w700, color: T.text)),
          ]),
        ),
      );
}

/// ── Posters & video: live events, fashion walks, workshops ───────
class _Poster {
  final String tag;
  final String title;
  final String meta;
  final String imageUrl;
  final String videoUrl;
  final String emoji;
  final String motif;
  final int bg;
  final void Function(BuildContext) onTap;
  const _Poster({
    required this.tag,
    required this.title,
    required this.onTap,
    this.meta = '',
    this.imageUrl = '',
    this.videoUrl = '',
    this.emoji = '✦',
    this.motif = 'crew',
    this.bg = 0,
  });
}

class EventPosterShow extends StatelessWidget {
  final AppState app;
  const EventPosterShow({super.key, required this.app});

  List<_Poster> _posters() {
    String when(String date, String city) => [date, city].where((s) => s.trim().isNotEmpty).join('  ·  ');
    final real = <_Poster>[
      for (final e in app.platformEvents)
        _Poster(
          tag: '${e['category'] ?? e['kind'] ?? 'Live event'}',
          title: '${e['title'] ?? ''}',
          meta: when('${e['date'] ?? ''}', '${e['city'] ?? ''}'),
          imageUrl: '${e['image_url'] ?? ''}'.trim(),
          videoUrl: '${e['video_url'] ?? ''}'.trim(),
          emoji: '${e['emoji'] ?? '📅'}',
          bg: (e['bg'] as num?)?.toInt() ?? 0,
          onTap: (c) => showEventBooking(c, app, e),
        ),
      for (final s in app.sessions)
        _Poster(
          tag: s.isWebinar ? 'Webinar' : 'Workshop',
          title: s.title,
          meta: when(s.date, s.city),
          emoji: s.emoji,
          motif: 'education',
          bg: s.bg,
          onTap: (c) => showSessionRegister(c, app, s),
        ),
    ].where((p) => p.title.trim().isNotEmpty).toList();

    // AOneGo9's own posters keep the show full until the desk publishes —
    // each one opens the real section it names.
    final house = [
      _Poster(tag: 'AOneGo9', title: 'Live events near you', meta: 'Castings, shows & open houses', emoji: '🎤', bg: 1,
          onTap: (_) => app.setView('events')),
      _Poster(tag: 'AOneGo9', title: 'Fashion walks', meta: 'Ramp shows & fashion weeks', emoji: '👠', motif: 'fashion', bg: 3,
          onTap: (_) => app.setView('events')),
      _Poster(tag: 'AOneGo9', title: 'Workshops & webinars', meta: 'Learn from the people who run the floor', emoji: '🎓',
          motif: 'education', bg: 5, onTap: (_) => app.setView('sessions')),
      _Poster(tag: 'AOneGo9', title: 'Casting calls', meta: 'Brands looking for faces this week', emoji: '📣', motif: 'talent', bg: 7,
          onTap: (_) => app.openResults(division: 'talent')),
    ];
    return [...real, ...house.take((5 - real.length).clamp(0, house.length))];
  }

  @override
  Widget build(BuildContext context) {
    final posters = _posters();
    final narrow = isNarrow(context);
    final w = narrow ? 168.0 : 216.0;
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _pad(context)),
          child: HomeHeading('Live events · Fashion walks · Workshops', action: 'All events', onAction: () => app.setView('events')),
        ),
        const SizedBox(height: 12),
        _AutoRail(
          count: posters.length,
          itemWidth: w,
          height: w * 4 / 3,
          builder: (_, i) => _PosterCard(poster: posters[i]),
        ),
      ]),
    );
  }
}

class _PosterCard extends StatelessWidget {
  final _Poster poster;
  const _PosterCard({required this.poster});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: () => poster.onTap(context),
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: h ? T.marigold : Colors.transparent, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(fit: StackFit.expand, children: [
            if (poster.videoUrl.isNotEmpty)
              AdVideo(url: poster.videoUrl, posterUrl: poster.imageUrl, bg: poster.bg, emoji: poster.emoji)
            else if (poster.imageUrl.isNotEmpty)
              AdStill(url: poster.imageUrl, bg: poster.bg, emoji: poster.emoji)
            else ...[
              DecoratedBox(decoration: BoxDecoration(gradient: T.grPoster(poster.bg))),
              DivisionFx(divisionId: poster.motif, accent: T.marigold, intensity: h ? 2 : 1.3, fadeToward: Alignment.bottomCenter),
              Align(
                alignment: const Alignment(0, -.25),
                child: AnimatedScale(
                  scale: h ? 1.1 : 1,
                  duration: const Duration(milliseconds: 240),
                  child: Text(poster.emoji, style: const TextStyle(fontSize: 58)),
                ),
              ),
            ],
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xE6140A0B)],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: T.marigold, borderRadius: BorderRadius.circular(3)),
                  child: Text(poster.tag.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: F.syne(size: 9, weight: FontWeight.w800, color: const Color(0xFF2A1404), letterSpacing: 1.1)),
                ),
                const SizedBox(height: 7),
                Text(poster.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: F.fraunces(size: 15, weight: FontWeight.w700, color: T.posterInk, height: 1.2)),
                if (poster.meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(poster.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: F.syne(size: 11, weight: FontWeight.w500, color: T.posterInkMuted)),
                ],
              ]),
            ),
            if (poster.videoUrl.isNotEmpty)
              const Positioned(
                right: 10,
                top: 10,
                child: Icon(Icons.play_circle_fill_rounded, size: 26, color: Colors.white),
              ),
          ]),
        ),
      );
}

/// ── Industry experts: celebrities, actors, models ────────────────
class _Expert {
  final String name;
  final String role;
  final String imageUrl;
  final String videoUrl;
  final String emoji;
  final double rating;
  final bool promoted;
  final bool verified;
  final int bg;
  final void Function(BuildContext) onTap;
  const _Expert({
    required this.name,
    required this.role,
    required this.onTap,
    this.imageUrl = '',
    this.videoUrl = '',
    this.emoji = '⭐',
    this.rating = 0,
    this.promoted = false,
    this.verified = false,
    this.bg = 0,
  });
}

class IndustryExperts extends StatelessWidget {
  final AppState app;

  /// Pads the row to the page gutter; off when a page supplies its own.
  final bool padded;
  const IndustryExperts({super.key, required this.app, this.padded = true});

  List<_Expert> _experts() {
    final promoted = [
      for (final a in app.ads.where((a) => a.opensProfile))
        _Expert(
          name: a.profileName.isNotEmpty ? a.profileName : a.headline,
          role: catOf(a.profileCat)?.name ?? (a.label.isEmpty ? 'Featured' : a.label),
          imageUrl: a.imageUrl,
          videoUrl: a.isVideo ? a.videoUrl : '',
          emoji: a.emoji,
          promoted: true,
          bg: a.bg,
          onTap: (c) => openAdCreative(c, app, a),
        ),
    ];
    final ids = {for (final a in app.ads) a.profileId};
    final talent = [
      for (final v in app.featuredTalent.where((v) => !ids.contains(v['id'])))
        _Expert(
          name: '${v['name'] ?? ''}',
          role: catOf(v['cat'] as String?)?.name ?? 'Talent',
          imageUrl: '${v['avatarUrl'] ?? ''}',
          emoji: '${v['emoji'] ?? '⭐'}',
          rating: (v['rating'] as num?)?.toDouble() ?? 0,
          verified: v['verified'] == true,
          bg: '${v['id']}'.hashCode.abs() % 9,
          onTap: (_) => app.openProfile(v),
        ),
    ];
    return [...promoted, ...talent].where((e) => e.name.trim().isNotEmpty).take(16).toList();
  }

  @override
  Widget build(BuildContext context) {
    final experts = _experts();
    final narrow = isNarrow(context);
    final w = narrow ? 150.0 : 190.0;
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padded ? _pad(context) : 0),
          child: HomeHeading('Industry experts — celebrities, actors & models',
              action: 'See all', onAction: () => app.openResults(division: 'talent')),
        ),
        const SizedBox(height: 12),
        _AutoRail(
          count: experts.isEmpty ? 4 : experts.length,
          itemWidth: w,
          // The photo takes what the two text lines leave (see _ExpertCard).
          height: w * 1.25 + 56,
          every: const Duration(milliseconds: 2800),
          builder: (_, i) => experts.isEmpty
              ? _PromoteYourselfCard(onTap: () => app.setView('advertise'), bg: i)
              : _ExpertCard(expert: experts[i]),
        ),
      ]),
    );
  }
}

class _ExpertCard extends StatelessWidget {
  final _Expert expert;
  const _ExpertCard({required this.expert});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: () => expert.onTap(context),
        builder: (h) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: h ? T.gold : T.bdr, width: h ? 1.6 : 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(fit: StackFit.expand, children: [
                if (expert.videoUrl.isNotEmpty)
                  AdVideo(url: expert.videoUrl, posterUrl: expert.imageUrl, bg: expert.bg, emoji: expert.emoji)
                else
                  AdStill(url: expert.imageUrl, bg: expert.bg, emoji: expert.emoji),
                if (expert.promoted)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: T.marigold, borderRadius: BorderRadius.circular(3)),
                      child: Text('PROMOTED',
                          style: F.syne(size: 8.5, weight: FontWeight.w800, color: const Color(0xFF2A1404), letterSpacing: 1.1)),
                    ),
                  ),
                if (expert.videoUrl.isNotEmpty)
                  const Positioned(
                    right: 8,
                    top: 8,
                    child: Icon(Icons.play_circle_fill_rounded, size: 24, color: Colors.white),
                  ),
                if (expert.rating > 0)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(6, 2, 5, 2),
                      decoration: BoxDecoration(color: T.grn, borderRadius: BorderRadius.circular(4)),
                      child: Text('${expert.rating.toStringAsFixed(1)} ★',
                          style: F.syne(size: 11, weight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Flexible(
              child: Text(expert.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: F.syne(size: 13.5, weight: FontWeight.w700, color: h ? T.gold : T.cream)),
            ),
            if (expert.verified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified_rounded, size: 14, color: T.logoCyan),
            ],
          ]),
          const SizedBox(height: 2),
          Text(expert.role,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: F.syne(size: 11.5, weight: FontWeight.w500, color: T.mut)),
        ]),
      );
}

class _PromoteYourselfCard extends StatelessWidget {
  final VoidCallback onTap;
  final int bg;
  const _PromoteYourselfCard({required this.onTap, required this.bg});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: T.grPoster(bg + 1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: h ? T.marigold : Colors.transparent, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(fit: StackFit.expand, children: [
                DivisionFx(divisionId: 'talent', accent: T.marigold, intensity: h ? 2 : 1.2, fadeToward: Alignment.bottomCenter),
                Center(child: Text(const ['⭐', '🎬', '📸', '🎭'][bg % 4], style: const TextStyle(fontSize: 46))),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text('Your profile here', style: F.syne(size: 13.5, weight: FontWeight.w700, color: h ? T.gold : T.cream)),
          const SizedBox(height: 2),
          Text('Promote it →', style: F.syne(size: 11.5, weight: FontWeight.w600, color: T.gold)),
        ]),
      );
}
