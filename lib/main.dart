import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/tokens.dart';
import 'state/app_state.dart';
import 'screens/browse_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/vendor_screens.dart';
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
        theme: ThemeData(
          scaffoldBackgroundColor: T.bg,
          colorScheme: const ColorScheme.dark(surface: T.bg, primary: T.gold),
          useMaterial3: true,
        ),
        home: const _Root(),
      ),
    );
  }
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
        body = const VendorAuth();
        break;
      case 'vendor-dash':
        body = const VendorDash();
        toastAccent = T.gold;
        break;
      case 'vendor-edit':
        body = const VendorUpload();
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
