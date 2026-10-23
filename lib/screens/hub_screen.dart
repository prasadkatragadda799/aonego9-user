import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/taxonomy.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/home_sections.dart' show artistCatIds, vendorCatIds;
import '../widgets/home_showcase.dart' show IndustryExperts;
import '../widgets/hub_parts.dart';
import '../widgets/reels_viewer.dart' show showReelsViewer;
import '../widgets/results_kit.dart' show showDeskBrief;

/// Artists and Vendors — the bottom bar's two marketplace tabs, laid out in
/// the Wedding Planning format the client approved: a festive banner with a
/// search riding over it, round shortcuts, then tinted bands of picture
/// cards with promos between them.
///
/// The search here finds a profile by NAME across every category in the
/// hub ("the one I already know"), which the category search on the home
/// page cannot do.
class HubScreen extends StatelessWidget {
  /// 'artists' | 'vendors'
  final String kind;
  const HubScreen({super.key, required this.kind});

  bool get _artists => kind == 'artists';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final narrow = isNarrow(context);
    final pad = narrow ? 16.0 : 20.0;
    void open(String cat) => app.openResults(cat: cat);
    final ids = _artists ? artistCatIds : vendorCatIds;
    final circles = [for (final c in ids.map(catOf).whereType<Cat>()) (c.id, c.name)];

    final sections = _artists
        ? <Widget>[
            IndustryExperts(app: app),
            HubBand(
              title: 'On camera — models & talent',
              tint: const Color(0xFFF7D9DF),
              items: const [
                ('modelF', 'Female Models', '👗'),
                ('modelM', 'Male Models', '🕴️'),
                ('makeupArtist', 'Makeup & Hair Artists', '💄'),
                ('designer', 'Fashion Designers', '✂️'),
              ],
              onOpen: open,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 22, pad, 0),
              child: HubPromo(
                title: 'Can\'t find the right face?',
                sub: 'Our casting desk sends you a shortlist of five in 24 hours',
                cta: 'Get my shortlist',
                emoji: '🎯',
                onTap: () => showDeskBrief(context, cat: catOf('modelF')!),
              ),
            ),
            HubBand(
              title: 'Behind the camera',
              tint: const Color(0xFFFBE7CF),
              items: const [
                ('photo', 'Photographers', '📸'),
                ('video', 'Videographers', '🎥'),
                ('editVideo', 'Video Editors', '🎞️'),
                ('editVfx', 'VFX Artists', '🪄'),
              ],
              onOpen: open,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 22, pad, 0),
              child: HubPromo(
                title: 'Watch artists\' reels',
                sub: 'Swipe through the photos and videos on their profiles',
                cta: 'Play reels',
                emoji: '🎬',
                ground: const Color(0xFF2A0C3A),
                accent: T.marigold,
                onTap: () => showReelsViewer(context),
              ),
            ),
            HubBand(
              title: 'Design & motion',
              tint: const Color(0xFFE6E1F5),
              items: const [
                ('edit3d', '3D & Animation', '🧊'),
                ('editGraphic', 'Graphic Designers', '🎨'),
                ('photo', 'Portfolio Shoots', '🖼️'),
                ('video', 'Showreels', '📽️'),
              ],
              onOpen: open,
            ),
          ]
        : <Widget>[
            HubBand(
              title: 'Floors, studios & venues',
              tint: const Color(0xFFDDEFEA),
              items: const [
                ('studio', 'Photo Studios', '📷'),
                ('venue', 'Event Venues', '🏛️'),
                ('events', 'Event Production', '🎪'),
                ('hotel', 'Hotels & Stays', '🏨'),
              ],
              onOpen: open,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 22, pad, 0),
              child: HubPromo(
                title: 'Advertise your business',
                sub: 'Photo & video ads, listings and Instagram campaigns',
                cta: 'Get started',
                emoji: '📣',
                ground: const Color(0xFF0E3B3A),
                accent: T.marigold,
                onTap: () => app.setView('advertise'),
              ),
            ),
            HubBand(
              title: 'Fashion, beauty & learning',
              tint: const Color(0xFFFBE7CF),
              items: const [
                ('clothShop', 'Cloth Houses & Showrooms', '👚'),
                ('jewellery', 'Jewellery', '💎'),
                ('makeupStudio', 'Beauty & Makeup Studios', '💇'),
                ('academy', 'Academies', '🎓'),
              ],
              onOpen: open,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 22, pad, 0),
              child: HubPromo(
                title: 'Planning a wedding?',
                sub: 'Venues, decor, photographers and stays in one place',
                emoji: '💍',
                onTap: () => app.setView('wedding'),
              ),
            ),
          ];

    return Container(
      color: T.bg,
      child: Column(children: [
        AppTopBar(title: _artists ? 'Artists' : 'Vendors & Services'),
        Expanded(
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    HubBanner(
                      colors: _artists
                          ? const [Color(0xFF2A0C3A), Color(0xFF8A1F5C), T.marigold]
                          : const [Color(0xFF0E3B3A), Color(0xFF1E6B5C), T.marigold],
                      motif: _artists ? 'talent' : 'spaces',
                      motifAccent: T.marigold,
                      emojis: _artists ? '⭐ 🎬 📸' : '🏛️ 🎛️ 🏨',
                      title: _artists ? 'Find the right face for the frame' : 'Book the floor, the crew and the kit',
                      search: _ProfileSearchField(catIds: ids, artists: _artists),
                    ),
                    _ProfileSearchResults(catIds: ids, artists: _artists),
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, 18, pad, 0),
                      child: HubCircles(items: circles, onOpen: open),
                    ),
                    ...sections,
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ),
          ]),
        ),
        if (narrow) const AppDock(),
      ]),
    );
  }
}

