import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/tokens.dart';
import 'state/app_state.dart';
import 'screens/browse_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/vendor_screens.dart';
import 'screens/auth_screen.dart';
import 'screens/account_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/newsletter_screen.dart';
import 'screens/events_screen.dart';
import 'screens/about_screen.dart';
import 'screens/partners_screen.dart';
import 'screens/team_screen.dart';
import 'screens/sessions_screen.dart';
import 'screens/connect_screen.dart';
import 'widgets/app_drawer.dart';
import 'widgets/newsletter_popup.dart';
import 'widgets/toast.dart';

void main() => runApp(const AOneGo9App());

class AOneGo9App extends StatefulWidget {
  const AOneGo9App({super.key});

  @override
  State<AOneGo9App> createState() => _AOneGo9AppState();
}

class _AOneGo9AppState extends State<AOneGo9App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Fires when the OS switches appearance. Without this, a visitor on
  /// "follow system" who flips their phone to dark at dusk keeps the light
  /// palette until the tab is reloaded.
  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, app, _) {
          final platform = WidgetsBinding.instance.platformDispatcher.platformBrightness;
          final brightness = app.resolveBrightness(platform);
          // Tokens are static getters, so the active palette has to be set
          // before anything below reads one. Everything under this Consumer
          // rebuilds on a theme change, so nothing can hold a stale colour.
          T.applyBrightness(brightness);

          return MaterialApp(
            title: 'AOneGo9 — Modeling Agency & Production House',
            debugShowCheckedModeBanner: false,
            scrollBehavior: const _AppScrollBehavior(),
            theme: _themeFor(brightness),
            home: const _Root(),
          );
        },
      ),
    );
  }

  ThemeData _themeFor(Brightness brightness) => ThemeData(
        brightness: brightness,
        scaffoldBackgroundColor: T.bg,
        colorScheme: ColorScheme(
          brightness: brightness,
          surface: T.bg,
          onSurface: T.text,
          primary: T.gold,
          onPrimary: T.onAccent(T.gold),
          secondary: T.gold,
          onSecondary: T.onAccent(T.gold),
          error: T.redText,
          onError: T.onAccent(T.redText),
        ),
        useMaterial3: true,
        // Spinners inherit the brand instead of Material's default blue.
        progressIndicatorTheme: ProgressIndicatorThemeData(color: T.gold),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: T.gold,
          selectionColor: T.gold.withValues(alpha: .28),
          selectionHandleColor: T.gold,
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: T.card,
            border: Border.all(color: T.bdr),
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: F.syne(size: 11, weight: FontWeight.w600, color: T.text),
          waitDuration: const Duration(milliseconds: 400),
        ),
        dividerTheme: DividerThemeData(color: T.bdr, thickness: 1, space: 1),
        drawerTheme: DrawerThemeData(
          backgroundColor: T.surf,
          scrimColor: T.scrim,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        // Flutter web's default scrollbar is a light overlay — invisible on
        // the dark ground and barely there on the light one.
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (st) => st.contains(WidgetState.hovered) ? T.bdhi : T.bdr,
          ),
          thickness: const WidgetStatePropertyAll(8),
          radius: const Radius.circular(4),
          crossAxisMargin: 2,
        ),
      );
}

/// On desktop web the category rail and profile tabs are horizontal scrollers.
/// Flutter only accepts touch drags by default, so a mouse user could see the
/// overflow but not reach it. This enables mouse/trackpad dragging everywhere.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    Widget body;
    Color toastAccent = T.ac(app.activeCat);

    switch (app.view) {
      case 'profile':
        if (app.selectedProfile != null) {
          body = ProfileScreen(profile: app.selectedProfile!);
          toastAccent = T.ac(app.selectedProfile!['cat'] as String?);
        } else {
          body = const BrowseScreen();
        }
        break;
      case 'vendor-auth':
      case 'vendor-dash':
      case 'vendor-edit':
        body = const VendorPortalScreen();
        toastAccent = T.gold;
        break;
      case 'login':
        body = const UserAuth();
        break;
      case 'account':
        body = app.isLoggedIn ? const AccountScreen() : const UserAuth();
        break;
      case 'subscription':
        body = app.isLoggedIn ? const SubscriptionScreen() : const UserAuth();
        break;
      case 'newsletter':
        body = const NewsletterScreen();
        break;
      case 'events':
        body = const EventsScreen();
        break;
      case 'about':
        body = const AboutScreen();
        break;
      case 'partners':
        body = const PartnersScreen();
        break;
      case 'team':
        body = const TeamScreen();
        break;
      case 'sessions':
        body = const SessionsScreen();
        break;
      case 'connect':
        body = const ConnectScreen();
        break;
      default:
        body = const BrowseScreen();
    }

    return Scaffold(
      backgroundColor: T.bg,
      drawer: const AppDrawer(),
      drawerEnableOpenDragGesture: true,
      body: Stack(
        children: [
          Positioned.fill(child: body),
          if (app.showNewsletterPopup && app.view == 'browse') const NewsletterPopup(),
          if (app.toast != null) ToastView(msg: app.toast!, accent: toastAccent),
        ],
      ),
    );
  }
}
