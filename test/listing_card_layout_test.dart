import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aonego9_user/theme/tokens.dart';
import 'package:aonego9_user/widgets/listing_card.dart';

/// The listing card — portfolio card and directory row — has to lay out
/// without overflow from the smallest phone to the desktop grid, with long
/// names and every optional field present, and each action has to reach its
/// own callback.
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
    'fromPrice': 40000,
    'tags': ['Fashion', 'Wedding', 'Product', 'Editorial', 'Drone'],
  };

  // Card widths the grid produces: a 320 phone (288), the 260 minimum on
  // tablet/desktop, a 375/430 phone, and the widest single column.
  for (final row in [false, true]) {
    for (final width in [260.0, 288.0, 343.0, 398.0, 519.0]) {
      testWidgets('${row ? 'row' : 'card'} lays out at ${width.toInt()}px with no overflow', (tester) async {
        T.applyBrightness(Brightness.light);
        var viewed = 0, enquired = 0, shared = 0, hearted = 0;
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: width,
                  child: ListingCard(
                    item: item,
                    row: row,
                    onView: () => viewed++,
                    onEnquire: () => enquired++,
                    onShare: () => shared++,
                    onShortlist: () => hearted++,
                    availIn: 'Mumbai',
                  ),
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

        for (final f in [
          find.text('Enquire'),
          find.text('Portfolio'),
          find.byIcon(Icons.chat_rounded),
          find.byIcon(Icons.favorite_border_rounded),
        ]) {
          await tester.ensureVisible(f);
          await tester.pumpAndSettle();
          await tester.tap(f);
        }
        expect((enquired, viewed, shared, hearted), (1, 1, 1, 1));
      });
    }
  }

  testWidgets('without the optional callbacks, Enquire opens the profile and extras hide', (tester) async {
    T.applyBrightness(Brightness.light);
    var viewed = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 320, child: ListingCard(item: item, onView: () => viewed++))),
      ),
    ));
    await tester.pump();
    tester.takeException();
    await tester.tap(find.text('Enquire'));
    expect(viewed, 1);
    expect(find.byIcon(Icons.chat_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
  });

  group('ribbon', () {
    test('top rated needs bookings behind the score', () {
      expect(ListingCard.ribbonFor({'rating': 5.0, 'reviewCount': 1}), isNull);
      expect(ListingCard.ribbonFor({'rating': 4.6, 'reviewCount': 12}), 'Top rated');
    });
    test('a paid plan is featured; the starter plan is not', () {
      expect(ListingCard.ribbonFor({'badge': 'Premium'}), 'Featured');
      expect(ListingCard.ribbonFor({'badge': 'Starter'}), isNull);
    });
    test('a profile with no bookings is a new face', () {
      expect(ListingCard.ribbonFor({'isNew': true, 'badge': 'Starter'}), 'New face');
    });
  });

  test('prices shorten to k and lakh', () {
    expect(ListingCard.priceShort(40000), '₹40k');
    expect(ListingCard.priceShort(15500), '₹15.5k');
    expect(ListingCard.priceShort(150000), '₹1.5L');
    expect(ListingCard.priceShort(800), '₹800');
  });
}
