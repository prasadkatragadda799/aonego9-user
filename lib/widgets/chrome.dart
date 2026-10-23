import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import 'common.dart';
import 'division_fx.dart';
import 'footer.dart';

void openAppDrawer(BuildContext context) {
  Scaffold.maybeOf(context)?.openDrawer();
}

/// Hamburger that opens the site drawer. Lives in every top bar.
class MenuBtn extends StatelessWidget {
  const MenuBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return HoverFx(
      onTap: () => openAppDrawer(context),
      builder: (h) => Tooltip(
        message: 'Menu',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: h ? T.gold.withValues(alpha: .10) : Colors.transparent,
            border: Border.all(color: h ? T.gold.withValues(alpha: .45) : T.bdr),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.menu_rounded, size: 18, color: h ? T.gold : T.mut),
        ),
      ),
    );
  }
}

class GhostBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool compact;
  const GhostBtn({super.key, required this.label, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 7),
          decoration: BoxDecoration(
            color: T.gold.withValues(alpha: .06),
            border: Border.all(color: T.gold.withValues(alpha: .3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: F.syne(size: 12, weight: FontWeight.w700, color: T.gold)),
        ),
      );
}

class GoldBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const GoldBtn({super.key, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
          child: Text(label, style: F.syne(size: 12, weight: FontWeight.w700, color: T.bg)),
        ),
      );
}

/// Shared inner-page chrome: menu, back, title, optional actions, scroll + footer.
class PageFrame extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool showFooter;
  final bool constrain;
  final double maxWidth;

  const PageFrame({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.showFooter = true,
    this.constrain = true,
    this.maxWidth = 1100,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    return Container(
      color: T.bg,
      child: Column(
        children: [
          AppTopBar(title: title, actions: actions),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: constrain
                      ? Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: body,
                          ),
                        )
                      : body,
                ),
                if (showFooter) const SliverToBoxAdapter(child: SiteFooter()),
              ],
            ),
          ),
          if (narrow) const AppDock(),
        ],
      ),
    );
  }
}

