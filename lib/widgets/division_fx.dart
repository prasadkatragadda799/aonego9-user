import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ambient motion for a division block — each one moves the way its trade
/// does, so the eight blocks on "Browse the floor" read as eight rooms rather
/// than eight identical boxes:
///
///   talent       a stage spotlight sweeping across
///   crew         a film strip rolling past, with a shutter flash
///   post         an edit timeline with clips and a moving playhead
///   beauty       powder sparkles twinkling
///   fashion      fabric threads flowing like a drape
///   spaces       a blueprint grid with light passing through arches
///   hospitality  warm steam rising
///   education    steps of a progress chart filling up
///
/// Painted in the division's own accent at low strength so copy on top stays
/// readable. Users who ask their OS to reduce motion get the still frame.
class DivisionFx extends StatefulWidget {
  final String divisionId;
  final Color accent;

  /// 0–1. Hover / press raise it so the block responds to touch.
  final double intensity;

  /// Where the motion should dissolve to nothing — the side the block's copy
  /// sits on, so text is never drawn over a moving pattern. Null = no fade.
  final Alignment? fadeToward;
  const DivisionFx({
    super.key,
    required this.divisionId,
    required this.accent,
    this.intensity = 1,
    this.fadeToward,
  });

  @override
  State<DivisionFx> createState() => _DivisionFxState();
}

class _DivisionFxState extends State<DivisionFx> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _periodMs(widget.divisionId)),
  );

  static int _periodMs(String id) => switch (id) {
        'talent' => 5200,
        'crew' => 4000,
        'post' => 4600,
        'beauty' => 3600,
        'fashion' => 6000,
        'spaces' => 5600,
        'hospitality' => 5000,
        _ => 4800,
      };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.of(context).disableAnimations;
    if (still) {
      _c
        ..stop()
        ..value = .35;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget paint = CustomPaint(
      painter: _FxPainter(widget.divisionId, widget.accent, _c, widget.intensity,
          // Copy at the top → motifs sit low; copy at the bottom → they sit high.
          low: (widget.fadeToward?.y ?? 1) <= 0),
      size: Size.infinite,
    );
    final fade = widget.fadeToward;
    if (fade != null) {
      paint = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => LinearGradient(
          begin: -fade,
          end: fade,
          colors: const [Colors.white, Colors.white, Color(0x00FFFFFF)],
          stops: const [0, .38, .78],
        ).createShader(r),
        child: paint,
      );
    }
    return RepaintBoundary(child: IgnorePointer(child: paint));
  }
}

class _FxPainter extends CustomPainter {
  final String id;
  final Color accent;
  final Animation<double> t;
  final double k;
  final bool low;
  _FxPainter(this.id, this.accent, this.t, this.k, {this.low = false}) : super(repaint: t);

  Color _a(double alpha) => accent.withValues(alpha: (alpha * k).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size s) {
    if (s.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & s);
    switch (id) {
      case 'talent':
        _spotlight(canvas, s);
      case 'crew':
        _filmStrip(canvas, s);
      case 'post':
        _timeline(canvas, s);
      case 'beauty':
        _sparkles(canvas, s);
      case 'fashion':
        _threads(canvas, s);
      case 'spaces':
        _blueprint(canvas, s);
      case 'hospitality':
        _steam(canvas, s);
      default:
        _steps(canvas, s);
    }
    canvas.restore();
  }

  double get v => t.value;

