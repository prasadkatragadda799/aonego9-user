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
import 'widgets/toast.dart';

void main() => runApp(const AOneGo9App());

class AOneGo9App extends StatelessWidget {
  const AOneGo9App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'AOneGo9 — Modeling Agency & Production House',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const _AppScrollBehavior(),
        theme: ThemeData(
          scaffoldBackgroundColor: T.bg,
          colorScheme: const ColorScheme.dark(
            surface: T.bg,
            primary: T.gold,
            onPrimary: T.bg,
            secondary: T.gold,
            error: T.redText,
          ),
          useMaterial3: true,
          // Spinners inherit the brand instead of Material's default blue.
          progressIndicatorTheme: const ProgressIndicatorThemeData(color: T.gold),
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
          dividerTheme: const DividerThemeData(color: T.bdr, thickness: 1, space: 1),
          // Flutter web's default scrollbar is a light overlay — invisible here.
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered) ? T.bdhi : T.bdr,
            ),
            thickness: const WidgetStatePropertyAll(8),
            radius: const Radius.circular(4),
            crossAxisMargin: 2,
          ),
        ),
        home: const _Root(),
      ),
    );
  }
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
      default:
        body = const BrowseScreen();
    }

    return Scaffold(
      backgroundColor: T.bg,
      body: Stack(
        children: [
          Positioned.fill(child: body),
          if (app.toast != null) ToastView(msg: app.toast!, accent: toastAccent),
        ],
      ),
    );
  }
}
