import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/hub_parts.dart';
import '../widgets/market_search.dart';

/// Wedding planning — one page that gathers every category a wedding books,
/// laid out picture-first: a banner with the search over it, round shortcuts,
/// then "for the bride", a promo, "for the groom" and the pre-wedding shoot.
///
/// Every card opens real AOneGo9 results for the browsing location; nothing
/// here is a separate catalogue.
class WeddingScreen extends StatelessWidget {
  const WeddingScreen({super.key});

  // Festive ground that stays the same in both themes — a wedding page in
  // the app's neutral chrome read as a settings screen.
  static const _maroon = Color(0xFF7A1424);
  static const _rose = Color(0xFFF7D9DF);
  static const _marigold = Color(0xFFF2B33D);

  static const _circles = [
    ('venue', 'Banquets & Venues'),
    ('events', 'Catering & Decor'),
    ('photo', 'Photographers'),
    ('video', 'Wedding Films'),
    ('hotel', 'Guest Stays'),
    ('studio', 'Photo Studios'),
  ];

  static const _bride = [
    ('designer', 'Bridal Wear', '👰'),
    ('jewellery', 'Wedding Jewellery', '💍'),
    ('makeupArtist', 'Bridal Makeup Artists', '💄'),
    ('makeupStudio', 'Bridal Salons & Mehendi', '🌿'),
  ];

  static const _groom = [
    ('clothShop', 'Wedding Suits & Sherwani', '🤵'),
    ('makeupStudio', 'Grooming Salons', '💈'),
    ('jewellery', 'Groom Jewellery', '⌚'),
    ('events', 'Baraat & Entertainment', '🎺'),
  ];

  static const _pre = [
    ('photo', 'Pre-wedding Shoot', '📸'),
    ('video', 'Save-the-date Films', '🎬'),
    ('modelF', 'Bridal Models', '👗'),
    ('editVideo', 'Wedding Video Editors', '✂️'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final narrow = isNarrow(context);
    final pad = narrow ? 16.0 : 20.0;
    void open(String cat) => app.openResults(cat: cat);

    return Container(
      color: T.bg,
      child: Column(children: [
        const AppTopBar(title: 'Wedding Planning'),
        Expanded(
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    HubBanner(
                      colors: const [_maroon, Color(0xFFB2364A), _marigold],
                      motif: 'beauty',
                      motifAccent: _marigold,
                      emojis: '💍 🪔 🌸',
                      title: 'Plan the whole wedding in one place',
                      search: MarketSearch(accent: T.gold),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, 18, pad, 0),
                      child: HubCircles(items: _circles, onOpen: open),
                    ),
                    HubBand(
                      title: 'Wedding planning for the bride',
                      tint: _rose,
                      items: _bride,
                      onOpen: open,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, 22, pad, 0),
                      child: HubPromo(
                        title: 'Choose the best photographers',
                        sub: 'to capture your special moments',
                        emoji: '📸',
                        ground: _maroon,
                        accent: _marigold,
                        glow: const Color(0xFFE0A33A),
                        onTap: () => open('photo'),
                      ),
                    ),
                    HubBand(
                      title: 'Wedding planning for the groom',
                      tint: const Color(0xFFFBE7CF),
                      items: _groom,
                      onOpen: open,
                    ),
                    HubBand(
                      title: 'Pre-wedding planning',
                      tint: const Color(0xFFE6E1F5),
                      items: _pre,
                      onOpen: open,
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ),
          ]),
        ),
        if (narrow) const AppDock(),
      ]),
    );
  }
}
