import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────────
/// DESIGN TOKENS — dual theme.
///
/// Part of the AOneGo9 product line. The brand gold family, the type stack
/// and the category hues are shared with the vendor and super-admin apps.
///
/// ── How the theme swap works ─────────────────────────────────────
/// Every colour is a static GETTER over a single mutable [_light] flag rather
/// than a `const`. That is what lets ~850 existing `T.bg` call sites switch
/// theme without being rewritten to take a BuildContext. [applyBrightness] is
/// called at the root before MaterialApp builds, and the whole tree rebuilds
/// on toggle, so no widget can read a stale colour.
///
/// ── Semantic roles (not literal names) ───────────────────────────
///   bg    page ground          card  raised surface
///   surf  sunken band          bdr   hairline
///   cream STRONGEST text  →  near-black in light, near-white in dark
///   text  primary body         mut   secondary        dim   tertiary
///   faint decorative rules ONLY — never text, in either theme
///
/// ── Contrast ─────────────────────────────────────────────────────
/// Every text step clears WCAG AA (4.5:1) against bg, surf AND card in both
/// themes. This is enforced by test/contrast_test.dart, which fails the build
/// rather than trusting the numbers below to stay true.
/// ─────────────────────────────────────────────────────────────────
class T {
  T._();

  static bool _light = false;

  /// True when the light palette is active.
  static bool get isLight => _light;

  /// Point the token set at a brightness. Call before the frame that reads it.
  static void applyBrightness(Brightness b) => _light = b == Brightness.light;

  static Color _p(Color dark, Color light) => _light ? light : dark;

  // ── Surfaces ───────────────────────────────────────────────────
  // Light is warm paper, not clinical white: the display serif and the gold
  // both sit badly on pure #FFF, and the ground carries a slight cream bias
  // toward the brand hue so the palette reads as chosen rather than default.
  static Color get bg => _p(const Color(0xFF09090B), const Color(0xFFFAF8F3));
  static Color get surf => _p(const Color(0xFF101013), const Color(0xFFF2EEE4));
  static Color get card => _p(const Color(0xFF17171B), const Color(0xFFFFFFFF));
  static Color get bdr => _p(const Color(0xFF272730), const Color(0xFFE3DED1));
  static Color get bdhi => _p(const Color(0xFF3E3E46), const Color(0xFFC6BFAD));

  // ── Brand ──────────────────────────────────────────────────────
  /// The immutable brand anchor. Never theme-swapped — this is the colour the
  /// logo and the other two apps are matched to. Use [gold] for UI.
  static const brandGold = Color(0xFFC9A86C);

  /// Gold as a UI colour. #C9A86C is only ~2.0:1 on light paper, so the light
  /// theme uses a deepened gold of the same hue that clears AA as body text
  /// and still reads unmistakably as the brand.
  static Color get gold => _p(brandGold, const Color(0xFF7C5E21));
  static Color get goldLight => _p(const Color(0xFFE3CFA3), const Color(0xFF6B501B));
  static Color get goldDark => _p(const Color(0xFFA8884A), const Color(0xFF664E1B));

  // ── Text ramp ──────────────────────────────────────────────────
  static Color get cream => _p(const Color(0xFFF0EBE0), const Color(0xFF16140F));
  static Color get text => _p(const Color(0xFFE4DFD5), const Color(0xFF232019));
  static Color get mut => _p(const Color(0xFFA8A6B0), const Color(0xFF57534A));
  static Color get dim => _p(const Color(0xFF8A8894), const Color(0xFF6B6659));

  /// Decorative rules and disabled glyphs only — fails AA by design, in both
  /// themes. Anything a user must read uses text/mut/dim.
  static Color get faint => _p(const Color(0xFF5C5A66), const Color(0xFFB4AE9D));

