import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/events_screen.dart' show showEventBooking;
import '../screens/sessions_screen.dart' show showSessionRegister;
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'ad_slot.dart' show AdStill, AdVideo, openAdCreative;
import 'common.dart';
import 'division_fx.dart';

/// The home page's spotlight — one auto-advancing rectangle above "Browse
/// the floor" that carries whatever the desk has published, video or photo,
/// and takes the visitor straight to the action behind it:
///
///   ad creative     → the promoted profile, or the advertiser's site
///   event           → the booking form for that event
///   workshop/webinar→ the seat-reservation form
///   digest story    → the story
///
/// When the desk has published little or nothing, AOneGo9's own house posts
/// fill the reel — motion-graphic slides (the [DivisionFx] vocabulary on the
/// poster ground) that point at real sections of the app. They are labelled
/// as AOneGo9's own and never pose as a listing, an event or a person.
///
/// Story-style progress segments show where you are and how long is left;
/// it pauses under a cursor or a finger, has an explicit pause control
/// (auto-moving content needs one), and starts paused for visitors who asked
/// their OS to reduce motion.
class SpotlightReel extends StatefulWidget {
  /// Opens a division's results on the browse page (house slides use it).
  final ValueChanged<String> onOpenDivision;
  const SpotlightReel({super.key, required this.onOpenDivision});

  @override
  State<SpotlightReel> createState() => _SpotlightReelState();
}

class _Slide {
  final String key;
  final String tag;
  final bool disclose; // true for paid creatives — shows the AD marker
  final String title;
  final String sub;
  final String meta;
  final String cta;
  final String motif;
  final String imageUrl;
  final String videoUrl;
  final String emoji;
  final int bg;
  final void Function(BuildContext, AppState) onTap;
  const _Slide({
    required this.key,
    required this.tag,
    required this.title,
    required this.sub,
    required this.cta,
    required this.onTap,
    this.disclose = false,
    this.meta = '',
    this.motif = 'talent',
    this.imageUrl = '',
    this.videoUrl = '',
    this.emoji = '',
    this.bg = 0,
  });

  bool get isVideo => videoUrl.isNotEmpty;
}

class _SpotlightReelState extends State<SpotlightReel> with SingleTickerProviderStateMixin {
  static const _minSlides = 5;
  static const _maxRealSlides = 8;

