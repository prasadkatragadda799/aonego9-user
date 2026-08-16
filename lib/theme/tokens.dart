import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────
/// DESIGN TOKENS — 1:1 port of the original CSS palette.
///
/// Part of the AOneGo9 product line — see ../../../DESIGN_TOKENS.md for the
/// canonical spec. The brand gold (#C9A86C) is byte-identical across the user,
/// vendor and super-admin apps and must never diverge.
///
/// TEXT RAMP — every step below clears WCAG AA (4.5:1) against bg/surf/card,
/// which are the only three surfaces body text ever lands on:
///
///           on bg(#09090B)  on surf(#101013)  on card(#17171B)
///   text     17.0:1          16.4:1            15.4:1
///   mut       8.3:1           8.0:1             7.4:1
///   dim       5.7:1           5.5:1             5.1:1
///   faint     2.6:1  ← decorative rules/dividers ONLY, never text
///
/// The former dim (#484652) sat at 2.1:1 on card, which made taglines, tags,
/// field labels, hints and disabled button text effectively invisible. Anything
/// a user must read uses text/mut/dim — never faint.
/// ─────────────────────────────────────────────
class T {
  static const bg = Color(0xFF09090B); // BG
  static const surf = Color(0xFF101013); // SURF
  static const card = Color(0xFF17171B); // CARD
  static const bdr = Color(0xFF272730); // BDR  — raised from #22222A so hairlines read
  static const bdhi = Color(0xFF3E3E46); // BDHI
  static const gold = Color(0xFFC9A86C); // GOLD — brand anchor (shared, never diverges)
  static const goldLight = Color(0xFFE3CFA3); // shared gold family
  static const goldDark = Color(0xFFA8884A); // shared gold family
  static const cream = Color(0xFFF0EBE0); // CREAM
  static const text = Color(0xFFE4DFD5); // TEXT — primary  (15.4:1 on card)
  static const mut = Color(0xFFA8A6B0); // MUT  — secondary ( 7.4:1 on card)
  static const dim = Color(0xFF8A8894); // DIM  — tertiary  ( 5.1:1 on card)
  static const faint = Color(0xFF5C5A66); // FAINT — decorative only, never body text
  // Danger comes in two weights, because one colour cannot serve both jobs:
  //   red     — FILLS and tints. Dark enough that white/near-black sits on it
  //             at 4.5:1 (the ticker's LIVE pill depends on this).
  //   redText — DANGER TEXT on bg/surf/card, where `red` only reached 3.9:1.
  // Reach for redText whenever the colour lands on a glyph, red otherwise.
  static const red = Color(0xFFCC4A4A); // RED — danger fill  (≈ AppColors.danger)
  static const redText = Color(0xFFE88A8A); // 7.2:1 on card
  static const grn = Color(0xFF6AAB88); // GRN — success (6.6:1 as text, 7.4:1 as fill)

  /// ── Literal logo colours ──────────────────────────────────────
  /// Sampled from the AOneGo9 master logo. These exist ONLY to render the
  /// brand mark faithfully — never use them as UI colours. The editorial UI
  /// palette stays anchored on [gold].
  static const logoAmber = Color(0xFFFFC400);
  static const logoCyan = Color(0xFF00BCE0);
  static const logoInk = Color(0xFF000000);

  /// Foreground to use on top of an accent-filled surface (buttons, pills).
  /// Every accent in this system is a light pastel, so near-black always wins —
  /// but this computes it rather than assuming, so a future dark accent is safe.
  static Color onAccent(Color accent) =>
      accent.computeLuminance() > 0.45 ? bg : cream;

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
