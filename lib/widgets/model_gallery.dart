import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../data/app_data.dart';
import 'common.dart';

Map<String, dynamic> _typeInfo(String t) =>
    portTypes[t] ?? {'label': t, 'color': T.gold.toARGB32(), 'icon': '📸'};

List<String> portfolioImageUrls(Map<String, dynamic> item) {
  final raw = item['images'] as List?;
  if (raw != null && raw.isNotEmpty) {
    return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
  }
  final single = (item['imageUrl'] as String?) ?? (item['image_url'] as String?) ?? '';
  return single.trim().isNotEmpty ? [single.trim()] : const [];
}

/// Renders a portfolio item's cover.
///
/// [fit] defaults to [BoxFit.cover], which is what the uniform grid cells want
/// — every tile fills its square. The lightbox must pass [BoxFit.contain]
/// instead: it shows the photo at full size, and cropping it there would hide
/// exactly the part of the shot the user opened it to see.
Widget portfolioCoverImage(
  Map<String, dynamic> item, {
  double emojiSize = 44,
  int photoIndex = 0,
  BoxFit fit = BoxFit.cover,
}) {
  final urls = portfolioImageUrls(item);
  final url = photoIndex < urls.length ? urls[photoIndex] : (urls.isNotEmpty ? urls.first : '');

  Widget fallback() => Container(
        decoration: BoxDecoration(gradient: T.gr((item['bg'] as int?) ?? 0)),
        alignment: Alignment.center,
        child: Text(item['emoji'] ?? '', style: TextStyle(fontSize: emojiSize)),
      );

  if (url.isNotEmpty) {
    return Image.network(
      url,
      fit: fit,
      // `contain` must size to the available box and letterbox inside it;
      // forcing infinite extents is only right when the image fills the cell.
      width: fit == BoxFit.contain ? null : double.infinity,
      height: fit == BoxFit.contain ? null : double.infinity,
      errorBuilder: (_, __, ___) => fallback(),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        // Full-size portfolio shots are heavy — without this the lightbox is
        // blank while they download, which reads as a broken image.
        final expected = progress.expectedTotalBytes;
        return Center(
          child: SizedBox(
            height: 28,
            width: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: T.gold,
              value: expected != null ? progress.cumulativeBytesLoaded / expected : null,
            ),
          ),
        );
      },
    );
  }
  return Container(
    decoration: BoxDecoration(gradient: T.gr((item['bg'] as int?) ?? 0)),
    alignment: Alignment.center,
    child: Opacity(
      opacity: .55,
      child: Text(item['emoji'] ?? '', style: TextStyle(fontSize: emojiSize)),
    ),
  );
}

/// `ModelGallery` — IG-style portfolio: story filters + 3-col grid + lightbox.
class ModelGallery extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Color accent;
  final void Function(String, String, String) onToast;
  const ModelGallery({super.key, required this.items, required this.accent, required this.onToast});

  @override
  State<ModelGallery> createState() => _ModelGalleryState();
}

class _ModelGalleryState extends State<ModelGallery> {
  String _filter = 'all';

  List<Map<String, dynamic>> get _filtered =>
      _filter == 'all' ? widget.items : widget.items.where((p) => p['type'] == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final activeFilters = storyFilters
        .where((sf) => sf['id'] == 'all' || widget.items.any((p) => p['type'] == sf['id']))
        .toList();
    final filtered = _filtered;

    final w = screenW(context);
    final narrow = w <= 480;
    final cols = narrow ? 2 : 3;
    // 'all' plus a single type filters nothing — both chips show the same
    // posts — so the row is only worth its space once there are 2+ real types.
    final showFilters = activeFilters.length > 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showFilters) ...[
          SizedBox(
            // Story circles are an IG-style flourish that needs room; on a
            // phone they ate 86px of the fold, so there they become chips.
            height: narrow ? 36 : 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: activeFilters.length,
              separatorBuilder: (_, __) => SizedBox(width: narrow ? 8 : 14),
              itemBuilder: (_, i) {
                final sf = activeFilters[i];
                final active = _filter == sf['id'];
                return _StoryButton(
                  icon: sf['icon']!,
                  label: sf['label']!,
                  active: active,
                  compact: narrow,
                  onTap: () => setState(() => _filter = sf['id']!),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          '${filtered.length} post${filtered.length != 1 ? 's' : ''}'
          '${_filter != 'all' ? ' · ${_typeInfo(_filter)['label']}' : ''}',
          style: F.mono(size: 11, color: T.dim),
        ),
        const SizedBox(height: 12),
        // Grid — sized from the caption's real height rather than a fixed
        // aspect ratio. At 2 columns on a 375px phone `.72` left the caption
        // ~61px for ~98px of content, so headlines were sliced in half.
        LayoutBuilder(builder: (context, bc) {
          const gap = 14.0;
          final cellW = (bc.maxWidth - gap * (cols - 1)) / cols;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
              // square cover + caption block
              mainAxisExtent: cellW + _PortCell.captionHeight,
            ),
            itemBuilder: (_, i) => _PortCell(
              item: filtered[i],
              compact: narrow,
              onTap: () => _openLightbox(context, filtered, i),
            ),
          );
        }),
      ],
    );
  }

  void _openLightbox(BuildContext context, List<Map<String, dynamic>> filtered, int index) =>
      openPortfolioLightbox(
        context,
        items: filtered,
        index: index,
        accent: widget.accent,
        onToast: widget.onToast,
      );
}