  // A large virtual page count lets the reel loop forward forever without a
  // visible jump back to the first slide.
  static const _loopBase = 10000;
  late final PageController _pc = PageController(initialPage: _loopBase);
  late final AnimationController _progress = AnimationController(vsync: this)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _next();
    });

  int _page = _loopBase;
  bool _hovering = false;
  bool _touching = false;
  bool _userPaused = false;
  bool _reduceMotion = false;
  bool _started = false;
  Timer? _resume;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (!_started) {
      _started = true;
      _reduceMotion = reduce;
      _userPaused = reduce;
      WidgetsBinding.instance.addPostFrameCallback((_) => _restart());
    } else {
      _reduceMotion = reduce;
    }
  }

  @override
  void dispose() {
    _resume?.cancel();
    _progress.dispose();
    _pc.dispose();
    super.dispose();
  }

  bool get _paused => _hovering || _touching || _userPaused;

  void _restart() {
    if (!mounted) return;
    final slides = _slides(context.read<AppState>());
    if (slides.isEmpty) return;
    final s = slides[_page % slides.length];
    // Video gets longer on screen — it needs a moment to start and be seen.
    _progress
      ..duration = Duration(milliseconds: s.isVideo ? 9000 : 6000)
      ..value = 0;
    if (!_paused) _progress.forward();
  }

  void _syncPlayback() {
    if (_paused) {
      _progress.stop();
    } else if (!_progress.isAnimating && _progress.value < 1) {
      _progress.forward();
    }
  }

  void _next() => _go(_page + 1);
  void _prev() => _go(_page - 1);

  void _go(int page) {
    if (!_pc.hasClients) return;
    if (_reduceMotion) {
      _pc.jumpToPage(page);
    } else {
      _pc.animateToPage(page, duration: const Duration(milliseconds: 520), curve: Curves.easeInOutCubic);
    }
  }

  // ── Slide sources ───────────────────────────────────────────────

  List<_Slide> _slides(AppState app) {
    final real = <_Slide>[
      for (final a in app.ads.take(4))
        _Slide(
          key: 'ad-${a.id}',
          tag: a.label.isEmpty ? 'Featured' : a.label,
          disclose: true,
          title: a.headline,
          sub: a.sub,
          meta: [a.profileName, a.city].where((x) => x.isNotEmpty).join(' · '),
          cta: a.opensProfile ? 'View profile' : 'Visit',
          imageUrl: a.imageUrl,
          videoUrl: a.isVideo ? a.videoUrl : '',
          emoji: a.emoji,
          bg: a.bg,
          motif: 'talent',
          onTap: (ctx, app) => openAdCreative(ctx, app, a),
        ),
      for (final e in app.platformEvents
          .where((e) => '${e['status'] ?? ''}'.toLowerCase() != 'past')
          .toList()
        ..sort((a, b) => (b['on_poster'] == true ? 1 : 0) - (a['on_poster'] == true ? 1 : 0)))
        _Slide(
          key: 'ev-${e['id']}',
          tag: e['on_poster'] == true ? 'Event · On the poster' : 'Event',
          title: '${e['title'] ?? ''}',
          sub: '${e['blurb'] ?? ''}',
          meta: [e['date'], e['venue'], e['city']].where((x) => '${x ?? ''}'.isNotEmpty).join(' · '),
          cta: 'Book a spot',
          imageUrl: '${e['image_url'] ?? ''}',
          videoUrl: '${e['video_url'] ?? ''}',
          emoji: '${e['emoji'] ?? '📅'}',
          bg: (e['bg'] as num?)?.toInt() ?? 0,
          motif: 'crew',
          onTap: (ctx, app) => showEventBooking(ctx, app, e),
        ),
      for (final s in app.sessions.where((s) => !s.soldOut))
        _Slide(
          key: 'se-${s.id}',
          tag: s.isWebinar ? 'Webinar' : 'Workshop',
          title: s.title,
          sub: s.blurb,
          meta: [s.date, if (s.time.isNotEmpty) s.time, s.city, s.isFree ? 'Free' : s.fee]
              .where((x) => x.isNotEmpty)
              .join(' · '),
          cta: s.nearlyFull ? 'Last seats — reserve' : 'Reserve a seat',
          emoji: s.emoji,
          bg: s.bg,
          motif: 'education',
          onTap: (ctx, app) => showSessionRegister(ctx, app, s),
        ),
      for (final n in app.newsletters.take(2))
        _Slide(
          key: 'nl-${n.id}',
          tag: n.kind == 'trend' ? 'Trend' : 'What\'s happening',
          title: n.title,
          sub: n.excerpt,
          meta: [n.date, n.city].where((x) => x.isNotEmpty).join(' · '),
          cta: 'Read the story',
          imageUrl: n.imageUrl ?? '',
          emoji: n.emoji,
          bg: n.bg,
          motif: 'post',
          onTap: (ctx, app) => app.openIssue(n),
        ),
    ].where((s) => s.title.trim().isNotEmpty).take(_maxRealSlides).toList();

    final house = _houseSlides();
    final need = (_minSlides - real.length).clamp(0, house.length);
    return [...real, ...house.take(need)];
  }

  /// AOneGo9's own posts. Each points at a real place in the app.
  List<_Slide> _houseSlides() => [
        _Slide(
          key: 'h-events',
          tag: 'AOneGo9 · Events',
          title: 'Castings, shows & open houses — book in a tap',
          sub: 'See what is on the calendar near you and reserve your place.',
          cta: 'See events',
          motif: 'crew',
          bg: 1,
          onTap: (ctx, app) => app.setView('events'),
        ),
        _Slide(
          key: 'h-apply',
          tag: 'AOneGo9 · For talent & vendors',
          title: 'Get listed. Get briefed. Get booked.',
          sub: 'Apply as an artist, or list your studio, venue, crew or label.',
          cta: 'Apply now',
          motif: 'talent',
          bg: 2,
          onTap: (ctx, app) => app.openConnect('apply'),
        ),
        _Slide(
          key: 'h-sessions',
          tag: 'AOneGo9 · Workshops & Webinars',
          title: 'Learn from the people who run the floor',
          sub: 'Posing, portfolios, lighting, editing — reserve a seat.',
          cta: 'Reserve a seat',
          motif: 'education',
          bg: 3,
          onTap: (ctx, app) => app.setView('sessions'),
        ),
        _Slide(
          key: 'h-venues',
          tag: 'AOneGo9 · Venues',
          title: 'Find the room for your next shoot',
          sub: 'Studios, heritage properties and event spaces across India.',
          cta: 'Browse venues',
          motif: 'spaces',
          bg: 4,
          onTap: (ctx, app) => widget.onOpenDivision('spaces'),
        ),
        _Slide(
          key: 'h-digest',
          tag: 'AOneGo9 · The Friday digest',
          title: 'What is happening — and what is trending',
          sub: 'Castings, campaigns and the crews actually booking, every Friday.',
          cta: 'Read the digest',
          motif: 'post',
          bg: 5,
          onTap: (ctx, app) => app.setView('newsletter'),
        ),
      ];

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final slides = _slides(app);
    if (slides.isEmpty) return const SizedBox.shrink();

    final w = screenW(context);
    final narrow = isNarrow(context);
    final pad = narrow ? 16.0 : 20.0;
    // A rectangle that keeps its shape with the screen: tall enough on a
    // phone for two lines of title and a button, letterboxed on desktop.
    final height = narrow ? (w * .62).clamp(210.0, 270.0) : (w < 1024 ? 300.0 : 340.0);
    final count = slides.length;
    final current = _page % count;

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, narrow ? 18 : 26, pad, 0),
      child: Semantics(
        container: true,
        label: 'Spotlight, slide ${current + 1} of $count',
        child: MouseRegion(
          onEnter: (_) {
            _hovering = true;
            _syncPlayback();
            setState(() {});
          },
          onExit: (_) {
            _hovering = false;
            _syncPlayback();
            setState(() {});
          },
          child: Listener(
            onPointerDown: (_) {
              _resume?.cancel();
              _touching = true;
              _syncPlayback();
            },
            onPointerUp: (_) => _releaseTouch(),
            onPointerCancel: (_) => _releaseTouch(),
            child: SizedBox(
              height: height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pc,
                      onPageChanged: (p) {
                        setState(() => _page = p);
                        _restart();
                      },
                      itemBuilder: (ctx, i) {
                        final s = slides[i % count];
                        return _SlideView(
                          key: ValueKey('${s.key}-$i'),
                          slide: s,
                          narrow: narrow,
                          onTap: () => s.onTap(context, app),
                        );
                      },
                    ),
                    // Story-style progress — one segment per slide.
                    Positioned(
                      left: 12,
                      right: 52,
                      top: 10,
                      child: AnimatedBuilder(
                        animation: _progress,
                        builder: (_, __) => Row(children: [
                          for (var i = 0; i < count; i++) ...[
                            if (i > 0) const SizedBox(width: 4),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _go(_page - current + i),
                                child: Container(
                                  height: 14,
                                  alignment: Alignment.center,
                                  color: Colors.transparent,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      minHeight: 3,
                                      value: i < current ? 1 : (i == current ? _progress.value : 0),
                                      backgroundColor: Colors.white.withValues(alpha: .28),
                                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ]),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 6,
                      child: _RoundBtn(
                        icon: _userPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        tooltip: _userPaused ? 'Play spotlight' : 'Pause spotlight',
                        size: 36,
                        onTap: () {
                          setState(() => _userPaused = !_userPaused);
                          _syncPlayback();
                        },
                      ),
                    ),
                    if (!narrow) ...[
                      Positioned(
                        left: 12,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: _hovering ? 1 : 0,
                            child: _RoundBtn(icon: Icons.chevron_left_rounded, tooltip: 'Previous', onTap: _prev),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: _hovering ? 1 : 0,
                            child: _RoundBtn(icon: Icons.chevron_right_rounded, tooltip: 'Next', onTap: _next),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Hold briefly after a touch so a swipe or a tap is not chased by an
  /// immediate auto-advance.
  void _releaseTouch() {
    _resume?.cancel();
    _resume = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      _touching = false;
      _syncPlayback();
    });
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  final bool narrow;
  final VoidCallback onTap;
  const _SlideView({super.key, required this.slide, required this.narrow, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = slide;
    final hasMedia = s.imageUrl.isNotEmpty || s.isVideo;
    final accent = T.dac(s.motif);
    return Semantics(
      button: true,
      label: '${s.tag}: ${s.title}. ${s.cta}',
      child: HoverFx(
        onTap: onTap,
        builder: (h) => Stack(
          fit: StackFit.expand,
          children: [
            // Ground: the real creative when there is one, otherwise the
            // poster gradient with the slide's motif moving across it.
            if (s.isVideo)
              AdVideo(url: s.videoUrl, posterUrl: s.imageUrl, bg: s.bg, emoji: s.emoji)
            else if (s.imageUrl.isNotEmpty)
              AdStill(url: s.imageUrl, bg: s.bg, emoji: s.emoji)
            else
              DecoratedBox(decoration: BoxDecoration(gradient: T.grPoster(s.bg))),
            if (!hasMedia) ...[
              Positioned.fill(
                child: DivisionFx(
                  divisionId: s.motif,
                  // Marigold on the dark poster ground, whatever the theme.
                  accent: T.marigold,
                  intensity: h ? 2.6 : 2.0,
                  fadeToward: Alignment.bottomLeft,
                ),
              ),
              if (s.emoji.isNotEmpty)
                Positioned(
                  right: narrow ? 18 : 48,
                  bottom: narrow ? 64 : 60,
                  child: Opacity(
                    opacity: .22,
                    child: Text(s.emoji, style: TextStyle(fontSize: narrow ? 64 : 110)),
                  ),
                ),
            ],
            // Scrim so copy stays legible over any creative.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x3309090B), Color(0x1409090B), Color(0xE609090B)],
                    stops: [0, .35, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: narrow ? 16 : 28,
              right: narrow ? 16 : 28,
              top: 34,
              child: Wrap(spacing: 6, runSpacing: 6, children: [
                if (s.disclose) const _Tag(text: 'AD', muted: true),
                _Tag(text: s.tag.toUpperCase(), color: accent),
                if (s.isVideo) const _Tag(text: '▶ VIDEO', muted: true),
              ]),
            ),
            Positioned(
              left: narrow ? 16 : 28,
              right: narrow ? 16 : 28,
              bottom: narrow ? 16 : 26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Text(
                      s.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: F.fraunces(size: narrow ? 21 : 30, weight: FontWeight.w700, color: T.posterInk, height: 1.15),
                    ),
                  ),
                  if (s.sub.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Text(s.sub,
                          maxLines: narrow ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: F.syne(size: narrow ? 12.5 : 14, weight: FontWeight.w400, color: T.posterInkMuted, height: 1.5)),
                    ),
                  ],
                  SizedBox(height: narrow ? 12 : 16),
                  Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: EdgeInsets.symmetric(horizontal: narrow ? 14 : 18, vertical: narrow ? 9 : 11),
                      decoration: BoxDecoration(
                        color: h ? T.logoAmber : T.marigold,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(s.cta,
                            style: F.syne(size: narrow ? 12.5 : 13.5, weight: FontWeight.w700, color: const Color(0xFF14120E))),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF14120E)),
                      ]),
                    ),
                    if (s.meta.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(s.meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: F.mono(size: 11, color: T.posterInkMuted)),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color? color;
  final bool muted;
  const _Tag({required this.text, this.color, this.muted = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: muted ? const Color(0xCC09090B) : Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(text,
            style: F.syne(
                size: 9,
                weight: FontWeight.w800,
                color: muted ? T.posterInk : (color ?? T.gold),
                letterSpacing: 1.2)),
      );
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  const _RoundBtn({required this.icon, required this.tooltip, required this.onTap, this.size = 40});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          label: tooltip,
          child: HoverFx(
            onTap: onTap,
            builder: (h) => Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: h ? const Color(0xEE09090B) : const Color(0x9909090B),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: size * .55, color: Colors.white),
            ),
          ),
        ),
      );
}
