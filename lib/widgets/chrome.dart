import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import 'common.dart';
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
          child: Text(label, style: F.syne(size: 12, weight: FontWeight.w700, color: T.gold)),
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
    final app = context.watch<AppState>();
    final pad = isNarrow(context) ? 16.0 : 20.0;
    return Container(
      color: T.bg,
      child: Column(
        children: [
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: T.chrome,
              border: Border(bottom: BorderSide(color: T.bdr)),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  child: Row(
                    children: [
                      const MenuBtn(),
                      const SizedBox(width: 10),
                      GhostBtn(
                        label: isNarrow(context) ? '← Browse' : '← Back to Browse',
                        onTap: app.backToBrowse,
                        compact: isNarrow(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: F.syne(size: 13, weight: FontWeight.w700, color: T.text),
                        ),
                      ),
                      ...actions,
                    ],
                  ),
                ),
              ),
            ),
          ),
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
        ],
      ),
    );
  }
}

/// Eyebrow + display title + dek used on editorial pages.
class PageIntro extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String dek;

  /// Null means "the brand gold for the active theme" — it cannot be a
  /// default value now that gold is a theme-dependent getter.
  final Color? accent;
  const PageIntro({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.dek,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final pad = isNarrow(context) ? 16.0 : 24.0;
    final size = (screenW(context) * 0.048).clamp(28.0, 48.0);
    final accent = this.accent ?? T.gold;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, isNarrow(context) ? 28 : 40, pad, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 16, height: 1.5, color: accent),
              const SizedBox(width: 8),
              Text(eyebrow.toUpperCase(),
                  style: F.syne(size: 10, weight: FontWeight.w700, color: accent, letterSpacing: 2.4)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: F.fraunces(size: size, weight: FontWeight.w700, color: T.cream, height: 1.08, letterSpacing: -1.2)),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(dek, style: F.syne(size: 15, weight: FontWeight.w400, color: T.mut, height: 1.7)),
          ),
        ],
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
