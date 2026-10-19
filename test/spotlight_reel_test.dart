import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aonego9_user/data/api_client.dart';
import 'package:aonego9_user/screens/events_screen.dart';
import 'package:aonego9_user/state/app_state.dart';
import 'package:aonego9_user/theme/tokens.dart';
import 'package:aonego9_user/widgets/spotlight_reel.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({});

  Future<AppState> pump(WidgetTester tester, {double width = 390, String? openedDivision}) async {
    T.applyBrightness(Brightness.light);
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = AppState();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: app,
      child: MaterialApp(
        home: Scaffold(body: SpotlightReel(onOpenDivision: (_) {})),
      ),
    ));
    await tester.pump();
    return app;
  }

  Future<void> drain(WidgetTester tester) async {
    // Let AppState's startup timers (popup delay, network) run out.
    await tester.pump(const Duration(seconds: 30));
  }

  testWidgets('with nothing published, house posts fill the reel', (tester) async {
    await pump(tester);
    expect(find.text('See events'), findsOneWidget);
    expect(find.textContaining('AONEGO9 ·'), findsWidgets);
    await drain(tester);
  });

  testWidgets('tapping a house post navigates to its section', (tester) async {
    final app = await pump(tester);
    await tester.tap(find.text('See events'));
    await tester.pump();
    expect(app.view, 'events');
    await drain(tester);
  });

  testWidgets('auto-advances, and the pause control stops it', (tester) async {
    await pump(tester, width: 1280);
    expect(find.text('See events'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 6100));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Apply now'), findsOneWidget, reason: 'second house post after one interval');

    await tester.tap(find.byTooltip('Pause spotlight'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Apply now'), findsOneWidget, reason: 'paused reel stays put');
    await drain(tester);
  });

  testWidgets('an event without its own link opens the booking form', (tester) async {
    final app = await pump(tester);
    final ctx = tester.element(find.byType(SpotlightReel));
    showEventBooking(ctx, app, {'id': 'e1', 'title': 'Monsoon Open Casting', 'date': '2026-11-02', 'city': 'Mumbai'});
    // The reel and its motifs loop forever, so pumpAndSettle never settles —
    // step through the dialog's entrance instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('BOOK A SPOT'), findsOneWidget);
    expect(find.text('Request booking'), findsOneWidget);
    await drain(tester);
  });

  test('list endpoints accept a bare array or a page envelope', () {
    expect(ApiClient.asList([{'a': 1}]).length, 1);
    expect(ApiClient.asList({'items': [{'a': 1}, {'a': 2}]}).length, 2);
    expect(ApiClient.asList({'results': [{'a': 1}]}).length, 1);
    expect(ApiClient.asList({'data': [{'a': 1}]}).length, 1);
    expect(ApiClient.asList({'detail': 'nope'}), isEmpty);
    expect(ApiClient.asList(null), isEmpty);
    expect(ApiClient.asList([1, 'x', {'ok': true}]).length, 1, reason: 'non-object rows are dropped');
  });
}
