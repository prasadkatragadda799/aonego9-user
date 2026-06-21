import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────
/// DESIGN TOKENS — 1:1 port of the original CSS palette.
///
/// Part of the AOneGo9 product line — see ../../../DESIGN_TOKENS.md for the
/// canonical spec. The brand gold (#C9A86C) is byte-identical across the user,
/// vendor and super-admin apps and must never diverge.
/// ─────────────────────────────────────────────
class T {
  static const bg = Color(0xFF09090B); // BG
  static const surf = Color(0xFF101013); // SURF
  static const card = Color(0xFF17171B); // CARD
  static const bdr = Color(0xFF22222A); // BDR
  static const bdhi = Color(0xFF38383E); // BDHI
  static const gold = Color(0xFFC9A86C); // GOLD — brand anchor (shared)
  static const goldLight = Color(0xFFE3CFA3); // shared gold family
  static const goldDark = Color(0xFFA8884A); // shared gold family
  static const cream = Color(0xFFF0EBE0); // CREAM
  static const text = Color(0xFFE4DFD5); // TEXT
  static const mut = Color(0xFF7A7882); // MUT
  static const dim = Color(0xFF484652); // DIM
  static const red = Color(0xFFCC4A4A); // RED — danger (≈ AppColors.danger)
  static const grn = Color(0xFF6AAB88); // GRN — success (≈ AppColors.success)

  /// Category accent colours (CAT_AC).
  static const Map<String, Color> catAccent = {
    'venue': Color(0xFF7DB5A0),
    'photo': Color(0xFFC4B098),
    'video': Color(0xFF7C9EC8),
    'modelF': Color(0xFFC898AA),
    'modelM': Color(0xFF8898B6),
    'events': Color(0xFFC4A870),
  };

  /// ac(id) — accent for a category, defaults to gold.
  static Color ac(String? id) => catAccent[id] ?? gold;

  /// GRS — the rotating diagonal gradient backgrounds.
  static const List<List<Color>> _grs = [
    [Color(0xFF1A1208), bg],
    [Color(0xFF0F1520), bg],
    [Color(0xFF180A14), bg],
    [Color(0xFF0A1218), bg],
    [Color(0xFF121408), bg],
    [Color(0xFF160A0E), bg],
    [Color(0xFF0F0818), bg],
    [Color(0xFF0A1808), bg],
    [Color(0xFF100F18), bg],
  ];

  /// gr(i) — linear-gradient(145deg, …) at index i, wrapping.
  static LinearGradient gr(int i) {
    final c = _grs[i % _grs.length];
    // 145deg in CSS ≈ top-left-ish to bottom-right-ish.
    return LinearGradient(
      begin: const Alignment(-0.5, -1),
      end: const Alignment(0.5, 1),
      colors: c,
    );
  }
}

/// ─────────────────────────────────────────────
/// TYPOGRAPHY — Fraunces (serif display), Syne (sans body), DM Mono.
/// ─────────────────────────────────────────────
class F {
  static TextStyle fraunces({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = T.cream,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );

  static TextStyle syne({
    double size = 13,
    FontWeight weight = FontWeight.w600,
    Color color = T.text,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.syne(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono({
    double size = 11,
    FontWeight weight = FontWeight.w400,
    Color color = T.dim,
    double? letterSpacing,
  }) =>
      GoogleFonts.dmMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );
}
