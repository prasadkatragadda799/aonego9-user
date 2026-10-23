
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/directory.dart';
import '../data/taxonomy.dart';
import '../screens/events_screen.dart' show showEventBooking;
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'ad_slot.dart' show AdStill, AdVideo, openAdCreative;
import 'common.dart';
import 'home_sections.dart' show artistCatIds;
import 'results_kit.dart' show shareProfileOnWhatsApp;

/// ─────────────────────────────────────────────────────────────────
/// REELS — "artists' profile photos & videos, Instagram-style, with ad
/// videos from other companies between them".
///
/// One vertical, full-screen feed: swipe (or scroll, or ↑/↓) through the
/// photos and videos artists have put on their profiles, with sponsored
/// creatives every few reels and event videos when the desk has them.
/// Every reel leads somewhere real — the profile, the advertiser, the
/// booking form.
/// ─────────────────────────────────────────────────────────────────

class ReelItem {
  final String key;

  /// artist | ad | event | house
  final String kind;
  final String imageUrl;
  final String videoUrl;
  final String title;
  final String subtitle;
  final String emoji;
  final int bg;
  final Map<String, dynamic>? profile;
  final AdCreative? ad;
  final Map<String, dynamic>? event;
  const ReelItem({
    required this.key,
    required this.kind,
    required this.title,
    this.subtitle = '',
    this.imageUrl = '',
    this.videoUrl = '',
    this.emoji = '✦',
    this.bg = 0,
    this.profile,
    this.ad,
    this.event,
  });

  bool get isVideo => videoUrl.isNotEmpty;
}

/// Every reel the app can show right now, in feed order: artists' media
/// with a sponsored reel after every third, then event videos.
List<ReelItem> buildReels(AppState app) {
  // Reels are the artists' own work — studios and venues have their
  // galleries on their profiles instead.
  final artists = <String, Map<String, dynamic>>{
    for (final v in [...app.featuredTalent, ...app.catItems])
      if (artistCatIds.contains(v['cat'])) '${v['id']}': v,
  };
  final artistReels = <ReelItem>[];
  for (final v in artists.values) {
    final urls = <String>{
      '${v['avatarUrl'] ?? ''}'.trim(),
      ...((v['galleryUrls'] as List?) ?? const []).map((e) => '$e'.trim()),
    }.where((u) => u.isNotEmpty).take(3);
    final cat = catOf(v['cat'] as String?)?.name ?? '';
    final loc = '${v['loc'] ?? ''}';
    var n = 0;
    for (final u in urls) {
      final isVideo = RegExp(r'\.(mp4|webm|mov|m3u8)(\?|$)', caseSensitive: false).hasMatch(u);
      artistReels.add(ReelItem(
        key: 'a-${v['id']}-${n++}',
        kind: 'artist',
        title: '${v['name'] ?? ''}',
        subtitle: [cat, loc].where((s) => s.isNotEmpty).join('  ·  '),
        imageUrl: isVideo ? '' : u,
        videoUrl: isVideo ? u : '',
        emoji: '${v['emoji'] ?? '✦'}',
        bg: '${v['id']}'.hashCode.abs() % 9,
        profile: v,
      ));
    }
  }

  final adReels = [
    for (final a in app.ads.where((a) => a.imageUrl.isNotEmpty || a.videoUrl.isNotEmpty))
      ReelItem(
        key: 'ad-${a.id}',
        kind: 'ad',
        title: a.headline,
        subtitle: a.sub,
        imageUrl: a.imageUrl,
        videoUrl: a.isVideo ? a.videoUrl : '',
        emoji: a.emoji,
        bg: a.bg,
        ad: a,
      ),
  ];

  final eventReels = [
    for (final e in app.platformEvents.where((e) => '${e['video_url'] ?? ''}'.trim().isNotEmpty))
      ReelItem(
        key: 'ev-${e['id']}',
        kind: 'event',
        title: '${e['title'] ?? ''}',
        subtitle: ['${e['date'] ?? ''}', '${e['city'] ?? ''}'].where((s) => s.trim().isNotEmpty).join('  ·  '),
        imageUrl: '${e['image_url'] ?? ''}'.trim(),
        videoUrl: '${e['video_url'] ?? ''}'.trim(),
        emoji: '${e['emoji'] ?? '📅'}',
        bg: (e['bg'] as num?)?.toInt() ?? 0,
        event: e,
      ),
  ];

  final feed = <ReelItem>[];
  var ad = 0;
  for (var i = 0; i < artistReels.length; i++) {
    feed.add(artistReels[i]);
    if ((i + 1) % 3 == 0 && ad < adReels.length) feed.add(adReels[ad++]);
  }
  feed
    ..addAll(adReels.skip(ad))
    ..addAll(eventReels);
  return feed.where((r) => r.title.trim().isNotEmpty).toList();
}

