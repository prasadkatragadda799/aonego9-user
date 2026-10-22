import 'dart:async';

import 'package:flutter/material.dart';
import '../data/directory.dart';
import '../data/taxonomy.dart';
import '../screens/events_screen.dart' show showEventBooking;
import '../screens/sessions_screen.dart' show showSessionRegister;
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'ad_slot.dart' show AdStill, AdVideo, openAdCreative;
import 'common.dart';
import 'division_fx.dart';

/// ─────────────────────────────────────────────────────────────────
/// HOME SECTIONS — the blocks of the home page, in the order the client's
/// sketch stacks them:
///
///   [PromoStrip]          slim advertisement strip under the search
///   (spotlight reel)      the big video / poster advertisement
///   [ListingProfiles]     Artists | Business & Vendors, all types
///   [QuickTiles]          Live events, fashion weeks, workshops, castings…
///   [UpdatesFolders]      AOneGo9 — Events / Academic / Updates, photo + video
///   [ServiceProviders]    "Browse service providers" picture grid
///   [ReelsCarousel]       stacked reels — video ads and advertisements
///   [IndustryGrid]        "Types of industry — AOneGo9"
///
/// Text is kept to labels: each block is a picture, an icon or a tile, so the
/// page reads graphically rather than as paragraphs.
/// ─────────────────────────────────────────────────────────────────

/// Individuals — the people who are booked.
const List<String> artistCatIds = [
  'modelF',
  'modelM',
  'photo',
  'video',
  'makeupArtist',
  'designer',
  'editVideo',
  'editVfx',
  'edit3d',
  'editGraphic',
];

/// Businesses — the places and firms that are hired.
const List<String> vendorCatIds = [
  'studio',
  'events',
  'venue',
  'makeupStudio',
  'clothShop',
  'jewellery',
  'hotel',
  'academy',
];

List<Cat> _cats(List<String> ids) => ids.map(catOf).whereType<Cat>().toList();

double _pad(BuildContext c) => isNarrow(c) ? 16.0 : 20.0;

/// Section title with an optional trailing link, shared by every block.
class HomeHeading extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const HomeHeading(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(title,
                style: F.fraunces(
                    size: isNarrow(context) ? 19 : 22, weight: FontWeight.w700, color: T.cream, letterSpacing: -.3)),
          ),
          if (action != null)
            HoverFx(
              onTap: onAction ?? () {},
              builder: (h) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text('$action →',
                    style: F.syne(size: 12.5, weight: FontWeight.w700, color: h ? T.cream : T.gold)),
              ),
            ),
        ],
      );
}

// ── Advertisement strip ─────────────────────────────────────────────

/// One-line advertisement under the search. Paid creatives rotate through it
/// with an AD marker; with none booked it carries AOneGo9's own "list free"
/// call, so the slot is never blank.
class PromoStrip extends StatefulWidget {
  final AppState app;
  const PromoStrip({super.key, required this.app});

  @override
  State<PromoStrip> createState() => _PromoStripState();
}