  // ── Status ─────────────────────────────────────────────────────
  // Danger comes in two weights because one colour cannot serve both jobs:
  // `red` is for FILLS and tints, `redText` for danger text on bg/surf/card.
  static Color get red => _p(const Color(0xFFBE3B3B), const Color(0xFFB33224));
  static Color get redText => _p(const Color(0xFFE88A8A), const Color(0xFF9E2A1E));
  static Color get grn => _p(const Color(0xFF6AAB88), const Color(0xFF2C7A4F));

  /// ── Literal logo colours ──────────────────────────────────────
  /// Sampled from the AOneGo9 master logo. These exist ONLY to render the
  /// brand mark faithfully and are identical in both themes.
  static const logoAmber = Color(0xFFFFC400);
  static const logoCyan = Color(0xFF00BCE0);
  static const logoInk = Color(0xFF000000);

  /// The wordmark alternates amber / neutral / cyan. The neutral letters are
  /// white on the dark ground; on paper they have to be ink or half the mark
  /// disappears. Amber and cyan are literal brand colours and never move.
  static Color get logoNeutral => _p(const Color(0xFFFFFFFF), const Color(0xFF17150F));

  /// Foreground for text sitting ON an accent-filled surface.
  ///
  /// Deliberately fixed literals rather than [cream]/[bg]: the right answer
  /// depends only on the accent's own luminance, and pulling theme tokens in
  /// here made a gold button render light-on-light the moment [cream] flipped
  /// to near-black for the light theme.
  static Color onAccent(Color accent) {
    const ink = Color(0xFF14120E);
    const paper = Color(0xFFF6F2E8);
    return _contrast(ink, accent) >= _contrast(paper, accent) ? ink : paper;
  }

  /// WCAG 2.1 relative contrast ratio.
  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// ── Category accents ──────────────────────────────────────────
  /// Authored as light pastels for the dark ground. On paper they land around
  /// 2:1, so the light theme deepens each one through HSL — same hue, same
  /// identity, enough contrast to be read as text. Deriving rather than
  /// hand-listing 18 more hexes keeps the two themes from drifting apart.
  static const Map<String, Color> _catAccentDark = {
    // talent
    'modelF': Color(0xFFC898AA),
    'modelM': Color(0xFF8898B6),
    // production
    'photo': Color(0xFFC4B098),
    'video': Color(0xFF7C9EC8),
    'studio': Color(0xFFA8B8C4),
    'events': Color(0xFFC4A870),
    // post & design
    'editVideo': Color(0xFF8FB0C0),
    'editVfx': Color(0xFFA898C8),
    'edit3d': Color(0xFF7FBAB4),
    'editGraphic': Color(0xFFC8A890),
    // hair & makeup
    'makeupArtist': Color(0xFFD09AA8),
    'makeupStudio': Color(0xFFC0A0B8),
    // fashion & retail
    'designer': Color(0xFFC4A0C0),
    'clothShop': Color(0xFFB8A888),
    'jewellery': Color(0xFFD4BC80),
    // venues
    'venue': Color(0xFF7DB5A0),
    // hospitality
    'hotel': Color(0xFF88B0A0),
    // academy
    'academy': Color(0xFF98A8C8),
  };

  static const Map<String, Color> _divisionAccentDark = {
    'talent': Color(0xFFC898AA),
    'crew': Color(0xFF7C9EC8),
    'post': Color(0xFFA898C8),
    'beauty': Color(0xFFD09AA8),
    'fashion': Color(0xFFC4A0C0),
    'spaces': Color(0xFF7DB5A0),
    'hospitality': Color(0xFF88B0A0),
    'education': Color(0xFF98A8C8),
  };

  /// Deepen a pastel for the light ground: hold the hue, lift saturation so it
  /// does not go muddy at low lightness, then drop lightness to ~33%.
  static Color _forPaper(Color c) {
    final h = HSLColor.fromColor(c);
    return h
        .withSaturation((h.saturation * 1.45).clamp(0.0, 0.62))
        .withLightness(0.30)
        .toColor();
  }

