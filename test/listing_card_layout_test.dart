import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aonego9_user/theme/tokens.dart';
import 'package:aonego9_user/widgets/listing_card.dart';

/// The directory-row listing card has to lay out without overflow from the
/// smallest phone to the two-up desktop grid, with long names and every
/// optional field present.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  final item = <String, dynamic>{
    'id': 'x1',
    'cat': 'photo',
    'name': 'Rhea Kapoor Photography & Films — Wedding, Fashion and Commercial Studio',
    'loc': 'Andheri West, Mumbai, Maharashtra',
    'tagline': 'Editorial and campaign photography with a full in-house lighting crew, '
        'retouching and same-week delivery.',
    'badge': 'Top Rated',
    'emoji': '📷',
    'rating': 4.8,
    'reviewCount': 128,
    'verified': true,
    'isNew': true,
    'tags': ['Fashion', 'Wedding', 'Product', 'Editorial', 'Drone'],
  };

  // Card widths the auto-fill grid produces: a 320 phone (288), the 260
  // minimum on tablet/desktop, a 375/430 phone, and the widest single column
  // before the grid splits in two.
  for (final width in [260.0, 288.0, 343.0, 398.0, 519.0]) {
    testWidgets('lays out at ${width.toInt()}px with no overflow', (tester) async {
      T.applyBrightness(Brightness.light);
      var tapped = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: width,
                child: ListingCard(item: item, onView: () => tapped++, availIn: 'Mumbai'),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      // Font fetches are disabled in tests; anything else thrown — a
      // RenderFlex overflow in particular — fails the test.
      final err = tester.takeException();
      expect(err == null || err.toString().contains('GoogleFonts') || err.toString().contains('font'), isTrue,
          reason: '$err');

      // Both CTAs open the profile.
      for (final label in ['Send a Brief', 'Portfolio']) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
      }
      expect(tapped, 2);
    });
  }
}
