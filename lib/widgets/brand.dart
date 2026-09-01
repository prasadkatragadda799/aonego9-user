import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// ─────────────────────────────────────────────
/// BRAND MARK — the AOneGo9 logo.
///
/// Renders bundled artwork, falling back to a native vector wordmark drawn from
/// the same letterforms and the same sampled colours if an asset ever fails to
/// decode. The bundled PNGs are the primary path on purpose: the fallback draws
/// in Fraunces via `google_fonts`, which fetches over the network on web, so a
/// slow or blocked font request would render the brand mark in a substitute
/// typeface. Artwork is deterministic.
///
/// Two files, because the two variants are different lockups — pointing both at
/// one file squashed the tagline into the nav bar:
///
///     assets/brand/aonego9_logo.png     wordmark only        → nav
///     assets/brand/aonego9_lockup.png   wordmark + tagline   → auth, footer
///
/// Replacing either with the real master export needs no code change; keep the
/// filenames and a transparent background, since the mark is drawn over the
/// app's near-black surfaces rather than on a black box. See
/// assets/brand/README.md.
/// ─────────────────────────────────────────────
const String logoAssetPath = 'assets/brand/aonego9_logo.png';
const String logoLockupAssetPath = 'assets/brand/aonego9_lockup.png';

/// How much of the mark to draw.
enum LogoVariant {
  /// Wordmark only — for tight bars like the sticky nav.
  wordmark,

  /// Wordmark + "MODELING AGENCY" lockup — for auth, splash, footer.
  full,
}

class BrandLogo extends StatelessWidget {
  /// Cap height of the wordmark in logical pixels.
  final double size;
  final LogoVariant variant;

  /// Shown under the wordmark in [LogoVariant.full].
  final String tagline;

  const BrandLogo({
    super.key,
    this.size = 20,
    this.variant = LogoVariant.wordmark,
    this.tagline = 'MODELING AGENCY',
  });

  @override
  Widget build(BuildContext context) {
    final full = variant == LogoVariant.full;
    // Each variant gets its own artwork; the vector wordmark is the safety net.
    final height = full ? size * 2.05 : size * 1.18;

    // The master artwork bakes the neutral letters in white, which is right on
    // the dark ground and invisible on paper — half the wordmark disappears.
    // The text lockup below mirrors the same letter colouring and takes its
    // neutral from the theme, so the light theme renders that instead of
    // tinting or plating the PNG.
    if (T.isLight) return _wordmark();

    return Image.asset(
      full ? logoLockupAssetPath : logoAssetPath,
      height: height,
      fit: BoxFit.contain,
      // The mark is downscaled hard (≥1500px source → ~25px in the nav), where
      // `medium` visibly softens Bodoni's hairline serifs.
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => _wordmark(),
      // Keep layout stable while the image decodes so the nav never jumps.
      frameBuilder: (_, child, frame, wasSync) =>
          wasSync || frame != null ? child : SizedBox(height: height),
    );
  }

  Widget _wordmark() {
    // Letter colouring mirrors the master logo: amber A, white "o…e" counters,
    // cyan G, amber "o9" with its swash tail.
    TextStyle mark(Color c) => F.fraunces(
          size: size,
          weight: FontWeight.w700,
          color: c,
          height: 1,
          letterSpacing: -size * 0.045,
        );

    final word = Text.rich(
      TextSpan(children: [
        TextSpan(text: 'A', style: mark(T.logoAmber)),
        TextSpan(text: 'o', style: mark(T.logoNeutral)),
        TextSpan(text: 'n', style: mark(T.logoAmber)),
        TextSpan(text: 'e', style: mark(T.logoNeutral)),
        TextSpan(text: 'G', style: mark(T.logoCyan)),
        TextSpan(text: 'o', style: mark(T.logoNeutral)),
        TextSpan(
          text: '9',
          style: mark(T.logoAmber).copyWith(fontStyle: FontStyle.italic),
        ),
      ]),
      maxLines: 1,
      overflow: TextOverflow.visible,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    );

    if (variant == LogoVariant.wordmark) return word;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        word,
        SizedBox(height: size * 0.28),
        // "MODELING AGENCY" — white with amber E's, as in the master lockup.
        Text.rich(
          TextSpan(
            style: F.syne(
              size: (size * 0.30).clamp(8.0, 14.0),
              weight: FontWeight.w700,
              color: T.logoNeutral,
              letterSpacing: (size * 0.17).clamp(2.0, 6.0),
            ),
            children: _taglineSpans(),
          ),
          maxLines: 1,
        ),
      ],
    );
  }

  /// Splits the tagline so every "E" picks up the amber accent.
  List<TextSpan> _taglineSpans() {
    final spans = <TextSpan>[];
    final buf = StringBuffer();
    void flush() {
      if (buf.isEmpty) return;
      spans.add(TextSpan(text: buf.toString()));
      buf.clear();
    }

    for (final ch in tagline.toUpperCase().split('')) {
      if (ch == 'E') {
        flush();
        spans.add(TextSpan(text: ch, style: const TextStyle(color: T.logoAmber)));
      } else {
        buf.write(ch);
      }
    }
    flush();
    return spans;
  }
}
