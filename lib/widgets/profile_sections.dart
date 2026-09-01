import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../data/profile_extras.dart';
import '../services/link_service.dart';
import '../theme/tokens.dart';
import 'common.dart';
import 'logo_mark.dart';

typedef Toast = void Function(String title, String body, String icon);

/// ── Link in bio ─────────────────────────────────────────────────
/// "Add to URL link bio me — Instagram and other URL link."
class SocialLinksRow extends StatelessWidget {
  final List<SocialLink> links;
  final Color accent;
  final Toast onToast;
  const SocialLinksRow({
    super.key,
    required this.links,
    required this.accent,
    required this.onToast,
  });

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final l in links)
          HoverFx(
            onTap: () async {
              final ok = await LinkService.open(l.url);
              if (!ok) onToast('Could not open', l.url, '⚠️');
            },
            builder: (h) => AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: h ? accent.withValues(alpha: .12) : T.surf,
                border: Border.all(color: h ? accent : T.bdr),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(l.icon, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 7),
                Text(l.label,
                    style: F.syne(size: 12, weight: FontWeight.w700, color: h ? accent : T.text)),
                const SizedBox(width: 6),
                Icon(Icons.north_east_rounded, size: 11, color: h ? accent : T.faint),
              ]),
            ),
          ),
      ],
    );
  }
}

/// ── Awards & achievements ───────────────────────────────────────
class AwardsSection extends StatelessWidget {
  final List<Award> awards;
  final Color accent;
  const AwardsSection({super.key, required this.awards, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (awards.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BlkHeader('Awards & Achievements'),
        for (int i = 0; i < awards.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              border: Border(
                bottom: i == awards.length - 1 ? BorderSide.none : BorderSide(color: T.bdr),
              ),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .12),
                  border: Border.all(color: accent.withValues(alpha: .22)),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text('🏆', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(awards[i].title,
                      style: F.syne(size: 13, weight: FontWeight.w700, color: T.text, height: 1.4)),
                  if (awards[i].issuer.isNotEmpty || awards[i].year.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      [awards[i].issuer, awards[i].year].where((s) => s.isNotEmpty).join(' · '),
                      style: F.syne(size: 11, weight: FontWeight.w600, color: accent),
                    ),
                  ],
                  if (awards[i].note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(awards[i].note,
                        style: F.syne(size: 11.5, weight: FontWeight.w400, color: T.mut, height: 1.55)),
                  ],
                ]),
              ),
            ]),
          ),
      ],
    );
  }
}