/// Opens the full-size portfolio viewer.
///
/// Shared by the model Gallery tab and the generic Portfolio tab — the
/// repository maps every portfolio record to both field shapes
/// (`label`/`sub` and `headline`/`desc`/`type`), so the same items drive both.
void openPortfolioLightbox(
  BuildContext context, {
  required List<Map<String, dynamic>> items,
  required int index,
  required Color accent,
  required void Function(String, String, String) onToast,
}) {
  if (items.isEmpty) return;
  showGeneralDialog(
    context: context,
    barrierColor: const Color(0xF2000000),
    barrierDismissible: true,
    barrierLabel: 'lightbox',
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) => _Lightbox(
      items: items,
      start: index.clamp(0, items.length - 1),
      accent: accent,
      onToast: onToast,
    ),
    transitionBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
  );
}

class _StoryButton extends StatelessWidget {
  final String icon, label;
  final bool active;
  final bool compact;
  final VoidCallback onTap;
  const _StoryButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      // Phone form: a filter chip that reads as a filter, matching the ones on
      // the browse screen, instead of a 58px avatar-sized circle.
      return HoverFx(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? T.gold.withValues(alpha: .10) : T.surf,
            border: Border.all(color: active ? T.gold : ((h) ? T.bdhi : T.bdr)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Text(label,
                  maxLines: 1,
                  style: F.syne(
                      size: 12,
                      weight: active ? FontWeight.w700 : FontWeight.w600,
                      color: active ? T.gold : T.mut)),
            ],
          ),
        ),
      );
    }
    return HoverFx(
      onTap: onTap,
      builder: (h) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: active
                  ? LinearGradient(colors: [T.gold, T.gold.withValues(alpha: .4)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : null,
              color: active ? null : T.bdr,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: T.card,
                border: Border.all(color: T.bg, width: 2.5),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: F.syne(size: 10, weight: FontWeight.w600, color: active ? T.gold : T.mut)),
        ],
      ),
    );
  }
}

