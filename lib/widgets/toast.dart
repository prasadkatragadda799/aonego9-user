import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';

/// `.toast` — bottom-right card with an accent left-border.
class ToastView extends StatelessWidget {
  final ToastMsg msg;
  final Color accent;
  const ToastView({super.key, required this.msg, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 22,
      right: 22,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        tween: Tween(begin: 0, end: 1),
        builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 28 * (1 - v)), child: child),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 290),
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
          decoration: BoxDecoration(
            color: T.card,
            border: Border(
              top: const BorderSide(color: T.bdr),
              right: const BorderSide(color: T.bdr),
              bottom: const BorderSide(color: T.bdr),
              left: BorderSide(color: accent, width: 3),
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(color: Color(0xB3000000), blurRadius: 40, offset: Offset(0, 12))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(msg.i, style: const TextStyle(fontSize: 19)),
              const SizedBox(width: 11),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(msg.t, style: F.syne(size: 13, weight: FontWeight.w700, color: T.text)),
                    const SizedBox(height: 2),
                    Text(msg.b, style: F.syne(size: 11, weight: FontWeight.w400, color: T.mut, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