  // Computed once. Rebuilding 26 HSL conversions on every rail frame showed
  // up as jank on the browse screen.
  static final Map<String, Color> _catAccentLight = {
    for (final e in _catAccentDark.entries) e.key: _forPaper(e.value),
  };
  static final Map<String, Color> _divisionAccentLight = {
    for (final e in _divisionAccentDark.entries) e.key: _forPaper(e.value),
  };

  static Map<String, Color> get catAccent => _light ? _catAccentLight : _catAccentDark;
  static Map<String, Color> get divisionAccent =>
      _light ? _divisionAccentLight : _divisionAccentDark;

  /// ac(id) — accent for a category, defaults to gold.
  static Color ac(String? id) => catAccent[id] ?? gold;

  /// dac(id) — accent for a division, defaults to gold.
  static Color dac(String? id) => divisionAccent[id] ?? gold;

  /// ── Gradient grounds ──────────────────────────────────────────
  /// Dark: a deep tint bleeding into the page ground. Light: the same hues at
  /// paper weight, so a card that was a moody wash stays a wash rather than
  /// becoming a flat grey box.
  static const List<Color> _grTintDark = [
    Color(0xFF1A1208), Color(0xFF0F1520), Color(0xFF180A14),
    Color(0xFF0A1218), Color(0xFF121408), Color(0xFF160A0E),
    Color(0xFF0F0818), Color(0xFF0A1808), Color(0xFF100F18),
  ];
  static const List<Color> _grTintLight = [
    Color(0xFFF6EEDF), Color(0xFFE9EEF6), Color(0xFFF6E9F0),
    Color(0xFFE6F0F4), Color(0xFFF1F3E2), Color(0xFFF7E9E9),
    Color(0xFFEFE9F6), Color(0xFFE9F3E6), Color(0xFFECEBF5),
  ];

  /// gr(i) — linear-gradient(145deg, …) at index i, wrapping.
  static LinearGradient gr(int i) {
    final tint = (_light ? _grTintLight : _grTintDark)[i % 9];
    return LinearGradient(
      // 145deg in CSS ≈ top-left-ish to bottom-right-ish.
      begin: const Alignment(-0.5, -1),
      end: const Alignment(0.5, 1),
      colors: [tint, bg],
    );
  }

  /// A gradient that stays DARK in both themes.
  ///
  /// Media surfaces — ad creatives, profile covers, gallery tiles — carry
  /// light copy over a dark scrim because that is what works over an actual
  /// photograph. When there is no photo yet, the placeholder has to stay on
  /// the same side of the contrast line, or the light theme puts white text
  /// on a pale wash.
  static LinearGradient grPoster(int i) => LinearGradient(
        begin: const Alignment(-0.5, -1),
        end: const Alignment(0.5, 1),
        colors: [_grTintDark[i % 9], const Color(0xFF09090B)],
      );

  /// Ink for copy sitting on a poster surface — fixed, never theme-swapped.
  static const posterInk = Color(0xFFF4F1EA);
  static const posterInkMuted = Color(0xFFB8B4AC);

  /// Scrim over imagery, so overlaid copy stays legible on either ground.
  static Color get scrim => _p(const Color(0xF509090B), const Color(0xF2FAF8F3));

  /// Translucent chrome behind pinned headers.
  static Color get chrome => _p(const Color(0xF709090B), const Color(0xF7FAF8F3));
}

/// ─────────────────────────────────────────────
/// TYPOGRAPHY — Fraunces (serif display), Syne (sans body), DM Mono.
/// ─────────────────────────────────────────────
class F {
  static TextStyle fraunces({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: weight,
        color: color ?? T.cream,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );

  static TextStyle syne({
    double size = 13,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.syne(
        fontSize: size,
        fontWeight: weight,
        color: color ?? T.text,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono({
    double size = 11,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
  }) =>
      GoogleFonts.dmMono(
        fontSize: size,
        fontWeight: weight,
        color: color ?? T.dim,
        letterSpacing: letterSpacing,
      );
}