/// Opens the feed full-screen at [start].
Future<void> showReelsViewer(BuildContext context, {List<ReelItem>? items, int start = 0}) {
  final app = context.read<AppState>();
  final reels = items ?? buildReels(app);
  return showGeneralDialog<void>(
    context: context,
    barrierColor: Colors.black,
    barrierDismissible: false,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, __) =>
        _ReelsViewer(outer: context, reels: reels, start: start.clamp(0, reels.isEmpty ? 0 : reels.length - 1)),
    transitionBuilder: (ctx, a, __, child) => FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, .06), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}

class _ReelsViewer extends StatefulWidget {
  /// The page that opened the feed — where a reel's action lands once the
  /// feed has closed.
  final BuildContext outer;
  final List<ReelItem> reels;
  final int start;
  const _ReelsViewer({required this.outer, required this.reels, required this.start});

  @override
  State<_ReelsViewer> createState() => _ReelsViewerState();
}

class _ReelsViewerState extends State<_ReelsViewer> with SingleTickerProviderStateMixin {
  late final PageController _pc = PageController(initialPage: widget.start);
  late int _at = widget.start;
  final _focus = FocusNode();

  /// Sound stays with the viewer from reel to reel, as it does on Instagram.
  bool _muted = true;

  // Photos have no end of their own, so they move on after a few seconds;
  // videos loop until the viewer swipes. One controller drives both the
  // advance and the progress bar, so holding a reel freezes both.
  late final AnimationController _photo = AnimationController(vsync: this, duration: const Duration(seconds: 6))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _go(1);
    });

  bool get _onPhoto => widget.reels.isNotEmpty && !widget.reels[_at].isVideo;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  void _arm() {
    _photo.reset();
    if (_onPhoto) _photo.forward();
  }

  void _hold(bool held) {
    if (!_onPhoto) return;
    if (held) {
      _photo.stop();
    } else {
      _photo.forward();
    }
  }

  void _go(int d) {
    final next = _at + d;
    if (next < 0 || next >= widget.reels.length || !_pc.hasClients) return;
    _pc.animateToPage(next, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _photo.dispose();
    _pc.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    final reels = widget.reels;
    // Handled here and stopped: left to bubble, the arrow keys would also
    // reach the app's scroll shortcuts and move the feed a second time.
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
        if (e.logicalKey == LogicalKeyboardKey.arrowDown || e.logicalKey == LogicalKeyboardKey.pageDown) {
          _go(1);
        } else if (e.logicalKey == LogicalKeyboardKey.arrowUp || e.logicalKey == LogicalKeyboardKey.pageUp) {
          _go(-1);
        } else if (e.logicalKey == LogicalKeyboardKey.escape) {
          _close();
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: Material(
        color: Colors.black,
        child: SafeArea(
          child: Stack(children: [
            // On a wide screen the feed is a phone-shaped column, the way
            // reels are watched; on a phone it is the whole screen.
            Center(
              child: AspectRatio(
                aspectRatio: narrow ? MediaQuery.of(context).size.aspectRatio : 9 / 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(narrow ? 0 : 16),
                  child: reels.isEmpty
                      ? const _EmptyReels()
                      : PageView.builder(
                          controller: _pc,
                          scrollDirection: Axis.vertical,
                          itemCount: reels.length,
                          onPageChanged: (i) {
                            setState(() => _at = i);
                            _arm();
                          },
                          itemBuilder: (c, i) => _ReelPage(
                            outer: widget.outer,
                            reel: reels[i],
                            active: i == _at,
                            muted: _muted,
                            onClose: _close,
                            onHold: _hold,
                          ),
                        ),
                ),
              ),
            ),
            // Photo timer — a thin bar along the top, like a story.
            if (_onPhoto)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Center(
                  child: SizedBox(
                    width: narrow ? double.infinity : 420,
                    child: AnimatedBuilder(
                      animation: _photo,
                      builder: (_, __) => LinearProgressIndicator(
                        value: _photo.value,
                        minHeight: 2,
                        backgroundColor: Colors.white.withValues(alpha: .15),
                        valueColor: const AlwaysStoppedAnimation(T.marigold),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Row(children: [
                Text('Reels', style: F.fraunces(size: 20, weight: FontWeight.w700, color: Colors.white)),
                const SizedBox(width: 8),
                if (reels.isNotEmpty)
                  Text('${_at + 1} / ${reels.length}',
                      style: F.syne(size: 12, weight: FontWeight.w600, color: Colors.white.withValues(alpha: .7))),
                const Spacer(),
                if (reels.isNotEmpty && reels[_at].isVideo) ...[
                  _RoundBtn(
                    icon: _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    tip: _muted ? 'Sound on' : 'Sound off',
                    onTap: () => setState(() => _muted = !_muted),
                  ),
                  const SizedBox(width: 8),
                ],
                _RoundBtn(icon: Icons.close_rounded, tip: 'Close', onTap: _close),
              ]),
            ),
            if (!narrow && reels.length > 1)
              Positioned(
                right: 24,
                top: 0,
                bottom: 0,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _RoundBtn(icon: Icons.keyboard_arrow_up_rounded, tip: 'Previous', onTap: () => _go(-1)),
                  const SizedBox(height: 10),
                  _RoundBtn(icon: Icons.keyboard_arrow_down_rounded, tip: 'Next', onTap: () => _go(1)),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}

class _ReelPage extends StatelessWidget {
  final BuildContext outer;
  final ReelItem reel;
  final bool active;
  final bool muted;
  final VoidCallback onClose;
  final ValueChanged<bool> onHold;
  const _ReelPage({
    required this.outer,
    required this.reel,
    required this.active,
    required this.muted,
    required this.onClose,
    required this.onHold,
  });

  void _open(AppState app) {
    onClose();
    final r = reel;
    if (r.profile != null) {
      app.openProfile(r.profile!);
    } else if (r.ad != null && outer.mounted) {
      openAdCreative(outer, app, r.ad!);
    } else if (r.event != null && outer.mounted) {
      showEventBooking(outer, app, r.event!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final r = reel;
    final profile = r.profile;
    final saved = profile != null && app.isShortlisted('${profile['id']}');
    final cta = switch (r.kind) {
      'artist' => 'View profile',
      'event' => 'Book now',
      _ => r.ad?.opensProfile == true ? 'View profile' : 'Visit',
    };

    return GestureDetector(
      onLongPressStart: (_) => onHold(true),
      onLongPressEnd: (_) => onHold(false),
      child: Stack(fit: StackFit.expand, children: [
        // Only the reel on screen plays — the neighbours stay as stills so a
        // long feed doesn't start a dozen videos at once.
        if (r.isVideo && active)
          AdVideo(url: r.videoUrl, posterUrl: r.imageUrl, bg: r.bg, emoji: r.emoji, muted: muted)
        else
          AdStill(url: r.imageUrl, bg: r.bg, emoji: r.emoji),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .18, .55, 1],
              colors: [Color(0x99000000), Colors.transparent, Colors.transparent, Color(0xE6000000)],
            ),
          ),
        ),
        // Action column, right edge.
        Positioned(
          right: 10,
          bottom: 110,
          child: Column(children: [
            if (profile != null) ...[
              _SideAction(
                icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: saved ? 'Saved' : 'Shortlist',
                color: saved ? const Color(0xFFFF6B81) : Colors.white,
                onTap: () => app.toggleShortlist(profile),
              ),
              const SizedBox(height: 16),
              _SideAction(
                icon: Icons.send_rounded,
                label: 'Share',
                onTap: () => shareProfileOnWhatsApp(context, profile),
              ),
              const SizedBox(height: 16),
            ],
            _SideAction(icon: Icons.open_in_new_rounded, label: cta.split(' ').first, onTap: () => _open(app)),
          ]),
        ),
        // Who / what, bottom-left.
        Positioned(
          left: 14,
          right: 76,
          bottom: 18,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            if (r.kind == 'ad')
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(3)),
                child: Text('SPONSORED',
                    style: F.syne(size: 9.5, weight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2)),
              ),
            Row(children: [
              _Dp(reel: r),
              const SizedBox(width: 10),
              Flexible(
                child: Text(r.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: F.syne(size: 15, weight: FontWeight.w800, color: Colors.white, height: 1.2)),
              ),
              if (profile?['verified'] == true) ...[
                const SizedBox(width: 5),
                const Icon(Icons.verified_rounded, size: 16, color: T.logoCyan),
              ],
            ]),
            if (r.subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(r.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: F.syne(size: 12.5, weight: FontWeight.w500, color: Colors.white.withValues(alpha: .8))),
            ],
            const SizedBox(height: 12),
            HoverFx(
              onTap: () => _open(app),
              builder: (h) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: h ? const Color(0xFFFFB84A) : T.marigold,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text('$cta →', style: F.syne(size: 13, weight: FontWeight.w800, color: const Color(0xFF2A1404))),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Dp extends StatelessWidget {
  final ReelItem reel;
  const _Dp({required this.reel});

  @override
  Widget build(BuildContext context) {
    final url = '${reel.profile?['avatarUrl'] ?? ''}'.trim();
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: T.marigold, width: 2),
        gradient: T.grPoster(reel.bg),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: url.isEmpty
          ? Text(reel.emoji, style: const TextStyle(fontSize: 16))
          : Image.network(url, fit: BoxFit.cover, width: 36, height: 36,
              errorBuilder: (_, __, ___) => Text(reel.emoji, style: const TextStyle(fontSize: 16))),
    );
  }
}

class _SideAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SideAction({required this.icon, required this.label, required this.onTap, this.color = Colors.white});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: h ? .28 : .16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: F.syne(size: 11, weight: FontWeight.w700, color: Colors.white)),
        ]),
      );
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final String tip;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.tip, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tip,
        child: HoverFx(
          onTap: onTap,
          builder: (h) => Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: h ? .3 : .16), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white),
          ),
        ),
      );
}

class _EmptyReels extends StatelessWidget {
  const _EmptyReels();

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return DecoratedBox(
      decoration: BoxDecoration(gradient: T.grPoster(1)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🎬', style: TextStyle(fontSize: 54)),
          const SizedBox(height: 14),
          Text('Reels from AOneGo9 artists play here',
              textAlign: TextAlign.center,
              style: F.fraunces(size: 20, weight: FontWeight.w700, color: T.posterInk, height: 1.25)),
          const SizedBox(height: 8),
          Text('Every photo and video an artist adds to their profile joins the feed.',
              textAlign: TextAlign.center,
              style: F.syne(size: 13, weight: FontWeight.w400, color: T.posterInkMuted, height: 1.5)),
          const SizedBox(height: 18),
          HoverFx(
            onTap: () {
              Navigator.of(context).maybePop();
              app.openConnect('apply');
            },
            builder: (h) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(color: h ? const Color(0xFFFFB84A) : T.marigold, borderRadius: BorderRadius.circular(30)),
              child: Text('Add your reels →', style: F.syne(size: 13, weight: FontWeight.w800, color: const Color(0xFF2A1404))),
            ),
          ),
        ]),
      ),
    );
  }
}

/// The floating "Reels" button above the bottom bar.
class ReelsPill extends StatelessWidget {
  final VoidCallback onTap;
  const ReelsPill({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Open reels',
        child: HoverFx(
          onTap: onTap,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.fromLTRB(12, 9, 16, 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [T.maroon, Color(0xFFB4462A)]),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: h ? T.marigold : Colors.transparent, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .28), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: T.marigold, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, size: 17, color: Color(0xFF2A1404)),
              ),
              const SizedBox(width: 8),
              Text('Reels', style: F.syne(size: 13, weight: FontWeight.w800, color: T.posterInk)),
            ]),
          ),
        ),
      );
}
