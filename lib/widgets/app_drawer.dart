import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/taxonomy.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import 'brand.dart';
import 'chrome.dart';
import 'common.dart';

/// Left-hand site panel — Newsletter, About, Partners, Events, plus account.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final w = MediaQuery.of(context).size.width;
    final drawerW = w < 420 ? w * 0.88 : 328.0;

    return Drawer(
      width: drawerW,
      backgroundColor: T.surf,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        decoration: BoxDecoration(
          color: T.surf,
          border: Border(right: BorderSide(color: T.bdr)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 16, 18),
                child: Row(
                  children: [
                    const Expanded(child: BrandLogo(size: 22, variant: LogoVariant.full)),
                    HoverFx(
                      onTap: () => Navigator.of(context).maybePop(),
                      builder: (h) => Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: h ? T.bdhi : T.bdr),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.close_rounded, size: 16, color: h ? T.cream : T.mut),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                child: Text(
                  'India\'s curated floor for talent, crews and rooms.',
                  style: F.syne(size: 12, weight: FontWeight.w400, color: T.mut, height: 1.6),
                ),
              ),
              Container(height: 1, color: T.bdr),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
                  children: [
                    const _SectionLabel('Discover'),
                    _Item(
                      icon: Icons.auto_stories_outlined,
                      label: 'Newsletter',
                      hint: 'What\'s happening & trends',
                      active: app.view == 'newsletter',
                      onTap: () => _go(context, app, 'newsletter'),
                    ),
                    _Item(
                      icon: Icons.info_outline_rounded,
                      label: 'About',
                      hint: 'The house & the three modules',
                      active: app.view == 'about',
                      onTap: () => _go(context, app, 'about'),
                    ),
                    _Item(
                      icon: Icons.handshake_outlined,
                      label: 'Partnered with',
                      hint: 'Weeks, guilds, boards',
                      active: app.view == 'partners',
                      onTap: () => _go(context, app, 'partners'),
                    ),
                    _Item(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      hint: 'Castings, open houses, weeks',
                      active: app.view == 'events',
                      onTap: () => _go(context, app, 'events'),
                    ),
                    _Item(
                      icon: Icons.school_outlined,
                      label: 'Workshops & Webinars',
                      hint: 'Clinics, intensives, sessions',
                      active: app.view == 'sessions',
                      onTap: () => _go(context, app, 'sessions'),
                    ),
                    _Item(
                      icon: Icons.groups_outlined,
                      label: 'Our team',
                      hint: 'The desks behind the floor',
                      active: app.view == 'team',
                      onTap: () => _go(context, app, 'team'),
                    ),
                    const SizedBox(height: 18),
                    const _SectionLabel('Marketplace'),
                    _Item(
                      icon: Icons.grid_view_rounded,
                      label: 'Browse',
                      hint: 'Talent, crews, venues',
                      active: app.view == 'browse' || app.view == 'profile',
                      onTap: () {
                        Navigator.of(context).maybePop();
                        app.backToBrowse();
                      },
                    ),
                    _Item(
                      icon: Icons.person_outline_rounded,
                      label: app.isLoggedIn
                          ? (app.currentUser?['name']?.toString().split(' ').first ?? 'Account')
                          : 'Sign in',
                      hint: app.isLoggedIn ? 'Bookings & subscription' : 'Track inquiries',
                      active: app.view == 'account' || app.view == 'login',
                      onTap: () => _go(context, app, 'account'),
                    ),
                    _Item(
                      icon: Icons.storefront_outlined,
                      label: 'Vendor portal',
                      hint: 'List your book',
                      active: app.view.startsWith('vendor'),
                      onTap: () => _go(context, app, 'vendor-auth'),
                    ),
                    const SizedBox(height: 18),
                    const _SectionLabel('Divisions'),
                    // Every division reachable in one tap, with its category
                    // count — the pinned rail only shows one division's
                    // categories at a time, so this is the full map.
                    for (final d in divisions)
                      _Item(
                        emoji: d.icon,
                        label: d.name,
                        hint: d.blurb,
                        accent: T.dac(d.id),
                        active: app.view == 'browse' && app.activeDivision == d.id,
                        onTap: () {
                          Navigator.of(context).maybePop();
                          app.switchDivision(d.id);
                          if (app.view != 'browse') app.backToBrowse();
                        },
                      ),
                    const SizedBox(height: 18),
                    const _SectionLabel('Get in touch'),
                    _Item(
                      icon: Icons.mail_outline_rounded,
                      label: 'Contact us',
                      hint: 'Questions, press, support',
                      active: app.view == 'connect' && app.connectTab == 'contact',
                      onTap: () {
                        Navigator.of(context).maybePop();
                        app.openConnect('contact');
                      },
                    ),
                    _Item(
                      icon: Icons.badge_outlined,
                      label: 'Apply',
                      hint: 'List as artist or vendor',
                      active: app.view == 'connect' && app.connectTab == 'apply',
                      onTap: () {
                        Navigator.of(context).maybePop();
                        app.openConnect('apply');
                      },
                    ),
                    _Item(
                      icon: Icons.diversity_3_outlined,
                      label: 'Join us',
                      hint: 'Work at AOneGo9',
                      active: app.view == 'connect' && app.connectTab == 'join',
                      onTap: () {
                        Navigator.of(context).maybePop();
                        app.openConnect('join');
                      },
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: T.bdr),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('APPEARANCE',
                          style: F.syne(
                              size: 9.5, weight: FontWeight.w700, color: T.dim, letterSpacing: 1.6)),
                    ),
                    const ThemeToggle(),
                    const SizedBox(height: 14),
                    HoverFx(
                      onTap: () => _go(context, app, 'newsletter'),
                      builder: (h) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: h ? T.goldLight : T.gold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          app.newsletterSubscribed ? 'Open the digest' : 'Subscribe to the digest',
                          style: F.syne(size: 13, weight: FontWeight.w700, color: T.bg),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '📍 ${app.location}',
                      textAlign: TextAlign.center,
                      style: F.mono(size: 11, color: T.dim),
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

  void _go(BuildContext context, AppState app, String view) {
    Navigator.of(context).maybePop();
    app.setView(view);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Text(text.toUpperCase(),
          style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 2)),
    );
  }
}

class _Item extends StatelessWidget {
  /// Either [icon] or [emoji] — divisions are identified by their glyph
  /// everywhere else in the app, so they use the emoji form here too.
  final IconData? icon;
  final String? emoji;
  final String label;
  final String hint;
  final bool active;
  /// Null means the brand gold for the active theme.
  final Color? accent;
  final VoidCallback onTap;
  const _Item({
    this.icon,
    this.emoji,
    required this.label,
    required this.hint,
    required this.active,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final accent = this.accent ?? T.gold;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: HoverFx(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: .12)
                : (h ? T.card : Colors.transparent),
            border: Border.all(
              color: active ? accent.withValues(alpha: .45) : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? accent.withValues(alpha: .16) : T.card,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: emoji != null
                    ? Text(emoji!, style: const TextStyle(fontSize: 15))
                    : Icon(icon, size: 17, color: active || h ? accent : T.mut),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: F.syne(size: 13.5, weight: FontWeight.w700, color: active ? accent : T.cream)),
                    const SizedBox(height: 2),
                    Text(hint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: F.syne(size: 11, weight: FontWeight.w400, color: T.dim, height: 1.35)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: active ? accent : T.faint),
            ],
          ),
        ),
      ),
    );
  }
}
