import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../data/directory.dart';
import '../data/user_repository.dart';
import '../services/link_service.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'common.dart';

/// Display advertising — "video ads & photo ads by display show artist and
/// vendor profile and the AOneGo9 website".
///
/// One slot rotates through the loaded creatives. A photo ad is a still with
/// a headline; a video ad plays inline, muted and looping, which is the only
/// way an autoplaying ad is allowed to behave on the web anyway.
///
/// Clicking through either opens the promoted profile inside the app or the
/// advertiser's site — never both, never a dead end.
class AdSlot extends StatefulWidget {
  /// Restricts the slot to creatives of one media type, when a placement only
  /// makes sense for one (a thin inline strip can't carry video).
  final String? only;
  final double height;
  final EdgeInsetsGeometry margin;

  const AdSlot({
    super.key,
    this.only,
    this.height = 260,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  State<AdSlot> createState() => _AdSlotState();
}

class _AdSlotState extends State<AdSlot> {
  int _index = 0;

  List<AdCreative> _creatives(AppState app) {
    final all = app.ads;
    if (widget.only == null) return all;
    return all.where((a) => a.media == widget.only).toList();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final creatives = _creatives(app);
    if (creatives.isEmpty) return const SizedBox.shrink();

    final ad = creatives[_index % creatives.length];
    final accent = ad.profileCat.isNotEmpty ? T.ac(ad.profileCat) : T.gold;

    return Padding(
      padding: widget.margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: widget.height,
            child: _AdCard(
              key: ValueKey(ad.id),
              ad: ad,
              accent: accent,
              onTap: () => _click(app, ad),
            ),
          ),
          if (creatives.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < creatives.length; i++)
                  HoverFx(
                    onTap: () => setState(() => _index = i),
                    builder: (h) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index % creatives.length ? 20 : 7,
                      height: 4,
                      decoration: BoxDecoration(
                        color: i == _index % creatives.length
                            ? accent
                            : (h ? T.bdhi : T.bdr),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _click(AppState app, AdCreative ad) async {
    if (ad.opensProfile) {
      // Load the real profile rather than trusting the ad's copy of it — an
      // ad can outlive the listing it promotes.
      try {
        final vendor = await UserRepository().vendorProfile(ad.profileId);
        if (!mounted) return;
        app.openVendorById(vendor);
        return;
      } catch (_) {
        if (!mounted) return;
        app.showToast('Listing unavailable', 'That profile is no longer live', '⚠️');
        return;
      }
    }
    if (ad.websiteUrl.isNotEmpty) {
      final ok = await LinkService.open(ad.websiteUrl);
      if (!ok && mounted) {
        app.showToast('Could not open link', ad.websiteUrl, '⚠️');
      }
    }
  }
}

class _AdCard extends StatelessWidget {
  final AdCreative ad;
  final Color accent;
  final VoidCallback onTap;
  const _AdCard({super.key, required this.ad, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    return HoverFx(
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          border: Border.all(color: h ? accent : T.bdr),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ad.isVideo && ad.videoUrl.isNotEmpty)
              _AdVideo(url: ad.videoUrl, posterUrl: ad.imageUrl, bg: ad.bg, emoji: ad.emoji)
            else
              _AdStill(url: ad.imageUrl, bg: ad.bg, emoji: ad.emoji),

            // Scrim so copy stays legible over any creative.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x2209090B), Color(0xF209090B)],
                    stops: [0.25, 1],
                  ),
                ),
              ),
            ),

            // Disclosure. An ad that doesn't say it's an ad is a dark pattern.
            Positioned(
              top: 12,
              left: 12,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xCC09090B),
                    border: Border.all(color: T.bdhi),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('AD',
                      style: F.syne(size: 9, weight: FontWeight.w700, color: T.posterInkMuted, letterSpacing: 1.4)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4)),
                  child: Text(ad.label.toUpperCase(),
                      style: F.syne(size: 9, weight: FontWeight.w700, color: T.bg, letterSpacing: 1.2)),
                ),
              ]),
            ),

            if (ad.isVideo)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xCC09090B),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('▶ VIDEO',
                      style: F.syne(size: 9, weight: FontWeight.w700, color: T.posterInk, letterSpacing: 1.2)),
                ),
              ),

            Positioned(
              left: narrow ? 16 : 24,
              right: narrow ? 16 : 24,
              bottom: narrow ? 16 : 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ad.headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: F.fraunces(
                      size: narrow ? 21 : 27,
                      weight: FontWeight.w700,
                      color: T.posterInk,
                      height: 1.12,
                      letterSpacing: -0.6,
                    ),
                  ),
                  if (ad.sub.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Text(ad.sub,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: F.syne(size: 13, weight: FontWeight.w400, color: T.posterInkMuted, height: 1.5)),
                    ),
                  ],
                  const SizedBox(height: 13),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: h ? accent : Colors.transparent,
                        border: Border.all(color: accent),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        ad.opensProfile ? 'View profile →' : 'Visit AOneGo9 →',
                        style: F.syne(
                            size: 12,
                            weight: FontWeight.w700,
                            color: h ? T.onAccent(accent) : accent),
                      ),
                    ),
                    if (ad.profileName.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          ad.city.isEmpty ? ad.profileName : '${ad.profileName} · ${ad.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: F.mono(size: 11, color: T.posterInkMuted),
                        ),
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

class _AdStill extends StatelessWidget {
  final String url;
  final int bg;
  final String emoji;
  const _AdStill({required this.url, required this.bg, required this.emoji});

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return _fallback();
    return Image.network(
      url.trim(),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
      loadingBuilder: (_, child, p) => p == null ? child : _fallback(),
    );
  }

  Widget _fallback() => Container(
        decoration: BoxDecoration(gradient: T.grPoster(bg)),
        alignment: Alignment.center,
        child: Opacity(opacity: .3, child: Text(emoji, style: const TextStyle(fontSize: 92))),
      );
}

/// Inline video creative — muted, looping, autoplaying.
///
/// Muted is not a style choice: browsers block autoplay with sound, and an
/// unmuted ad that interrupts whatever the visitor is listening to is the
/// fastest way to get the tab closed. A failed initialisation falls back to
/// the still, so a broken CDN never leaves a black rectangle on the page.
class _AdVideo extends StatefulWidget {
  final String url;
  final String posterUrl;
  final int bg;
  final String emoji;
  const _AdVideo({required this.url, required this.posterUrl, required this.bg, required this.emoji});

  @override
  State<_AdVideo> createState() => _AdVideoState();
}

class _AdVideoState extends State<_AdVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) {
      setState(() => _failed = true);
      return;
    }
    final c = VideoPlayerController.networkUrl(uri);
    try {
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      await c.setVolume(0);
      await c.setLooping(true);
      await c.play();
      setState(() => _controller = c);
    } catch (_) {
      await c.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (_failed || c == null || !c.value.isInitialized) {
      return _AdStill(url: widget.posterUrl, bg: widget.bg, emoji: widget.emoji);
    }
    // Cover the slot without distortion — FittedBox scales the video's own
    // aspect ratio up and lets the parent clip the overflow.
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: c.value.size.width,
        height: c.value.size.height,
        child: VideoPlayer(c),
      ),
    );
  }
}