class _PortCell extends StatelessWidget {
  /// Fixed height of the caption block under the square cover, so the grid can
  /// size each cell as `cellWidth + captionHeight` and nothing gets clipped:
  ///   10 top pad + 18 type pill + 4 + 17 headline + 4 + 33 desc(2 lines) + 12 bottom pad
  static const double captionHeight = 98;

  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final bool compact;
  const _PortCell({required this.item, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final ti = _typeInfo(item['type']);
    final tColor = Color(ti['color'] as int);
    return HoverFx(
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        transform: Matrix4.translationValues(0, h ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: T.card,
          border: Border.all(color: h ? T.gold : T.bdr),
          borderRadius: BorderRadius.circular(10),
          boxShadow: h ? const [BoxShadow(color: Color(0x8C000000), blurRadius: 32, offset: Offset(0, 12))] : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  portfolioCoverImage(item, emojiSize: 44),
                  if (portfolioImageUrls(item).length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xCC09090B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${portfolioImageUrls(item).length}', style: F.mono(size: 10, color: Colors.white)),
                      ),
                    ),
                  if (h)
                    Container(
                      color: const Color(0x7309090B),
                      alignment: Alignment.center,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: .6), width: 1.5),
                        ),
                        child: const Center(child: Text('⤢', style: TextStyle(fontSize: 14, color: Colors.white))),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(6, 2, 8, 2),
                      decoration: BoxDecoration(
                        color: tColor.withValues(alpha: .10),
                        border: Border.all(color: tColor.withValues(alpha: .22)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      // Long type names ("Traditional Ethnic") wrapped to two
                      // lines and burst out of the pill at phone width. In the
                      // narrow 2-column grid the emoji is dropped as well —
                      // those ~18px are the difference between the full label
                      // and "Traditional Eth…".
                      child: Text(compact ? ti['label'] : '${ti['icon']} ${ti['label']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: F.syne(size: 10, weight: FontWeight.w700, color: tColor, letterSpacing: .8)),
                    ),
                    const SizedBox(height: 4),
                    Text(item['headline'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: F.fraunces(size: 13, weight: FontWeight.w700, color: T.text, height: 1.3)),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(item['desc'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: F.syne(size: 11, weight: FontWeight.w400, color: T.mut, height: 1.5)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen lightbox carousel.
class _Lightbox extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int start;
  final Color accent;
  final void Function(String, String, String) onToast;
  const _Lightbox({required this.items, required this.start, required this.accent, required this.onToast});

  @override
  State<_Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<_Lightbox> {
  late int _i = widget.start;
  int _photo = 0;

  Map<String, dynamic> get _item => widget.items[_i];
  List<String> get _photos => portfolioImageUrls(_item);

  void _prev() {
    setState(() {
      if (_photos.length > 1 && _photo > 0) {
        _photo--;
      } else {
        _i = _i > 0 ? _i - 1 : widget.items.length - 1;
        _photo = portfolioImageUrls(widget.items[_i]).length - 1;
        if (_photo < 0) _photo = 0;
      }
    });
  }

  void _next() {
    setState(() {
      if (_photos.length > 1 && _photo < _photos.length - 1) {
        _photo++;
      } else {
        _i = _i < widget.items.length - 1 ? _i + 1 : 0;
        _photo = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final ti = _typeInfo(item['type']);
    final tColor = Color(ti['color'] as int);
    final wide = screenW(context) > 1024;
    final photos = _photos;
    final photoLabel = photos.length > 1 ? '${_photo + 1}/${photos.length}' : '';
    final showArrows = widget.items.length > 1 || photos.length > 1;

    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          // Top bar
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x12FFFFFF)))),
            child: Row(
              children: [
                Text('${ti['icon']} ${ti['label']}',
                    style: F.syne(size: 10, weight: FontWeight.w700, color: tColor, letterSpacing: 2)),
                const Spacer(),
                Text('${_i + 1} / ${widget.items.length}${photoLabel.isNotEmpty ? ' · $photoLabel' : ''}', style: F.mono(size: 11, color: T.dim)),
                const SizedBox(width: 12),
                _RoundBtn(label: '✕', onTap: () => Navigator.of(context).pop()),
              ],
            ),
          ),
          // Main
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inset so the whole photo stays clear of the arrows and
                      // the screen edges — `contain` guarantees nothing is cropped.
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: showArrows ? 72 : 20,
                          vertical: 20,
                        ),
                        child: portfolioCoverImage(item, emojiSize: 120, photoIndex: _photo, fit: BoxFit.contain),
                      ),
                      if (showArrows) ...[
                        Positioned(left: 16, child: _Arrow(label: '‹', onTap: _prev)),
                        Positioned(right: 16, child: _Arrow(label: '›', onTap: _next)),
                      ],
                    ],
                  ),
                ),
                if (wide)
                  Container(
                    width: 320,
                    padding: const EdgeInsets.all(28),
                    decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0x12FFFFFF)))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${ti['icon']} ${ti['label']}',
                            style: F.syne(size: 10, weight: FontWeight.w700, color: tColor, letterSpacing: 2)),
                        const SizedBox(height: 16),
                        Text(item['headline'] ?? '',
                            style: F.fraunces(size: 22, weight: FontWeight.w700, color: T.cream, height: 1.2)),
                        const SizedBox(height: 16),
                        Text(item['desc'] ?? '', style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.7)),
                        const SizedBox(height: 16),
                        Container(height: 1, color: const Color(0x12FFFFFF)),
                        const SizedBox(height: 16),
                        _PanelButton(
                          label: 'Book This Look →',
                          filled: true,
                          accent: widget.accent,
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onToast('Inquiry noted', 'Scroll to send your inquiry', '✅');
                          },
                        ),
                        const SizedBox(height: 6),
                        _PanelButton(
                          label: 'Share Image Link',
                          filled: false,
                          accent: widget.accent,
                          onTap: () => widget.onToast('Link copied', 'Share this portfolio item', '🔗'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Below 1024px the side panel is dropped, which left the shot with no
          // caption at all. Show it under the photo instead so phone users
          // still get the headline and description.
          if (!wide)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x12FFFFFF))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((item['headline'] ?? '').toString().isNotEmpty)
                    Text(item['headline'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: F.fraunces(size: 16, weight: FontWeight.w700, color: T.cream, height: 1.25)),
                  if ((item['desc'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(item['desc'],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: F.syne(size: 12, weight: FontWeight.w400, color: T.mut, height: 1.6)),
                  ],
                ],
              ),
            ),
          // Dots
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int di = 0; di < widget.items.length && di < 12; di++)
                  GestureDetector(
                    onTap: () => setState(() => _i = di),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: di == _i ? 18 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: di == _i ? widget.accent : Colors.white.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _RoundBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: h ? T.gold : Colors.white.withValues(alpha: .15)),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 18, color: h ? T.gold : Colors.white.withValues(alpha: .7)))),
        ),
      );
}

class _Arrow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Arrow({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x99000000),
            border: Border.all(color: h ? T.gold : Colors.white.withValues(alpha: .15)),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 20, color: h ? T.gold : Colors.white.withValues(alpha: .7)))),
        ),
      );
}

class _PanelButton extends StatelessWidget {
  final String label;
  final bool filled;
  final Color accent;
  final VoidCallback onTap;
  const _PanelButton({required this.label, required this.filled, required this.accent, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? accent : Colors.transparent,
            border: filled ? null : Border.all(color: T.bdr),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: F.syne(size: 13, weight: filled ? FontWeight.w700 : FontWeight.w600, color: filled ? T.bg : T.mut)),
        ),
      );
}