/// ── Name search ──────────────────────────────────────────────────
/// The field (over the banner) and the results (under it) talk through a
/// small notifier, so the results can push the page down instead of
/// floating over the shortcuts.
class _HubSearch extends ChangeNotifier {
  String query = '';

  /// The location [results] belong to — a search is stale once it moves.
  String location = '';
  bool busy = false;
  List<Map<String, dynamic>>? results; // null = backend unreachable
  int _token = 0;
  Timer? _debounce;

  void search(AppState app, String q, List<String> catIds) {
    query = q.trim();
    location = app.location;
    _debounce?.cancel();
    if (query.length < 2) {
      busy = false;
      results = const [];
      notifyListeners();
      return;
    }
    busy = true;
    notifyListeners();
    _debounce = Timer(const Duration(milliseconds: 380), () async {
      final token = ++_token;
      final found = await app.searchProfiles(query, catIds);
      if (token != _token) return;
      results = found;
      busy = false;
      notifyListeners();
    });
  }

  void clear() {
    _debounce?.cancel();
    _token++;
    query = '';
    busy = false;
    results = const [];
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final Map<String, _HubSearch> _searches = {};
_HubSearch _searchFor(bool artists) => _searches.putIfAbsent(artists ? 'a' : 'v', _HubSearch.new);

class _ProfileSearchField extends StatefulWidget {
  final List<String> catIds;
  final bool artists;
  const _ProfileSearchField({required this.catIds, required this.artists});

  @override
  State<_ProfileSearchField> createState() => _ProfileSearchFieldState();
}

class _ProfileSearchFieldState extends State<_ProfileSearchField> {
  late final _HubSearch _s = _searchFor(widget.artists);
  late final _c = TextEditingController(text: _s.query);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Container(
      height: 52,
      decoration: BoxDecoration(color: T.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: T.bdr)),
      child: Row(children: [
        const SizedBox(width: 14),
        Icon(Icons.person_search_rounded, size: 20, color: T.gold),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _c,
            onChanged: (v) {
              _s.search(app, v, widget.catIds);
              setState(() {});
            },
            textInputAction: TextInputAction.search,
            style: F.syne(size: 14, weight: FontWeight.w500, color: T.text),
            cursorColor: T.gold,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: widget.artists ? 'Search an artist by name…' : 'Search a studio, venue or shop by name…',
              hintStyle: F.syne(size: 14, weight: FontWeight.w400, color: T.dim),
            ),
          ),
        ),
        if (_c.text.isNotEmpty)
          IconButton(
            tooltip: 'Clear',
            onPressed: () {
              _c.clear();
              _s.clear();
              setState(() {});
            },
            icon: Icon(Icons.close_rounded, size: 18, color: T.mut),
          )
        else
          const SizedBox(width: 14),
      ]),
    );
  }
}