/// Inner-page top bar — menu, back to browse, the page title.
///
/// One component for every inner page (editorial pages, sign-in, vendor) so
/// they cannot drift apart. On a phone the back control is an icon so the
/// title keeps the width; on wider screens it is a labelled button.
class AppTopBar extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final VoidCallback? onBack;
  const AppTopBar({super.key, required this.title, this.actions = const [], this.onBack});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final narrow = isNarrow(context);
    final back = onBack ?? app.backToBrowse;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: T.chrome,
        border: Border(bottom: BorderSide(color: T.bdr)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: narrow ? 12 : 20),
            child: Row(
              children: [
                const MenuBtn(),
                const SizedBox(width: 8),
                if (narrow)
                  Tooltip(
                    message: 'Back to browse',
                    child: HoverFx(
                      onTap: back,
                      builder: (h) => Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: h ? T.gold.withValues(alpha: .10) : Colors.transparent,
                          border: Border.all(color: h ? T.gold.withValues(alpha: .45) : T.bdr),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.arrow_back_rounded, size: 18, color: h ? T.gold : T.mut),
                      ),
                    ),
                  )
                else
                  GhostBtn(label: '← Back to Browse', onTap: back),
                const SizedBox(width: 12),
                Container(width: 6, height: 6, decoration: BoxDecoration(color: T.gold, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: F.fraunces(size: narrow ? 15 : 16, weight: FontWeight.w600, color: T.cream),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Phone-only bottom dock — the same six destinations on every page, as the
/// client's sketch numbers them: Home, News & Media, Artists (talent
/// profiles), Vendors (service providers), Menu and Profile. Browse passes
/// [onHome] to scroll in place; everywhere else it navigates back to browse.
class AppDock extends StatelessWidget {
  final VoidCallback? onHome;
  const AppDock({super.key, this.onHome});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final bottom = MediaQuery.of(context).padding.bottom;
    final v = app.view;
    final onAccount = const {'account', 'login', 'subscription'}.contains(v);
    return Container(
      padding: EdgeInsets.only(bottom: bottom),
      decoration: BoxDecoration(
        color: T.card,
        border: Border(top: BorderSide(color: T.bdr)),
        boxShadow: const [BoxShadow(color: Color(0x1415161A), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: SizedBox(
        height: 60,
        child: Row(children: [
          _DockItem(icon: Icons.home_outlined, label: 'Home', active: v == 'browse', onTap: onHome ?? app.backToBrowse),
          _DockItem(
              icon: Icons.newspaper_rounded,
              label: 'News & Media',
              active: v == 'newsletter',
              onTap: () => app.setView('newsletter')),
          _DockItem(
              icon: Icons.star_outline_rounded,
              label: 'Artists',
              active: v == 'artists',
              onTap: () => app.setView('artists')),
          _DockItem(
              icon: Icons.storefront_outlined,
              label: 'Vendors',
              active: v == 'vendors',
              onTap: () => app.setView('vendors')),
          _DockItem(icon: Icons.menu_rounded, label: 'Menu', onTap: () => openAppDrawer(context)),
          _DockItem(
              icon: app.isLoggedIn ? Icons.person_rounded : Icons.person_outline_rounded,
              label: 'Profile',
              active: onAccount,
              onTap: () => app.setView('account')),
        ]),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _DockItem({required this.icon, required this.label, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Semantics(
          button: true,
          selected: active,
          label: label,
          child: InkResponse(
            onTap: onTap,
            radius: 32,
            highlightColor: Colors.transparent,
            splashColor: T.gold.withValues(alpha: .12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    color: active ? T.gold.withValues(alpha: .12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, size: 21, color: active ? T.gold : T.mut),
                ),
                const SizedBox(height: 3),
                // Six tabs on a 320px phone leave ~53px each; scale a long
                // label down rather than cutting it off.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label,
                        maxLines: 1,
                        style: F.syne(
                            size: 10.5,
                            weight: active ? FontWeight.w700 : FontWeight.w600,
                            color: active ? T.gold : T.mut)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Eyebrow + display title + dek used on editorial pages.
///
/// Set as a banner card with the page's own ambient motif behind it (the same
/// [DivisionFx] vocabulary as "Browse the floor"), dissolving toward the copy
/// so text is never drawn over motion. Each page picks the motif that fits
/// what it is about — film for events, rising steps for workshops, and so on.
class PageIntro extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String dek;

  /// Null means "the brand gold for the active theme" — it cannot be a
  /// default value now that gold is a theme-dependent getter.
  final Color? accent;

  /// Which [DivisionFx] motif plays behind the banner.
  final String motif;
  const PageIntro({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.dek,
    this.accent,
    this.motif = 'talent',
  });

  @override
  Widget build(BuildContext context) {
    final w = screenW(context);
    final narrow = isNarrow(context);
    final size = narrow ? (w < 380 ? 25.0 : 28.0) : (w * 0.04).clamp(32.0, 44.0);
    final accent = this.accent ?? T.gold;
    // No side padding: every page already insets its body, and adding more
    // here left the banner narrower than the content under it.
    return Padding(
      padding: EdgeInsets.fromLTRB(0, narrow ? 16 : 28, 0, 8),
      child: FadeUp(
        offset: 14,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [accent.withValues(alpha: .12), T.card],
            ),
            border: Border.all(color: T.bdr),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          // Phone: the copy spans the full card, so the motif gets its own
          // strip on top instead of running behind the text. Wider: the motif
          // fills the card and dissolves toward the copy on the left.
          child: Stack(
            children: [
              if (narrow)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 64,
                  child: DivisionFx(divisionId: motif, accent: accent, intensity: 1.2, fadeToward: Alignment.bottomCenter),
                )
              else
                Positioned.fill(
                  child: DivisionFx(divisionId: motif, accent: accent, intensity: 1.1, fadeToward: Alignment.centerLeft),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(narrow ? 18 : 28, narrow ? 64 : 30, narrow ? 18 : 28, narrow ? 22 : 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 18, height: 2, color: accent),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(eyebrow.toUpperCase(),
                              maxLines: 2,
                              style: F.syne(
                                  size: narrow ? 9.5 : 10.5,
                                  weight: FontWeight.w800,
                                  color: accent,
                                  letterSpacing: narrow ? 1.4 : 2.2)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Text(title,
                          style: F.fraunces(size: size, weight: FontWeight.w700, color: T.cream, height: 1.15)),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Text(dek,
                          style: F.syne(size: narrow ? 14 : 15, weight: FontWeight.w400, color: T.mut, height: 1.65)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Appearance switch — system / light / dark.
///
/// A three-way segmented control rather than a two-state toggle, because
/// "follow my system" is a real preference and collapsing it into a binary
/// silently overrides what the visitor already told their OS.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  static const _modes = [
    (id: 'system', icon: Icons.brightness_auto_rounded, label: 'Auto'),
    (id: 'light', icon: Icons.light_mode_rounded, label: 'Light'),
    (id: 'dark', icon: Icons.dark_mode_rounded, label: 'Dark'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: T.bg,
        border: Border.all(color: T.bdr),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final m in _modes)
            Expanded(
              child: HoverFx(
                onTap: () => app.setThemeMode(m.id),
                builder: (h) {
                  final active = app.themeMode == m.id;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 170),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? T.gold.withValues(alpha: .16)
                          : (h ? T.card : Colors.transparent),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(m.icon, size: 15, color: active ? T.gold : (h ? T.text : T.dim)),
                        const SizedBox(height: 4),
                        Text(
                          m.label,
                          style: F.syne(
                            size: 10,
                            weight: FontWeight.w700,
                            color: active ? T.gold : (h ? T.text : T.dim),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// One-tap appearance cycle for a crowded toolbar, where the full segmented
/// control does not fit.
class ThemeCycleBtn extends StatelessWidget {
  const ThemeCycleBtn({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final (icon, label) = switch (app.themeMode) {
      'light' => (Icons.light_mode_rounded, 'Light — tap for dark'),
      'dark' => (Icons.dark_mode_rounded, 'Dark — tap to follow system'),
      _ => (Icons.brightness_auto_rounded, 'Following system — tap for light'),
    };
    return Tooltip(
      message: label,
      child: HoverFx(
        onTap: app.cycleThemeMode,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: h ? T.gold.withValues(alpha: .10) : Colors.transparent,
            border: Border.all(color: h ? T.gold.withValues(alpha: .45) : T.bdr),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: h ? T.gold : T.mut),
        ),
      ),
    );
  }
}
