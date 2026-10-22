import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aonego9_user/state/app_state.dart';
import 'package:aonego9_user/theme/tokens.dart';
import 'package:aonego9_user/screens/about_screen.dart';
import 'package:aonego9_user/screens/events_screen.dart';
import 'package:aonego9_user/screens/connect_screen.dart';
import 'package:aonego9_user/screens/partners_screen.dart';
import 'package:aonego9_user/screens/newsletter_screen.dart';
import 'package:aonego9_user/screens/sessions_screen.dart';
import 'package:aonego9_user/screens/team_screen.dart';
import 'package:aonego9_user/screens/auth_screen.dart';
import 'package:aonego9_user/screens/vendor_screens.dart';
import 'package:aonego9_user/widgets/app_drawer.dart';
import 'package:aonego9_user/screens/profile_screen.dart';
import 'package:aonego9_user/screens/account_screen.dart';
import 'package:aonego9_user/screens/subscription_screen.dart';
import 'package:aonego9_user/screens/browse_screen.dart';
import 'package:aonego9_user/screens/wedding_screen.dart';

final sample = <String, dynamic>{
  'id': 'x1', 'cat': 'photo', 'name': 'Rhea Kapoor Photography & Films Studio', 'loc': 'Andheri West, Mumbai',
  'tagline': 'Editorial and campaign photography with full lighting crew.', 'badge': 'Top Rated', 'emoji': '📷',
  'rating': 4.8, 'reviewCount': 128, 'verified': true, 'tags': ['Fashion', 'Wedding', 'Product'],
  'price': '₹25,000', 'overview': 'Long overview text ' * 20, 'exp': '8 years', 'langs': 'English, Hindi',
  'stats': [{'n': '320+', 'l': 'Shoots'}, {'n': '8 yrs', 'l': 'Experience'}],
  'services': ['Fashion shoot', 'Product shoot'], 'packages': [], 'gallery': [],
};

/// Every page reachable from the menu must lay out without overflow or
/// framework errors from the smallest phone to desktop.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({});

  final pages = <String, Widget Function()>{
    'browse': () => const BrowseScreen(),
    'wedding': () => const WeddingScreen(),
    'about': () => const AboutScreen(),
    'events': () => const EventsScreen(),
    'connect': () => const ConnectScreen(),
    'partners': () => const PartnersScreen(),
    'newsletter': () => const NewsletterScreen(),
    'sessions': () => const SessionsScreen(),
    'team': () => const TeamScreen(),
    'auth': () => const UserAuth(),
    'vendor': () => const VendorPortalScreen(),
    'drawer': () => const AppDrawer(),
    'profile': () => ProfileScreen(profile: sample),
    'account': () => const AccountScreen(),
    'plans': () => const SubscriptionScreen(),
  };

  for (final w in [320.0, 375.0, 768.0, 1280.0]) {
    for (final e in pages.entries) {
      testWidgets('${e.key} @${w.toInt()}', (tester) async {
        T.applyBrightness(Brightness.light);
        tester.view.physicalSize = Size(w, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final errors = <String>[];
        final old = FlutterError.onError;
        FlutterError.onError = (d) {
          final m = d.exceptionAsString();
          // Fonts are not fetched in tests — not a layout problem.
          if (m.contains('GoogleFonts') || m.contains('font')) return;
          final loc = RegExp(r'lib/[a-z_/]+\.dart:\d+').allMatches(d.toString()).map((x) => x.group(0)).toSet().join(',');
          errors.add('${m.split('\n').first} <$loc>');
        };
        // `.value` so the state outlives the tree: the app never disposes its
        // AppState, and its startup timers would otherwise fire into a
        // disposed notifier and fail the test for a reason users can't hit.
        final app = AppState();
        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: app,
          child: MaterialApp(home: Scaffold(body: e.value())),
        ));
        await tester.pump(const Duration(seconds: 1));
        // Let startup timers (popup delay, toasts) run out.
        await tester.pump(const Duration(seconds: 30));
        FlutterError.onError = old;
        tester.takeException();
        expect(errors.toSet(), isEmpty, reason: '${e.key} @${w.toInt()}');
      });
    }
  }
}