/// ── Past work / projects ────────────────────────────────────────
/// "Add to work project links and photo & video & links."
class ProjectsSection extends StatelessWidget {
  final List<WorkProject> projects;
  final Color accent;
  final Toast onToast;
  const ProjectsSection({
    super.key,
    required this.projects,
    required this.accent,
    required this.onToast,
  });

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) return const SizedBox.shrink();
    final cols = screenW(context) <= 640 ? 1 : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BlkHeader('Past Work & Projects'),
        LayoutBuilder(builder: (context, bc) {
          const gap = 11.0;
          final w = (bc.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(spacing: gap, runSpacing: gap, children: [
            for (final p in projects)
              SizedBox(width: w, child: _ProjectCard(project: p, accent: accent, onToast: onToast)),
          ]);
        }),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final WorkProject project;
  final Color accent;
  final Toast onToast;
  const _ProjectCard({required this.project, required this.accent, required this.onToast});

  @override
  Widget build(BuildContext context) {
    final hasLink = project.link.isNotEmpty;
    return HoverFx(
      onTap: hasLink
          ? () async {
              final ok = await LinkService.open(project.link);
              if (!ok) onToast('Could not open', project.link, '⚠️');
            }
          : null,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: T.surf,
          border: Border.all(color: h && hasLink ? accent : T.bdr),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          if (project.hasMedia)
            SizedBox(
              height: 148,
              child: project.videoUrl.isNotEmpty
                  ? MediaTile(
                      item: MediaItem(
                        url: project.videoUrl,
                        thumbUrl: project.imageUrl,
                        isVideo: true,
                        caption: project.title,
                      ),
                      accent: accent,
                      onToast: onToast,
                    )
                  : _stillOrFallback(project.imageUrl),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              if (project.client.isNotEmpty || project.year.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    [project.client, project.year].where((s) => s.isNotEmpty).join(' · ').toUpperCase(),
                    style: F.syne(size: 9.5, weight: FontWeight.w700, color: accent, letterSpacing: 1.3),
                  ),
                ),
              Text(project.title,
                  style: F.syne(size: 13.5, weight: FontWeight.w700, color: T.cream, height: 1.35)),
              if (project.role.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(project.role, style: F.syne(size: 11.5, weight: FontWeight.w600, color: T.mut)),
              ],
              if (project.summary.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(project.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: F.syne(size: 11.5, weight: FontWeight.w400, color: T.mut, height: 1.55)),
              ],
              if (hasLink) ...[
                const SizedBox(height: 9),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Open project',
                      style: F.syne(size: 11, weight: FontWeight.w700, color: h ? accent : T.dim)),
                  const SizedBox(width: 5),
                  Icon(Icons.north_east_rounded, size: 11, color: h ? accent : T.faint),
                ]),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _stillOrFallback(String url) {
    if (url.trim().isEmpty) {
      return Container(
        decoration: BoxDecoration(gradient: T.grPoster(0)),
        alignment: Alignment.center,
        child: const Opacity(opacity: .4, child: Text('🎞️', style: TextStyle(fontSize: 34))),
      );
    }
    return Image.network(
      url.trim(),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        decoration: BoxDecoration(gradient: T.grPoster(0)),
        alignment: Alignment.center,
        child: const Opacity(opacity: .4, child: Text('🎞️', style: TextStyle(fontSize: 34))),
      ),
    );
  }
}

