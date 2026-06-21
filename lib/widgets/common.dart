import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// A `.blk` block card: dark surface, hairline border, rounded.
class Blk extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  const Blk({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.margin = const EdgeInsets.only(bottom: 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: T.card,
        border: Border.all(color: T.bdr),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// `.blk-h` — tiny uppercase tracking-wide header with a trailing hairline.
class BlkHeader extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry margin;
  const BlkHeader(this.text, {super.key, this.margin = const EdgeInsets.only(bottom: 16)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Row(
        children: [
          Text(text.toUpperCase(),
              style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 2)),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: T.bdr)),
        ],
      ),
    );
  }
}

/// `.vsec` / `.vu-sec` — same as BlkHeader but used in vendor screens.
class SecHeader extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry margin;
  const SecHeader(this.text, {super.key, this.margin = const EdgeInsets.only(bottom: 12)});

  @override
  Widget build(BuildContext context) => BlkHeader(text, margin: margin);
}

/// Fade-up entrance animation (mirrors .au / .su keyframes).
class FadeUp extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offset;
  const FadeUp({super.key, required this.child, this.delay = Duration.zero, this.offset = 18});

  @override
  State<FadeUp> createState() => _FadeUpState();
}

class _FadeUpState extends State<FadeUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    return AnimatedBuilder(
      animation: curved,
      builder: (_, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - curved.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Hover-scale / hover-border wrapper that also handles tap.
/// Mirrors the many `:hover { transform / border-color }` CSS rules.
class HoverFx extends StatefulWidget {
  final Widget Function(bool hovering) builder;
  final VoidCallback? onTap;
  const HoverFx({super.key, required this.builder, this.onTap});

  @override
  State<HoverFx> createState() => _HoverFxState();
}

class _HoverFxState extends State<HoverFx> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: widget.builder(_h),
      ),
    );
  }
}

/// Centered emoji over a gradient (used for card imagery / thumbnails).
class GradientArt extends StatelessWidget {
  final int bgIndex;
  final String emoji;
  final double emojiSize;
  final double? height;
  final double opacity;
  final List<Widget> overlay;
  final BorderRadiusGeometry? radius;
  const GradientArt({
    super.key,
    required this.bgIndex,
    required this.emoji,
    this.emojiSize = 80,
    this.height,
    this.opacity = 1,
    this.overlay = const [],
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(gradient: T.gr(bgIndex), borderRadius: radius),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: opacity,
            child: Text(emoji, style: TextStyle(fontSize: emojiSize)),
          ),
          ...overlay,
        ],
      ),
    );
  }
}

/// Returns a short responsive breakpoint helper.
double screenW(BuildContext c) => MediaQuery.of(c).size.width;
bool isNarrow(BuildContext c) => screenW(c) <= 768;
bool isTablet(BuildContext c) => screenW(c) <= 1024;
