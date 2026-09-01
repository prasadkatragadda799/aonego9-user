import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../data/taxonomy.dart';
import '../state/app_state.dart';
import 'brand.dart';
import 'common.dart';

/// Site footer — brand lockup, category + city shortcuts, trust line.
///
/// Every link routes through an existing [AppState] action (`switchCat`,
/// `setLocation`, `setView`), so this adds navigation surface without adding
/// any new behaviour.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final narrow = isNarrow(context);
    final pad = narrow ? 16.0 : 20.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: T.surf,
        border: Border(top: BorderSide(color: T.bdr)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, 44, pad, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 44,
                  runSpacing: 34,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    // ── Brand block ──
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BrandLogo(size: 24, variant: LogoVariant.full),
                          const SizedBox(height: 16),
                          Text(
                            'India\'s curated marketplace for verified talent, crews, studios, '
                            'designers, venues, stays and academies. Browse full portfolios and '
                            'pricing before you reach out.',
                            style: F.syne(size: 12.5, weight: FontWeight.w400, color: T.mut, height: 1.7),
                          ),
                          const SizedBox(height: 14),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: T.grn, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 7),
                            Text('Every listing admin-verified',
                                style: F.syne(size: 11, weight: FontWeight.w600, color: T.grn)),
                          ]),
                        ],
                      ),
                    ),
                    // ── Browse by division ──
                    // Listing all sixteen categories here made the footer
                    // taller than the page; divisions land you in the right
                    // room and the pinned rail takes it from there.
                    _Col(
                      title: 'Divisions',
                      children: [
                        for (final d in divisions)
                          _Link(
                            label: '${d.icon} ${d.name}',
                            active: app.activeDivision == d.id,
                            accent: T.dac(d.id),
                            onTap: () {
                              app.switchDivision(d.id);
                              if (app.view != 'browse') app.backToBrowse();
                            },
                          ),
                      ],
                    ),
                    // ── Cities ──
                    _Col(
                      title: 'Cities',
                      children: [
                        for (final city in AppState.cities)
                          _Link(
                            label: city,
                            active: app.location == city,
                            accent: T.gold,
                            onTap: () => app.setLocation(city),
                          ),
                      ],
                    ),
                    _Col(
                      title: 'Discover',
                      children: [
                        _Link(label: 'Industry news', accent: T.gold, onTap: () => app.setView('newsletter')),
                        _Link(label: 'Events', accent: T.gold, onTap: () => app.setView('events')),
                        _Link(label: 'Workshops & webinars', accent: T.gold, onTap: () => app.setView('sessions')),
                        _Link(label: 'Partners', accent: T.gold, onTap: () => app.setView('partners')),
                        _Link(label: 'About', accent: T.gold, onTap: () => app.setView('about')),
                        _Link(label: 'Our team', accent: T.gold, onTap: () => app.setView('team')),
                      ],
                    ),
                    _Col(
                      title: 'Company',
                      children: [
                        _Link(label: 'Contact us', accent: T.gold, onTap: () => app.openConnect('contact')),
                        _Link(label: 'Join us', accent: T.gold, onTap: () => app.openConnect('join')),
                        _Link(label: 'Apply as artist', accent: T.gold, onTap: () => app.openConnect('apply')),
                        _Link(label: 'List your business', accent: T.gold, onTap: () => app.openConnect('apply')),
                      ],
                    ),
                    _Col(
                      title: 'Account',
                      children: [
                        _Link(
                          label: app.isLoggedIn ? 'My Account' : 'Sign In',
                          accent: T.gold,
                          onTap: () => app.setView('account'),
                        ),
                        _Link(
                          label: 'Subscription',
                          accent: T.gold,
                          onTap: () => app.setView(app.isLoggedIn ? 'subscription' : 'login'),
                        ),
                        _Link(
                          label: 'Vendor portal',
                          accent: T.gold,
                          onTap: () => app.setView('vendor-auth'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Container(height: 1, color: T.bdr),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 18,
                  runSpacing: 10,
                  children: [
                    Text('© ${DateTime.now().year} AOneGo9 — Modeling Agency & Production House',
                        style: F.mono(size: 11, color: T.dim)),
                    Text(
                      app.locationState.isEmpty
                          ? 'Showing availability in ${app.location}'
                          : 'Showing availability in ${app.location}, ${app.locationState}',
                      style: F.mono(size: 11, color: T.dim),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Col extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Col({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title.toUpperCase(),
              style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 2)),
          const SizedBox(height: 14),
          ...children,
        ],
      );
}

class _Link extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  const _Link({required this.label, this.active = false, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Text(
            label,
            style: F.syne(
              size: 12.5,
              weight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? accent : (h ? T.text : T.mut),
            ),
          ),
        ),
      );
}