/// ── Brand work ──────────────────────────────────────────────────
/// "Artist profile brand work motion profile division — artist show logo and
/// details work about."
class BrandWorkSection extends StatelessWidget {
  final List<BrandWork> brands;
  final Color accent;
  final Toast onToast;
  const BrandWorkSection({
    super.key,
    required this.brands,
    required this.accent,
    required this.onToast,
  });

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty) return const SizedBox.shrink();

    // Grouped by brand division, because "which categories has this person
    // actually worked in" is the question a booker is asking here.
    final byDivision = <String, List<BrandWork>>{};
    for (final b in brands) {
      byDivision.putIfAbsent(b.division.isEmpty ? 'Other work' : b.division, () => []).add(b);
    }

    final cols = screenW(context) <= 520 ? 1 : (screenW(context) <= 900 ? 2 : 3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BlkHeader('Brand Work'),
        for (final entry in byDivision.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(width: 12, height: 1.5, color: accent),
              const SizedBox(width: 8),
              Text(entry.key.toUpperCase(),
                  style: F.syne(size: 9.5, weight: FontWeight.w700, color: accent, letterSpacing: 1.6)),
            ]),
          ),
          LayoutBuilder(builder: (context, bc) {
            const gap = 10.0;
            final w = (bc.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(spacing: gap, runSpacing: gap, children: [
              for (final b in entry.value)
                SizedBox(width: w, child: _BrandCard(brand: b, accent: accent, onToast: onToast)),
            ]);
          }),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _BrandCard extends StatelessWidget {
  final BrandWork brand;
  final Color accent;
  final Toast onToast;
  const _BrandCard({required this.brand, required this.accent, required this.onToast});

  @override
  Widget build(BuildContext context) {
    final hasLink = brand.link.isNotEmpty;
    return HoverFx(
      onTap: hasLink
          ? () async {
              final ok = await LinkService.open(brand.link);
              if (!ok) onToast('Could not open', brand.link, '⚠️');
            }
          : null,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: T.surf,
          border: Border.all(color: h && hasLink ? accent : T.bdr),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LogoMark(name: brand.brand, logoUrl: brand.logoUrl, size: 44, bg: brand.brand.length % 9),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(brand.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: F.syne(size: 13, weight: FontWeight.w700, color: T.cream)),
              if (brand.work.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(brand.work,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: F.syne(size: 11.5, weight: FontWeight.w400, color: T.mut, height: 1.5)),
              ],
              if (brand.year.isNotEmpty || brand.city.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text([brand.city, brand.year].where((s) => s.isNotEmpty).join(' · '),
                    style: F.mono(size: 10, color: T.dim)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

/// ── Mixed photo + video gallery ─────────────────────────────────
/// "Add to gallery section photos & videos."
class MediaGallerySection extends StatelessWidget {
  final List<MediaItem> media;
  final Color accent;
  final Toast onToast;
  final String title;
  const MediaGallerySection({
    super.key,
    required this.media,
    required this.accent,
    required this.onToast,
    this.title = 'Photos & Videos',
  });

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();
    final videos = media.where((m) => m.isVideo).length;
    final cols = screenW(context) <= 480 ? 2 : (screenW(context) <= 900 ? 3 : 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(children: [
            Text(title.toUpperCase(),
                style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 2)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${media.length - videos} photo · $videos video',
                style: F.mono(size: 9.5, color: accent),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Container(height: 1, color: T.bdr)),
          ]),
        ),
        LayoutBuilder(builder: (context, bc) {
          const gap = 8.0;
          final w = (bc.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(spacing: gap, runSpacing: gap, children: [
            for (int i = 0; i < media.length; i++)
              SizedBox(
                width: w,
                height: w,
                child: HoverFx(
                  onTap: () => _openViewer(context, i),
                  builder: (h) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      border: Border.all(color: h ? accent : T.bdr),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: MediaTile(item: media[i], accent: accent, onToast: onToast, autoplay: false),
                  ),
                ),
              ),
          ]);
        }),
      ],
    );
  }

  void _openViewer(BuildContext context, int index) {
    showDialog<void>(
      context: context,
      barrierColor: T.scrim,
      builder: (_) => _MediaViewer(media: media, index: index, accent: accent, onToast: onToast),
    );
  }
}

/// A single gallery cell. Videos show a poster with a play badge, and play
/// inline once opened — a grid of simultaneously playing videos would saturate
/// the connection and the GPU for no benefit.
class MediaTile extends StatelessWidget {
  final MediaItem item;
  final Color accent;
  final Toast onToast;
  final bool autoplay;
  const MediaTile({
    super.key,
    required this.item,
    required this.accent,
    required this.onToast,
    this.autoplay = false,
  });

  @override
  Widget build(BuildContext context) {
    if (item.isVideo && autoplay) {
      return InlineVideo(url: item.url, posterUrl: item.thumbUrl);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        _poster(),
        if (item.isVideo)
          Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xB309090B),
                border: Border.all(color: accent.withValues(alpha: .7)),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.play_arrow_rounded, size: 22, color: accent),
            ),
          ),
        if (item.caption.isNotEmpty)
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(9, 16, 9, 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xD9000000)],
                ),
              ),
              child: Text(item.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: F.syne(size: 10.5, weight: FontWeight.w600, color: Colors.white)),
            ),
          ),
      ],
    );
  }

  Widget _poster() {
    final url = item.poster;
    if (url.isEmpty) {
      return Container(
        decoration: BoxDecoration(gradient: T.grPoster(item.url.length % 9)),
        alignment: Alignment.center,
        child: Opacity(
          opacity: .35,
          child: Text(item.isVideo ? '🎬' : '🖼️', style: const TextStyle(fontSize: 30)),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        decoration: BoxDecoration(gradient: T.grPoster(item.url.length % 9)),
        alignment: Alignment.center,
        child: Opacity(
          opacity: .35,
          child: Text(item.isVideo ? '🎬' : '🖼️', style: const TextStyle(fontSize: 30)),
        ),
      ),
    );
  }
}

/// Fullscreen viewer with keyboard/arrow navigation.
class _MediaViewer extends StatefulWidget {
  final List<MediaItem> media;
  final int index;
  final Color accent;
  final Toast onToast;
  const _MediaViewer({
    required this.media,
    required this.index,
    required this.accent,
    required this.onToast,
  });