class _PromoStripState extends State<PromoStrip> {
  Timer? _timer;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && widget.app.ads.length > 1) setState(() => _i++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final ads = app.ads;
    final ad = ads.isEmpty ? null : ads[_i % ads.length];
    return Padding(
      padding: EdgeInsets.fromLTRB(_pad(context), 14, _pad(context), 0),
      child: HoverFx(
        onTap: () => ad == null ? app.openConnect('apply') : openAdCreative(context, app, ad),
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            color: T.card,
            border: Border.all(color: h ? T.gold : T.gold.withValues(alpha: .45)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Row(
              key: ValueKey(ad?.id ?? 'house'),
              children: [
                if (ad != null) ...[
                  _Pill(label: 'AD', color: T.mut),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: ad?.headline ?? (screenW(context) < 420 ? 'List yourself  ' : 'List your profile or business  ')),
                      if (ad == null)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: _Pill(label: 'FREE', color: T.red, filled: true),
                        ),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: F.syne(size: 13.5, weight: FontWeight.w700, color: T.cream),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: T.gold, borderRadius: BorderRadius.circular(6)),
                  child: Text(ad == null ? 'Start now' : (ad.opensProfile ? 'View' : 'Visit'),
                      style: F.syne(size: 12, weight: FontWeight.w800, color: T.onAccent(T.gold))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  const _Pill({required this.label, required this.color, this.filled = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: F.syne(
                size: 9.5, weight: FontWeight.w800, color: filled ? T.onAccent(color) : color, letterSpacing: .8)),
      );
}

// ── Listing profiles: Artists | Business & Vendors ──────────────────

class ListingProfiles extends StatefulWidget {
  final AppState app;
  const ListingProfiles({super.key, required this.app});

  @override
  State<ListingProfiles> createState() => _ListingProfilesState();
}

class _ListingProfilesState extends State<ListingProfiles> {
  bool _vendors = false;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final cats = _cats(_vendors ? vendorCatIds : artistCatIds);
    return Padding(
      padding: EdgeInsets.fromLTRB(_pad(context), 22, _pad(context), 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: BoxDecoration(
          color: T.card,
          border: Border.all(color: T.bdr),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('LISTING PROFILES',
                textAlign: TextAlign.center,
                style: F.syne(size: 10, weight: FontWeight.w800, color: T.dim, letterSpacing: 1.6)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: T.surf, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                _Segment(
                  label: 'Artists',
                  sub: 'All types',
                  icon: Icons.star_rounded,
                  active: !_vendors,
                  onTap: () => setState(() => _vendors = false),
                ),
                _Segment(
                  label: 'Business & Vendors',
                  sub: 'All types',
                  icon: Icons.storefront_rounded,
                  active: _vendors,
                  onTap: () => setState(() => _vendors = true),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, bc) {
              final cols = bc.maxWidth >= 900 ? 8 : (bc.maxWidth >= 560 ? 6 : 4);
              // Room for one "All types" cell after the visible categories.
              final shown = cats.take(cols * 2 - 1).toList();
              final w = bc.maxWidth / cols;
              return Wrap(
                runSpacing: 12,
                children: [
                  for (final c in shown)
                    SizedBox(
                      width: w,
                      child: _IconCell(
                        icon: c.icon,
                        label: c.name,
                        accent: T.ac(c.id),
                        onTap: () => app.openResults(cat: c.id),
                      ),
                    ),
                  SizedBox(
                    width: w,
                    child: _IconCell(
                      material: Icons.expand_more_rounded,
                      label: 'All types',
                      accent: T.gold,
                      onTap: () => showAllCategories(context, app, only: _vendors ? vendorCatIds : artistCatIds),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final String sub;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _Segment({required this.label, required this.sub, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Semantics(
          button: true,
          selected: active,
          child: HoverFx(
            onTap: onTap,
            builder: (h) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: active ? T.gold : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 16, color: active ? T.onAccent(T.gold) : T.mut),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    // Scaled rather than cut: "Business & Vendors" is wider
                    // than half a small phone at full size.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(label,
                          maxLines: 1,
                          style: F.syne(
                              size: 12.5, weight: FontWeight.w800, color: active ? T.onAccent(T.gold) : T.text)),
                    ),
                    Text(sub,
                        maxLines: 1,
                        style: F.syne(
                            size: 10,
                            weight: FontWeight.w600,
                            color: active ? T.onAccent(T.gold).withValues(alpha: .75) : T.dim)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
}

/// Round icon over a two-line label — the directory-style category cell.
class _IconCell extends StatelessWidget {
  final String? icon;
  final IconData? material;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  const _IconCell({this.icon, this.material, required this.label, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: HoverFx(
          onTap: onTap,
          builder: (h) => Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: h ? .22 : .13),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: h ? .7 : .3)),
              ),
              child: material != null
                  ? Icon(material, size: 24, color: accent)
                  : Text(icon!, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: F.syne(size: 11, weight: FontWeight.w600, color: h ? accent : T.text, height: 1.25)),
            ),
          ]),
        ),
      );
}

// ── Quick tiles ─────────────────────────────────────────────────────

class _Tile {
  final String emoji;
  final String label;
  final String motif;
  final void Function(BuildContext, AppState) onTap;
  const _Tile(this.emoji, this.label, this.motif, this.onTap);
}

/// The three-by-three block of shortcuts from the sketch.
class QuickTiles extends StatelessWidget {
  final AppState app;
  const QuickTiles({super.key, required this.app});

  static final _tiles = <_Tile>[
    _Tile('🎤', 'Live Events', 'crew', (c, a) => a.setView('events')),
    _Tile('👠', 'Fashion Weeks', 'fashion', (c, a) => a.setView('events')),
    _Tile('🎓', 'Workshops & Webinars', 'education', (c, a) => a.setView('sessions')),
    _Tile('📣', 'Casting Updates', 'talent', (c, a) => a.setView('newsletter')),
    _Tile('📸', 'Artist Portfolios', 'talent', (c, a) => a.openResults(division: 'talent')),
    _Tile('🏫', 'Academic Programs', 'education', (c, a) => a.openResults(cat: 'academy')),
    _Tile('💍', 'Wedding Planning', 'beauty', (c, a) => a.setView('wedding')),
    _Tile('✚', 'More Options', 'post', (c, a) => showAllCategories(c, a)),
    _Tile('🏢', 'Vendors', 'spaces', (c, a) => showAllCategories(c, a, only: vendorCatIds)),
  ];

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(_pad(context), 14, _pad(context), 0),
      child: LayoutBuilder(builder: (context, bc) {
        final cols = bc.maxWidth >= 900 ? 9 : (bc.maxWidth >= 560 ? 5 : 3);
        const gap = 10.0;
        final w = (bc.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < _tiles.length; i++)
              SizedBox(
                width: w,
                height: narrow ? 92 : 104,
                child: FadeUp(
                  delay: Duration(milliseconds: 30 * i),
                  offset: 10,
                  child: _QuickTile(tile: _tiles[i], onTap: () => _tiles[i].onTap(context, app)),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final _Tile tile;
  final VoidCallback onTap;
  const _QuickTile({required this.tile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = T.dac(tile.motif);
    return Semantics(
      button: true,
      label: tile.label,
      child: HoverFx(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: h ? .26 : .16), T.card],
            ),
            border: Border.all(color: accent.withValues(alpha: h ? .8 : .35)),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            Positioned.fill(
              child: DivisionFx(divisionId: tile.motif, accent: accent, intensity: h ? 1.4 : .8, fadeToward: Alignment.bottomCenter),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 8, 9),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tile.emoji, style: const TextStyle(fontSize: 22)),
                const Spacer(),
                Text(tile.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: F.syne(size: 12, weight: FontWeight.w800, color: T.cream, height: 1.2)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── AOneGo9 updates: Events / Academic / AOneGo9 ────────────────────

class _Post {
  final String tag;
  final String title;
  final String meta;
  final String imageUrl;
  final String videoUrl;
  final String emoji;
  final int bg;
  final void Function(BuildContext, AppState) onTap;
  const _Post({
    required this.tag,
    required this.title,
    required this.onTap,
    this.meta = '',
    this.imageUrl = '',
    this.videoUrl = '',
    this.emoji = '✦',
    this.bg = 0,
  });
}

/// The desk's update folders — photo and video posts, one folder per tab.
class UpdatesFolders extends StatefulWidget {
  final AppState app;
  const UpdatesFolders({super.key, required this.app});

  @override
  State<UpdatesFolders> createState() => _UpdatesFoldersState();
}

class _UpdatesFoldersState extends State<UpdatesFolders> {
  int _tab = 0;
  static const _tabs = ['AOneGo9 · Events', 'AOneGo9 · Academic', 'AOneGo9 · Updates'];

  List<_Post> _posts(AppState app) => switch (_tab) {
        0 => [
            for (final e in app.platformEvents)
              _Post(
                tag: e['on_poster'] == true ? 'On the poster' : 'Event',
                title: '${e['title'] ?? ''}',
                meta: [e['date'], e['city']].where((x) => '${x ?? ''}'.isNotEmpty).join(' · '),
                imageUrl: '${e['image_url'] ?? ''}',
                videoUrl: '${e['video_url'] ?? ''}',
                emoji: '${e['emoji'] ?? '📅'}',
                bg: (e['bg'] as num?)?.toInt() ?? 0,
                onTap: (c, a) => showEventBooking(c, a, e),
              ),
          ],
        1 => [
            for (final s in app.sessions)
              _Post(
                tag: s.isWebinar ? 'Webinar' : 'Workshop',
                title: s.title,
                meta: [s.date, s.city].where((x) => x.isNotEmpty).join(' · '),
                emoji: s.emoji,
                bg: s.bg,
                onTap: (c, a) => showSessionRegister(c, a, s),
              ),
          ],
        _ => [
            for (final n in app.newsletters)
              _Post(
                tag: n.kind == 'trend' ? 'Trend' : 'Update',
                title: n.title,
                meta: [n.date, n.city].where((x) => x.isNotEmpty).join(' · '),
                imageUrl: n.imageUrl ?? '',
                emoji: n.emoji,
                bg: n.bg,
                onTap: (c, a) => a.openIssue(n),
              ),
          ],
      };

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final posts = _posts(app).where((p) => p.title.trim().isNotEmpty).toList();
    final pad = _pad(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 28, pad, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: T.card,
          border: Border.all(color: T.bdr),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeHeading('Updates from AOneGo9'),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (var i = 0; i < _tabs.length; i++) ...[
                  HoverFx(
                    onTap: () => setState(() => _tab = i),
                    builder: (h) => AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _tab == i ? T.cream : (h ? T.surf : Colors.transparent),
                        border: Border.all(color: _tab == i ? T.cream : T.bdhi),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_tabs[i],
                          style: F.syne(
                              size: 12, weight: FontWeight.w700, color: _tab == i ? T.onAccent(T.cream) : T.text)),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 212,
              child: posts.isEmpty
                  ? _EmptyFolder(tab: _tab, app: app)
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: posts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => _PostCard(post: posts[i], onTap: () => posts[i].onTap(context, app)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFolder extends StatelessWidget {
  final int tab;
  final AppState app;
  const _EmptyFolder({required this.tab, required this.app});

  @override
  Widget build(BuildContext context) {
    final (label, go) = switch (tab) {
      0 => ('See the events calendar', () => app.setView('events')),
      1 => ('See workshops & webinars', () => app.setView('sessions')),
      _ => ('Read the digest', () => app.setView('newsletter')),
    };
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(color: T.surf, borderRadius: BorderRadius.circular(10)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.perm_media_outlined, size: 30, color: T.dim),
        const SizedBox(height: 8),
        Text('New photos & videos land here', style: F.syne(size: 13, weight: FontWeight.w600, color: T.mut)),
        const SizedBox(height: 10),
        HoverFx(
          onTap: go,
          builder: (h) => Text('$label →', style: F.syne(size: 12.5, weight: FontWeight.w700, color: h ? T.cream : T.gold)),
        ),
      ]),
    );
  }
}

class _PostCard extends StatelessWidget {
  final _Post post;
  final VoidCallback onTap;
  const _PostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${post.tag}: ${post.title}',
        child: HoverFx(
          onTap: onTap,
          builder: (h) => Container(
            width: 158,
            decoration: BoxDecoration(
              border: Border.all(color: h ? T.gold : T.bdr),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(fit: StackFit.expand, children: [
              AdStill(url: post.imageUrl, bg: post.bg, emoji: post.emoji),
              const _BottomScrim(),
              if (post.videoUrl.isNotEmpty)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.play_circle_fill_rounded, color: T.posterInk, size: 24),
                ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(post.tag.toUpperCase(),
                      style: F.syne(size: 9, weight: FontWeight.w800, color: T.marigold, letterSpacing: 1.2)),
                  const SizedBox(height: 3),
                  Text(post.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: F.syne(size: 12.5, weight: FontWeight.w700, color: T.posterInk, height: 1.25)),
                  if (post.meta.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(post.meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: F.syne(size: 10.5, weight: FontWeight.w500, color: T.posterInkMuted)),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      );
}

class _BottomScrim extends StatelessWidget {
  const _BottomScrim();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [.35, 1],
            colors: [Color(0x0009090B), Color(0xE609090B)],
          ),
        ),
      );
}

// ── Browse service providers ────────────────────────────────────────

/// Picture-card grid of every category — two across on a phone.
class ServiceProviders extends StatelessWidget {
  final AppState app;
  const ServiceProviders({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    final pad = _pad(context);
    final shown = narrow ? catalogue.take(10).toList() : catalogue;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 28, pad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeHeading('Browse service providers', action: 'See all', onAction: () => showAllCategories(context, app)),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, bc) {
            final cols = bc.maxWidth >= 1080 ? 6 : (bc.maxWidth >= 760 ? 4 : (bc.maxWidth >= 520 ? 3 : 2));
            const gap = 12.0;
            final w = (bc.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final c in shown)
                  SizedBox(
                    width: w,
                    child: _CatPictureCard(
                      cat: c,
                      count: app.knownCategoryCount(c.id),
                      onTap: () => app.openResults(cat: c.id),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _CatPictureCard extends StatelessWidget {
  final Cat cat;
  final int? count;
  final VoidCallback onTap;
  const _CatPictureCard({required this.cat, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = T.ac(cat.id);
    return Semantics(
      button: true,
      label: cat.name,
      child: HoverFx(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, h ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: T.card,
            border: Border.all(color: h ? accent : T.bdr),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: h ? .18 : .06), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AspectRatio(
              aspectRatio: 1.25,
              child: Stack(fit: StackFit.expand, children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent.withValues(alpha: .55), accent.withValues(alpha: .12)],
                    ),
                  ),
                ),
                DivisionFx(divisionId: cat.division, accent: T.isLight ? Colors.white : accent, intensity: h ? 1.8 : 1.1, fadeToward: Alignment.bottomRight),
                Center(child: Text(cat.icon, style: TextStyle(fontSize: h ? 50 : 46))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: F.syne(size: 13, weight: FontWeight.w700, color: T.cream)),
                const SizedBox(height: 2),
                Text(count == null ? (divisionById[cat.division]?.name ?? '') : '$count listed',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: F.syne(size: 11, weight: FontWeight.w600, color: accent)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Reels ───────────────────────────────────────────────────────────

class _Reel {
  final String key;
  final String tag;
  final String title;
  final String imageUrl;
  final String videoUrl;
  final String emoji;
  final int bg;
  final String motif;
  final bool disclose;
  final void Function(BuildContext, AppState) onTap;
  const _Reel({
    required this.key,
    required this.tag,
    required this.title,
    required this.onTap,
    this.imageUrl = '',
    this.videoUrl = '',
    this.emoji = '✦',
    this.bg = 0,
    this.motif = 'talent',
    this.disclose = false,
  });
}

/// Stacked, portrait reels — the centre card is full size and plays; the
/// neighbours fan out behind it, as in the sketch's 1st…5th stack.
class ReelsCarousel extends StatefulWidget {
  final AppState app;
  const ReelsCarousel({super.key, required this.app});

  @override
  State<ReelsCarousel> createState() => _ReelsCarouselState();
}

class _ReelsCarouselState extends State<ReelsCarousel> {
  static const _loopBase = 10000;
  PageController? _pc;
  double? _fraction;
  int _page = _loopBase;
  Timer? _timer;
  bool _held = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      final pc = _pc;
      if (_held || pc == null || !pc.hasClients || !mounted) return;
      if (MediaQuery.of(context).disableAnimations) return;
      pc.nextPage(duration: const Duration(milliseconds: 520), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc?.dispose();
    super.dispose();
  }

  PageController _controllerFor(double fraction) {
    if (_pc == null || _fraction != fraction) {
      _pc?.dispose();
      _fraction = fraction;
      _pc = PageController(initialPage: _page, viewportFraction: fraction);
    }
    return _pc!;
  }

  List<_Reel> _reels(AppState app) {
    final real = <_Reel>[
      for (final a in app.ads)
        _Reel(
          key: 'ad-${a.id}',
          tag: a.label.isEmpty ? 'Advertisement' : a.label,
          title: a.headline,
          imageUrl: a.imageUrl,
          videoUrl: a.isVideo ? a.videoUrl : '',
          emoji: a.emoji,
          bg: a.bg,
          disclose: true,
          onTap: (c, s) => openAdCreative(c, s, a),
        ),
      for (final e in app.platformEvents.where((e) => '${e['video_url'] ?? ''}'.isNotEmpty || '${e['image_url'] ?? ''}'.isNotEmpty))
        _Reel(
          key: 'ev-${e['id']}',
          tag: 'Event',
          title: '${e['title'] ?? ''}',
          imageUrl: '${e['image_url'] ?? ''}',
          videoUrl: '${e['video_url'] ?? ''}',
          emoji: '${e['emoji'] ?? '📅'}',
          bg: (e['bg'] as num?)?.toInt() ?? 0,
          motif: 'crew',
          onTap: (c, s) => showEventBooking(c, s, e),
        ),
    ].where((r) => r.title.trim().isNotEmpty).toList();

    // House reels, one per division, keep the stack full until the desk has
    // published enough of its own.
    final house = [
      for (var i = 0; i < divisions.length; i++)
        _Reel(
          key: 'h-${divisions[i].id}',
          tag: 'AOneGo9 · ${divisions[i].name}',
          title: divisions[i].blurb,
          emoji: divisions[i].icon,
          bg: i,
          motif: divisions[i].id,
          onTap: (c, s) => s.openResults(division: divisions[i].id),
        ),
    ];
    return [...real, ...house.take((5 - real.length).clamp(0, house.length))];
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final reels = _reels(app);
    final narrow = isNarrow(context);
    final w = screenW(context);
    final pad = _pad(context);
    final height = narrow ? 380.0 : 440.0;
    // Card width ≈ 9:16 of the height, expressed as a share of the viewport.
    final cardW = height * 9 / 16;
    final fraction = (cardW / (w.clamp(0, 1280) - pad * 2)).clamp(.2, .82);
    final pc = _controllerFor(fraction);
    final current = _page % reels.length;

    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: HomeHeading('Reels', action: 'News & Media', onAction: () => app.setView('newsletter')),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: height,
            child: Listener(
              onPointerDown: (_) => _held = true,
              onPointerUp: (_) => _held = false,
              onPointerCancel: (_) => _held = false,
              child: MouseRegion(
                onEnter: (_) => _held = true,
                onExit: (_) => _held = false,
                child: PageView.builder(
                  controller: pc,
                  padEnds: true,
                  onPageChanged: (p) => setState(() => _page = p),
                  itemBuilder: (context, p) {
                    final r = reels[p % reels.length];
                    return AnimatedBuilder(
                      animation: pc,
                      builder: (context, child) {
                        final pos = pc.position.haveDimensions ? (pc.page ?? _page.toDouble()) : _page.toDouble();
                        final d = (p - pos).abs().clamp(0.0, 2.0);
                        return Transform.scale(
                          scale: 1 - d * .14,
                          child: Opacity(opacity: (1 - d * .3).clamp(.4, 1.0), child: child),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _ReelCard(
                          reel: r,
                          playing: p % reels.length == current && p == _page,
                          onTap: () => r.onTap(context, app),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < reels.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == current ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == current ? T.gold : T.bdhi,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ReelCard extends StatelessWidget {
  final _Reel reel;
  final bool playing;
  final VoidCallback onTap;
  const _ReelCard({required this.reel, required this.playing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = reel;
    final hasMedia = r.imageUrl.isNotEmpty || r.videoUrl.isNotEmpty;
    return Semantics(
      button: true,
      label: '${r.tag}: ${r.title}',
      child: HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: h ? T.gold : Colors.transparent, width: 1.5),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(fit: StackFit.expand, children: [
            if (r.videoUrl.isNotEmpty && playing)
              AdVideo(url: r.videoUrl, posterUrl: r.imageUrl, bg: r.bg, emoji: r.emoji)
            else if (hasMedia)
              AdStill(url: r.imageUrl, bg: r.bg, emoji: r.emoji)
            else ...[
              DecoratedBox(decoration: BoxDecoration(gradient: T.grPoster(r.bg))),
              DivisionFx(divisionId: r.motif, accent: T.marigold, intensity: 2.2, fadeToward: Alignment.bottomCenter),
              Align(
                alignment: const Alignment(0, -.25),
                child: Text(r.emoji, style: const TextStyle(fontSize: 64)),
              ),
            ],
            const _BottomScrim(),
            Positioned(
              top: 10,
              left: 10,
              child: Row(children: [
                Icon(r.videoUrl.isNotEmpty ? Icons.play_circle_fill_rounded : Icons.movie_filter_rounded,
                    size: 18, color: T.posterInk),
                if (r.disclose) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      border: Border.all(color: T.posterInk),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text('AD', style: F.syne(size: 9, weight: FontWeight.w800, color: T.posterInk)),
                  ),
                ],
              ]),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 14,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.tag.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: F.syne(size: 9.5, weight: FontWeight.w800, color: T.marigold, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(r.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: F.syne(size: 14, weight: FontWeight.w700, color: T.posterInk, height: 1.3)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Types of industry ───────────────────────────────────────────────

class IndustryGrid extends StatelessWidget {
  final AppState app;
  const IndustryGrid({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final pad = _pad(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 30, pad, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: T.card,
          border: Border.all(color: T.bdr),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeHeading('Types of industry', action: 'More', onAction: () => showAllCategories(context, app)),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, bc) {
              final cols = bc.maxWidth >= 640 ? 8 : 4;
              final w = bc.maxWidth / cols;
              return Wrap(
                runSpacing: 14,
                children: [
                  for (final d in divisions)
                    SizedBox(
                      width: w,
                      child: _IconCell(
                        icon: d.icon,
                        label: d.name,
                        accent: T.dac(d.id),
                        onTap: () => app.openResults(division: d.id),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Sheets ──────────────────────────────────────────────────────────

/// Every category, grouped by division — the "More" and "All types" target.
/// [only] narrows it to one half of the marketplace (artists or vendors).
void showAllCategories(BuildContext context, AppState app, {List<String>? only}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: T.card,
    barrierColor: T.scrim,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (sheet) {
      final title = only == null ? 'All categories' : (identical(only, vendorCatIds) ? 'Business & Vendors' : 'Artists');
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * .85),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(16, 10, 16, 20 + MediaQuery.of(sheet).padding.bottom),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: T.bdhi, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Text(title, style: F.fraunces(size: 20, weight: FontWeight.w700, color: T.cream)),
            for (final d in divisions)
              if ((catsByDivision[d.id] ?? const <Cat>[]).any((c) => only == null || only.contains(c.id))) ...[
                const SizedBox(height: 16),
                Text('${d.icon}  ${d.name.toUpperCase()}',
                    style: F.syne(size: 10.5, weight: FontWeight.w800, color: T.dac(d.id), letterSpacing: 1.3)),
                const SizedBox(height: 10),
                LayoutBuilder(builder: (context, bc) {
                  final cols = bc.maxWidth >= 560 ? 6 : 4;
                  return Wrap(
                    runSpacing: 12,
                    children: [
                      for (final c in catsByDivision[d.id]!)
                        if (only == null || only.contains(c.id))
                          SizedBox(
                            width: bc.maxWidth / cols,
                            child: _IconCell(
                              icon: c.icon,
                              label: c.name,
                              accent: T.ac(c.id),
                              onTap: () {
                                Navigator.of(sheet).pop();
                                app.openResults(cat: c.id);
                              },
                            ),
                          ),
                    ],
                  );
                }),
              ],
          ],
        ),
      );
    },
  );
}

/// The bell: every notification — events, workshops, industry news.
void showNotifications(BuildContext context, AppState app) {
  final feed = app.updateFeed;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: T.card,
    barrierColor: T.scrim,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (sheet) {
      void go(UpdateEntry e) {
        Navigator.of(sheet).pop();
        switch (e.kind) {
          case 'workshop':
          case 'webinar':
            app.setView('sessions');
          case 'event':
            app.setView('events');
          default:
            app.setView('newsletter');
        }
      }

      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * .8),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(children: [
              Expanded(
                child: Text('Notifications · Industry & News',
                    style: F.fraunces(size: 18, weight: FontWeight.w700, color: T.cream)),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(sheet).pop(),
                icon: Icon(Icons.close_rounded, color: T.mut),
              ),
            ]),
          ),
          Container(height: 1, color: T.bdr),
          if (feed.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Text('You are all caught up.',
                  textAlign: TextAlign.center, style: F.syne(size: 14, weight: FontWeight.w600, color: T.mut)),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.only(bottom: MediaQuery.of(sheet).padding.bottom + 8),
                itemCount: feed.length,
                separatorBuilder: (_, __) => Container(height: 1, color: T.bdr),
                itemBuilder: (_, i) {
                  final e = feed[i];
                  return ListTile(
                    onTap: () => go(e),
                    leading: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: T.dac(e.division).withValues(alpha: .14), shape: BoxShape.circle),
                      child: Text(e.emoji, style: const TextStyle(fontSize: 18)),
                    ),
                    title: Text(e.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: F.syne(size: 13.5, weight: FontWeight.w700, color: T.cream)),
                    subtitle: Text(
                        [e.kind[0].toUpperCase() + e.kind.substring(1), e.date, e.city].where((x) => x.isNotEmpty).join(' · '),
                        style: F.syne(size: 11.5, weight: FontWeight.w500, color: T.dim)),
                    trailing: e.live
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: T.red, borderRadius: BorderRadius.circular(3)),
                            child: Text('LIVE', style: F.syne(size: 9, weight: FontWeight.w800, color: T.onAccent(T.red))),
                          )
                        : Icon(Icons.chevron_right_rounded, color: T.faint),
                  );
                },
              ),
            ),
        ]),
      );
    },
  );
}