  // ── talent: a cone of stage light swinging over the block ──────────
  void _spotlight(Canvas c, Size s) {
    final swing = math.sin(v * math.pi * 2);
    final cx = s.width * (.5 + .38 * swing);
    final top = Offset(s.width * .5 + swing * s.width * .12, -s.height * .15);
    final path = Path()
      ..moveTo(top.dx - 6, top.dy)
      ..lineTo(top.dx + 6, top.dy)
      ..lineTo(cx + s.width * .26, s.height * 1.05)
      ..lineTo(cx - s.width * .26, s.height * 1.05)
      ..close();
    c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_a(.20), _a(.04)],
        ).createShader(Offset.zero & s),
    );
    // The pool of light on the floor.
    c.drawOval(
      Rect.fromCenter(center: Offset(cx, s.height * .98), width: s.width * .5, height: s.height * .16),
      Paint()..color = _a(.16),
    );
  }

  // ── crew: sprocketed film rolling along the bottom, a shutter flash ─
  void _filmStrip(Canvas c, Size s) {
    final h = math.min(26.0, s.height * .24);
    final y = s.height * (low ? .74 : .30);
    c.drawRect(Rect.fromLTWH(0, y, s.width, h), Paint()..color = _a(.10));
    const gap = 18.0;
    final off = -(v * gap * 4) % gap;
    final hole = Paint()..color = _a(.28);
    for (var x = off; x < s.width + gap; x += gap) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y + 3, 8, 4), const Radius.circular(1)), hole);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y + h - 7, 8, 4), const Radius.circular(1)), hole);
    }
    final frame = Paint()
      ..color = _a(.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const fw = 54.0;
    final foff = -(v * fw * 2) % fw;
    for (var x = foff; x < s.width + fw; x += fw) {
      c.drawRect(Rect.fromLTWH(x + 4, y + 9, fw - 8, h - 18), frame);
    }
    // A brief flash once per loop, like a strobe going off on set.
    final f = ((v - .62) / .08).clamp(0.0, 1.0);
    final flash = f <= 0 || f >= 1 ? 0.0 : math.sin(f * math.pi);
    if (flash > 0) {
      c.drawCircle(
        Offset(s.width * .82, s.height * .28),
        s.width * .35,
        Paint()
          ..shader = RadialGradient(colors: [_a(.22 * flash), _a(0)]).createShader(
            Rect.fromCircle(center: Offset(s.width * .82, s.height * .28), radius: s.width * .35),
          ),
      );
    }
  }

  // ── post: three tracks of clips and a playhead scrubbing across ────
  void _timeline(Canvas c, Size s) {
    final base = s.height * (low ? .70 : .22);
    const th = 7.0;
    final clip = Paint()..color = _a(.18);
    final rnd = math.Random(7);
    for (var track = 0; track < 3; track++) {
      final y = base + track * (th + 6);
      var x = -rnd.nextDouble() * 30;
      while (x < s.width) {
        final w = 24 + rnd.nextDouble() * 50;
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, th), const Radius.circular(2)), clip);
        x += w + 6 + rnd.nextDouble() * 10;
      }
    }
    final px = s.width * v;
    c.drawLine(Offset(px, base - 10), Offset(px, base + 3 * (th + 6)), Paint()
      ..color = _a(.55)
      ..strokeWidth = 1.5);
    c.drawPath(
      Path()
        ..moveTo(px - 5, base - 14)
        ..lineTo(px + 5, base - 14)
        ..lineTo(px, base - 8)
        ..close(),
      Paint()..color = _a(.55),
    );
  }

  // ── beauty: four-point sparkles fading in and out ──────────────────
  void _sparkles(Canvas c, Size s) {
    final rnd = math.Random(3);
    for (var i = 0; i < 9; i++) {
      final p = Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height);
      final phase = (v + i / 9) % 1;
      final a = math.sin(phase * math.pi);
      final r = 3 + rnd.nextDouble() * 5 * a + 1;
      final path = Path()
        ..moveTo(p.dx, p.dy - r * 2)
        ..quadraticBezierTo(p.dx, p.dy, p.dx + r * 2, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + r * 2)
        ..quadraticBezierTo(p.dx, p.dy, p.dx - r * 2, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - r * 2)
        ..close();
      c.drawPath(path, Paint()..color = _a(.08 + .32 * a));
    }
  }

  // ── fashion: drape threads rippling ────────────────────────────────
  void _threads(Canvas c, Size s) {
    for (var i = 0; i < 6; i++) {
      final y0 = s.height * (.25 + i * .12);
      final path = Path()..moveTo(0, y0);
      for (var x = 0.0; x <= s.width; x += 6) {
        final y = y0 + math.sin(x / s.width * math.pi * 2 + v * math.pi * 2 + i * .7) * (6 + i * 1.5);
        path.lineTo(x, y);
      }
      c.drawPath(
        path,
        Paint()
          ..color = _a(.10 + i * .03)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  // ── spaces: blueprint grid, a row of arches, light passing through ─
  void _blueprint(Canvas c, Size s) {
    final grid = Paint()
      ..color = _a(.08)
      ..strokeWidth = 1;
    const step = 16.0;
    for (var x = 0.0; x < s.width; x += step) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), grid);
    }
    for (var y = 0.0; y < s.height; y += step) {
      c.drawLine(Offset(0, y), Offset(s.width, y), grid);
    }
    const archW = 34.0;
    final baseY = s.height - 8;
    final archH = math.min(48.0, s.height * .45);
    final lit = (v * (s.width / archW + 2)).floor() - 1;
    var i = 0;
    for (var x = 6.0; x + archW <= s.width; x += archW + 8, i++) {
      final r = Rect.fromLTWH(x, baseY - archH, archW, archH);
      final path = Path()
        ..moveTo(r.left, r.bottom)
        ..lineTo(r.left, r.top + archW / 2)
        ..arcToPoint(Offset(r.right, r.top + archW / 2), radius: const Radius.circular(archW / 2))
        ..lineTo(r.right, r.bottom);
      if (i == lit || i == lit - 1) {
        c.drawPath(Path.from(path)..close(), Paint()..color = _a(i == lit ? .18 : .09));
      }
      c.drawPath(
        path,
        Paint()
          ..color = _a(.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  // ── hospitality: soft steam rising and dissolving ──────────────────
  void _steam(Canvas c, Size s) {
    for (var i = 0; i < 7; i++) {
      final phase = (v + i / 7) % 1;
      final x = s.width * (.15 + (i * .13) % .75) + math.sin(phase * math.pi * 2 + i) * 8;
      final y = s.height * (1.05 - phase * 1.1);
      final r = 6 + phase * 16;
      c.drawCircle(Offset(x, y), r, Paint()..color = _a(.16 * (1 - phase)));
    }
  }

  // ── education: progress steps filling up, one after another ────────
  void _steps(Canvas c, Size s) {
    const n = 6;
    final w = s.width / (n + 1);
    for (var i = 0; i < n; i++) {
      final full = s.height * (.18 + i * .1);
      final grow = ((v * (n + 2)) - i).clamp(0.0, 1.0);
      final h = full * Curves.easeOut.transform(grow);
      final r = Rect.fromLTWH(w * (i + .5), s.height - h - 6, w * .62, h);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = _a(.10 + i * .03));
    }
    // A mortarboard-like spark at the top of the last finished step.
    final done = ((v * (n + 2)).floor()).clamp(0, n - 1);
    final full = s.height * (.18 + done * .1);
    c.drawCircle(Offset(w * (done + .5) + w * .31, s.height - full - 14), 3.5, Paint()..color = _a(.45));
  }

  @override
  bool shouldRepaint(covariant _FxPainter old) => old.id != id || old.accent != accent || old.k != k || old.low != low;
}