class _ProfileSearchResults extends StatelessWidget {
  final List<String> catIds;
  final bool artists;
  const _ProfileSearchResults({required this.catIds, required this.artists});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = _searchFor(artists);
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        if (s.query.length < 2) return const SizedBox.shrink();
        if (s.location != app.location && !s.busy) {
          // The visitor changed city since searching — search again there.
          WidgetsBinding.instance.addPostFrameCallback((_) => s.search(app, s.query, catIds));
        }
        final pad = isNarrow(context) ? 16.0 : 20.0;
        final q = s.query.toLowerCase();
        // Typing a category's name is a way in too: "photo" → Photographers.
        final cats = catIds.map(catOf).whereType<Cat>().where((c) => c.name.toLowerCase().contains(q)).toList();
        final results = s.results;

        Widget body;
        if (s.busy && (results == null || results.isEmpty)) {
          body = Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: T.gold)),
              const SizedBox(width: 10),
              Text('Searching ${artists ? 'artists' : 'vendors'} in ${app.location}…',
                  style: F.syne(size: 13, weight: FontWeight.w500, color: T.mut)),
            ]),
          );
        } else if (results == null) {
          body = _note('📡', 'Couldn\'t reach AOneGo9 right now — try again in a moment.');
        } else if (results.isEmpty) {
          body = _note('🔎', 'No ${artists ? 'artist' : 'business'} called "${s.query}" in ${app.location} yet.');
        } else {
          body = Column(children: [
            for (final v in results) _ResultRow(item: v, onTap: () => app.openProfile(v)),
          ]);
        }

        return Container(
          margin: EdgeInsets.fromLTRB(pad, 12, pad, 0),
          decoration: BoxDecoration(
            color: T.card,
            border: Border.all(color: T.bdr),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (cats.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final c in cats)
                    HoverFx(
                      onTap: () => app.openResults(cat: c.id),
                      builder: (h) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: h ? T.gold.withValues(alpha: .1) : T.surf,
                          border: Border.all(color: h ? T.gold : T.bdr),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text('${c.icon}  All ${c.name} →',
                            style: F.syne(size: 12.5, weight: FontWeight.w700, color: T.text)),
                      ),
                    ),
                ]),
              ),
            body,
            if (results != null && results.isEmpty && !s.busy && app.location != 'All India')
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Center(
                  child: HoverFx(
                    // Moving the location re-runs the search (see above).
                    onTap: () => app.setLocation('All India'),
                    builder: (h) => Text('Search all India instead →',
                        style: F.syne(size: 13, weight: FontWeight.w700, color: h ? T.cream : T.gold)),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }

  Widget _note(String icon, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: F.syne(size: 13, weight: FontWeight.w500, color: T.mut))),
        ]),
      );
}

class _ResultRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _ResultRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final url = '${item['avatarUrl'] ?? ''}'.trim();
    final accent = T.ac(item['cat'] as String?);
    final rating = (item['rating'] as num?)?.toDouble() ?? 0;
    final sub = [catOf(item['cat'] as String?)?.name ?? '', '${item['loc'] ?? ''}']
        .where((e) => e.trim().isNotEmpty)
        .join('  ·  ');
    return HoverFx(
      onTap: onTap,
      builder: (h) => Container(
        color: h ? T.surf : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: .12)),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: url.isEmpty
                ? Text('${item['emoji'] ?? '✦'}', style: const TextStyle(fontSize: 18))
                : Image.network(url,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Text('${item['emoji'] ?? '✦'}', style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text('${item['name'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: F.syne(size: 14, weight: FontWeight.w700, color: T.cream)),
                ),
                if (item['verified'] == true) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified_rounded, size: 14, color: T.logoCyan),
                ],
              ]),
              const SizedBox(height: 2),
              Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: F.syne(size: 12, weight: FontWeight.w500, color: T.mut)),
            ]),
          ),
          if (rating > 0)
            Container(
              padding: const EdgeInsets.fromLTRB(6, 2, 5, 2),
              decoration: BoxDecoration(color: T.grn, borderRadius: BorderRadius.circular(4)),
              child: Text('${rating.toStringAsFixed(1)} ★', style: F.syne(size: 11, weight: FontWeight.w800, color: Colors.white)),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: T.dim),
        ]),
      ),
    );
  }
}
