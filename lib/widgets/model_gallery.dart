import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../data/app_data.dart';
import 'common.dart';

Map<String, dynamic> _typeInfo(String t) =>
    portTypes[t] ?? {'label': t, 'color': T.gold.value, 'icon': '📸'};

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
    final cols = w <= 480 ? 2 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Story-circle filters
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: activeFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final sf = activeFilters[i];
              final active = _filter == sf['id'];
              return _StoryButton(
                icon: sf['icon']!,
                label: sf['label']!,
                active: active,
                onTap: () => setState(() => _filter = sf['id']!),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${filtered.length} post${filtered.length != 1 ? 's' : ''}'
          '${_filter != 'all' ? ' · ${_typeInfo(_filter)['label']}' : ''}',
          style: F.mono(size: 11, color: T.dim),
        ),
        const SizedBox(height: 12),
        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: .72,
          ),
          itemBuilder: (_, i) => _PortCell(
            item: filtered[i],
            onTap: () => _openLightbox(context, filtered, i),
          ),
        ),
      ],
    );
  }

  void _openLightbox(BuildContext context, List<Map<String, dynamic>> filtered, int index) {
    showGeneralDialog(
      context: context,
      barrierColor: const Color(0xF2000000),
      barrierDismissible: true,
      barrierLabel: 'lightbox',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => _Lightbox(
        items: filtered,
        start: index,
        accent: widget.accent,
        onToast: widget.onToast,
      ),
      transitionBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    );
  }
}

class _StoryButton extends StatelessWidget {
  final String icon, label;
  final bool active;
  final VoidCallback onTap;
  const _StoryButton({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                  ? LinearGradient(colors: [T.gold, T.gold.withOpacity(.4)], begin: Alignment.topLeft, end: Alignment.bottomRight)
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
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _PortCell({required this.item, required this.onTap});

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
                  Container(
                    decoration: BoxDecoration(gradient: T.gr((item['bg'] as int?) ?? 0)),
                    alignment: Alignment.center,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 250),
                      scale: h ? 1.08 : 1,
                      child: Opacity(opacity: h ? .7 : .55, child: Text(item['emoji'] ?? '', style: const TextStyle(fontSize: 44))),
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
                          border: Border.all(color: Colors.white.withOpacity(.6), width: 1.5),
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
                      padding: const EdgeInsets.fromLTRB(5, 2, 8, 2),
                      decoration: BoxDecoration(
                        color: tColor.withOpacity(.10),
                        border: Border.all(color: tColor.withOpacity(.22)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${ti['icon']} ${ti['label']}',
                          style: F.syne(size: 9, weight: FontWeight.w700, color: tColor, letterSpacing: 1)),
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

  void _prev() => setState(() => _i = _i > 0 ? _i - 1 : widget.items.length - 1);
  void _next() => setState(() => _i = _i < widget.items.length - 1 ? _i + 1 : 0);

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_i];
    final ti = _typeInfo(item['type']);
    final tColor = Color(ti['color'] as int);
    final wide = screenW(context) > 1024;

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
                Text('${_i + 1} / ${widget.items.length}', style: F.mono(size: 11, color: T.dim)),
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
                      Container(
                        decoration: BoxDecoration(gradient: T.gr(item['bg'] as int? ?? _i)),
                        alignment: Alignment.center,
                        child: Opacity(opacity: .4, child: Text(item['emoji'] ?? '', style: const TextStyle(fontSize: 120))),
                      ),
                      Positioned(left: 16, child: _Arrow(label: '‹', onTap: _prev)),
                      Positioned(right: 16, child: _Arrow(label: '›', onTap: _next)),
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
                        color: di == _i ? widget.accent : Colors.white.withOpacity(.2),
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
            border: Border.all(color: h ? T.gold : Colors.white.withOpacity(.15)),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 18, color: h ? T.gold : Colors.white.withOpacity(.7)))),
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
            border: Border.all(color: h ? T.gold : Colors.white.withOpacity(.15)),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 20, color: h ? T.gold : Colors.white.withOpacity(.7)))),
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
