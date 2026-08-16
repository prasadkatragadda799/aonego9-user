# Brand assets

## In-app logo

Drop the AOneGo9 master logo here as:

    assets/brand/aonego9_logo.png

Requirements:

- **Transparent background.** The mark is drawn over the app's near-black
  surfaces (`#09090B` / `#101013` / `#17171B`), so a baked-in black box will
  show as a visible rectangle in the nav bar.
- **≥ 1024px wide**, roughly 4x the largest on-screen size, so it stays crisp
  on 3x displays.
- Keep the filename exactly as above — `lib/widgets/brand.dart` looks for it by
  that path and falls back to a native vector wordmark when it is missing.

No code change is needed after adding the file; the next build picks it up.

## Browser tab + installed-app icons

`web/favicon.png` and `web/icons/Icon-{192,512}.png` +
`Icon-maskable-{192,512}.png` are **no longer the stock Flutter artwork**. They
now carry an `A9` monogram — amber `#FFC400` A, cyan `#00BCE0` 9, on the brand
black — drawn in Georgia Bold.

Why a monogram and not the full wordmark: a favicon renders at 16–32px, where
"AoneGo9 / MODELING AGENCY" turns to mush and the logo's hairline serifs
disappear entirely. The two initial glyphs in the two brand accents stay
readable at every size. The full lockup still appears in the nav, the sign-in
card, the footer and the web boot splash.

The maskable variants are full-bleed with the mark inside the centre 72%, since
Android crops them to a circle or squircle.

To regenerate them from the real artwork instead, overwrite these five files at
their exact pixel sizes:

| file | size | notes |
|---|---|---|
| `web/favicon.png` | 64×64 | rounded corners baked in |
| `web/icons/Icon-192.png` | 192×192 | rounded corners baked in |
| `web/icons/Icon-512.png` | 512×512 | rounded corners baked in |
| `web/icons/Icon-maskable-192.png` | 192×192 | square, full bleed, safe zone |
| `web/icons/Icon-maskable-512.png` | 512×512 | square, full bleed, safe zone |

`web/index.html` and `web/manifest.json` already reference all five by these
names, so replacing the files is the only step.
