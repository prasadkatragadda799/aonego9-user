import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// A partner/brand logo.
///
/// The brief asks for partner and brand walls that "show to logo display".
/// Real artwork is used whenever the desk has uploaded a logo URL. Until then
/// this draws a typographic monogram — the initials set in the display serif
/// on the partner's gradient — rather than a grey box or, worse, a real
/// company's trademark scraped from somewhere.
///
/// The monogram is deterministic, so a partner's mark doesn't change between
/// renders, and it upgrades to the real logo the moment one is published with
/// no call-site change.
class LogoMark extends StatelessWidget {
  final String name;
  final String logoUrl;
  final double size;
  final int bg;

  /// Logos are art, not photos: they are letterboxed inside the tile rather
  /// than cropped, so a wide wordmark isn't sliced in half.
  final EdgeInsets padding;

  const LogoMark({
    super.key,
    required this.name,
    this.logoUrl = '',
    this.size = 56,
    this.bg = 0,
    this.padding = const EdgeInsets.all(8),
  });

  /// Up to two initials — "Lakmé Fashion Week" → LF, "FDCI" → FD.
  String get _initials {
    final words = name
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final w = words.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.22);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: T.gr(bg),
        borderRadius: radius,
        border: Border.all(color: T.bdr),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.trim().isEmpty
          ? _monogram()
          : Padding(
              padding: padding,
              child: Image.network(
                logoUrl.trim(),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _monogram(),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _monogram(),
              ),
            ),
    );
  }

  Widget _monogram() => Center(
        child: Text(
          _initials,
          style: F.fraunces(
            size: size * 0.36,
            weight: FontWeight.w700,
            color: T.gold,
            letterSpacing: 0.5,
          ),
        ),
      );
}