  @override
  State<_MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<_MediaViewer> {
  late int _i = widget.index;

  void _step(int delta) {
    setState(() => _i = (_i + delta) % widget.media.length);
    if (_i < 0) setState(() => _i += widget.media.length);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.media[_i];
    final narrow = isNarrow(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(narrow ? 12 : 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Text('${_i + 1} / ${widget.media.length}', style: F.mono(size: 11, color: T.mut)),
            const Spacer(),
            if (widget.media.length > 1) ...[
              _ViewerBtn(icon: Icons.chevron_left_rounded, onTap: () => _step(-1)),
              const SizedBox(width: 6),
              _ViewerBtn(icon: Icons.chevron_right_rounded, onTap: () => _step(1)),
              const SizedBox(width: 6),
            ],
            _ViewerBtn(icon: Icons.close_rounded, onTap: () => Navigator.of(context).maybePop()),
          ]),
          const SizedBox(height: 12),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 700),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.isVideo
                    ? InlineVideo(url: item.url, posterUrl: item.thumbUrl, controls: true)
                    : Image.network(
                        item.url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          height: 320,
                          decoration: BoxDecoration(gradient: T.grPoster(0)),
                          alignment: Alignment.center,
                          child: Text('Image unavailable', style: F.syne(size: 13, color: T.mut)),
                        ),
                      ),
              ),
            ),
          ),
          if (item.caption.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(item.caption,
                textAlign: TextAlign.center,
                style: F.syne(size: 13, weight: FontWeight.w600, color: T.cream)),
          ],
        ],
      ),
    );
  }
}

class _ViewerBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ViewerBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: h ? T.card : Colors.transparent,
            border: Border.all(color: h ? T.bdhi : T.bdr),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: h ? T.cream : T.mut),
        ),
      );
}

/// Network video with an optional control bar.
///
/// Kept deliberately small: profile reels and ad creatives are short clips,
/// not a media player, so this is play/pause, mute and a progress line rather
/// than a full chrome.
class InlineVideo extends StatefulWidget {
  final String url;
  final String posterUrl;
  final bool controls;
  const InlineVideo({super.key, required this.url, this.posterUrl = '', this.controls = false});

  @override
  State<InlineVideo> createState() => _InlineVideoState();
}

class _InlineVideoState extends State<InlineVideo> {
  VideoPlayerController? _c;
  bool _failed = false;
  bool _muted = true;

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
      c.addListener(_onTick);
      setState(() => _c = c);
    } catch (_) {
      await c.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c?.removeListener(_onTick);
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (_failed || c == null || !c.value.isInitialized) {
      if (widget.posterUrl.trim().isNotEmpty) {
        return Image.network(widget.posterUrl.trim(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder());
      }
      return _placeholder();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: c.value.size.width,
            height: c.value.size.height,
            child: VideoPlayer(c),
          ),
        ),
        if (widget.controls)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xE0000000)],
                ),
              ),
              child: Row(children: [
                _CtlBtn(
                  icon: c.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  onTap: () => c.value.isPlaying ? c.pause() : c.play(),
                ),
                const SizedBox(width: 8),
                _CtlBtn(
                  icon: _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  onTap: () {
                    setState(() => _muted = !_muted);
                    c.setVolume(_muted ? 0 : 1);
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: c.value.duration.inMilliseconds == 0
                          ? 0
                          : c.value.position.inMilliseconds / c.value.duration.inMilliseconds,
                      minHeight: 3,
                      backgroundColor: Colors.white24,
                      color: T.gold,
                    ),
                  ),
                ),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _placeholder() => Container(
        decoration: BoxDecoration(gradient: T.grPoster(0)),
        alignment: Alignment.center,
        child: const Opacity(opacity: .4, child: Text('🎬', style: TextStyle(fontSize: 34))),
      );
}

class _CtlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CtlBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: h ? Colors.white24 : Colors.white10,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      );
}
