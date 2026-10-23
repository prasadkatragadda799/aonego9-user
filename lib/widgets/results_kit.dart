import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils/phone_util.dart';
import '../data/taxonomy.dart';
import '../services/link_service.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'common.dart';
import 'division_fx.dart';
import 'form_fields.dart';
import 'lead_form.dart';

/// ─────────────────────────────────────────────────────────────────
/// RESULTS KIT — the category results page, top to bottom:
///
///   CategoryStage   the category as a stage: poster ground, the division's
///                   own motion, live floor stats, and the casting desk CTA
///   LookTiles       the category's looks (Fashion, Ethnic, Ramp…) as tiles
///   ResultsToolbar  count, sort, verified-only, grid ⇄ list
///   DeskCard        "not sure who to pick?" — sits inside the results
///   ShortlistPill   floating, once anything is hearted
///
/// Plus the sheets those open: quick enquiry, casting-desk brief, shortlist.
/// The flow follows a directory (search → category → results → enquire);
/// the shortlist and the casting desk are the agency's own.
/// ─────────────────────────────────────────────────────────────────

/// Share a profile over WhatsApp with its deep link.
Future<void> shareProfileOnWhatsApp(BuildContext context, Map<String, dynamic> item) async {
  final app = context.read<AppState>();
  final cat = catOf(item['cat'] as String?)?.name ?? '';
  final loc = '${item['loc'] ?? ''}'.trim();
  final text = [
    '${item['name'] ?? 'A profile'} — $cat${loc.isEmpty ? '' : ' in $loc'}, on AOneGo9',
    app.shareLink(item),
  ].join('\n');
  final ok = await LinkService.shareOnWhatsApp(text);
  if (ok) {
    app.recordShare('${item['id'] ?? ''}');
  } else {
    app.showToast('Couldn\'t open WhatsApp', 'Copy the link from the profile instead', '⚠️');
  }
}

/// ── Category stage ───────────────────────────────────────────────
class CategoryStage extends StatelessWidget {
  final AppState app;
  final Cat cat;
  final VoidCallback onDesk;
  const CategoryStage({super.key, required this.app, required this.cat, required this.onDesk});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    final division = divisionById[cat.division];
    final place = app.location;
    final items = app.catItems;
    final verified = items.where((v) => v['verified'] == true).length;
    final rated = items.map((v) => (v['rating'] as num?)?.toDouble() ?? 0).where((r) => r > 0).toList();
    final avg = rated.isEmpty ? null : rated.reduce((a, b) => a + b) / rated.length;
    final settled = !app.listingsLoading && !app.listingsFailed;
    // The poster ground stays dark in both themes, so the accent has to be
    // the poster one rather than the paper-weight category accent.
    const ink = T.posterInk;
    const accent = T.marigold;

    return Container(
      margin: EdgeInsets.fromLTRB(narrow ? 16 : 20, 18, narrow ? 16 : 20, 4),
      decoration: BoxDecoration(
        gradient: T.grPoster(cat.id.hashCode.abs() % 9),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned.fill(
          child: DivisionFx(divisionId: cat.division, accent: accent, intensity: 1.5, fadeToward: Alignment.centerLeft),
        ),
        // The category's mark, lit like a spotlight on the right.
        Positioned(
          right: narrow ? -6 : 28,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: narrow ? 130 : 240,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [accent.withValues(alpha: .28), Colors.transparent]),
              ),
              child: Opacity(
                opacity: narrow ? .5 : .95,
                child: Text(cat.icon, style: TextStyle(fontSize: narrow ? 70 : 110)),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(narrow ? 18 : 28, narrow ? 18 : 26, narrow ? 18 : 28, narrow ? 18 : 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: narrow ? double.infinity : 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  [if (division != null) division.name.toUpperCase(), place.toUpperCase()].join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: F.syne(size: 10.5, weight: FontWeight.w800, color: accent, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: cat.h1, style: const TextStyle(color: ink)),
                    TextSpan(text: cat.h2, style: const TextStyle(color: accent)),
                  ]),
                  style: F.fraunces(size: narrow ? 24 : 32, weight: FontWeight.w700, height: 1.12),
                ),
                if (cat.sub.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(cat.sub,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: F.syne(size: 13, weight: FontWeight.w400, color: T.posterInkMuted, height: 1.5)),
                ],
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _StatChip(value: settled ? '${items.length}' : '—', label: items.length == 1 ? 'profile' : 'profiles'),
                  _StatChip(value: settled ? '$verified' : '—', label: 'verified'),
                  if (avg != null) _StatChip(value: '★ ${avg.toStringAsFixed(1)}', label: 'avg rating'),
                ]),
                const SizedBox(height: 18),
                // The shortlist has its own floating pill, so the stage keeps
                // to one call to action.
                _StageBtn(label: 'Let our desk shortlist for you', icon: Icons.auto_awesome_rounded, onTap: onDesk),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          border: Border.all(color: Colors.white.withValues(alpha: .16)),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: value, style: F.syne(size: 13, weight: FontWeight.w800, color: T.posterInk)),
          TextSpan(text: '  $label', style: F.syne(size: 12, weight: FontWeight.w500, color: T.posterInkMuted)),
        ])),
      );
}

class _StageBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _StageBtn({required this.label, required this.icon, required this.onTap});

  static const _ink = Color(0xFF2A1404);

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: h ? const Color(0xFFFFB84A) : T.marigold,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: _ink),
            const SizedBox(width: 7),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: F.syne(size: 13, weight: FontWeight.w800, color: _ink)),
            ),
          ]),
        ),
      );
}

/// ── Look tiles ───────────────────────────────────────────────────
/// The category's filter set, drawn as tiles you pick a look from rather
/// than a row of text chips.
class LookTiles extends StatelessWidget {
  final AppState app;
  final Color accent;
  const LookTiles({super.key, required this.app, required this.accent});

  static const _emoji = {
    'all': '✨', 'fashion': '👗', 'ethnic': '🪷', 'ramp': '🚶‍♀️', 'film': '🎬', 'commercial': '📺',
    'fitness': '💪', 'wedding': '💍', 'portrait': '🖼️', 'bridal': '👰', 'editorial': '📰', 'acting': '🎭',
    'modelling': '📸', 'hd & airbrush': '🖌️', 'sfx': '🧟', 'hair styling': '💇', 'makeup': '💄',
    'long form': '🎞️', 'social cuts': '📱', 'wedding films': '💒', 'colour grade': '🎨', 'compositing': '🧩',
    'clean-up': '🧽', 'cgi integration': '🪐', 'rotoscopy': '✂️', 'product 3d': '📦', 'character': '🧸',
    'motion graphics': '🌀', 'architectural': '🏛️', 'brand identity': '🔷', 'campaign': '📣',
    'packaging': '🎁', 'social': '💬', 'social media': '💬', 'banquet': '🍽️', 'rooftop': '🌇',
    'heritage': '🏰', 'outdoor': '🌳', 'indoor': '🏠', 'resort': '🏝️', 'concerts': '🎤',
    'corporate': '💼', 'business': '💼', 'fashion shows': '✨', 'wedding events': '🎊', 'documentary': '🎥',
    'brand films': '🎬', 'cyclorama': '⚪', 'daylight': '☀️', 'blackout': '🌑', 'equipment rental': '🎛️',
    'chair rental': '🪑', 'rental': '🔑', 'couture': '🪡', 'ready-to-wear': '👚', 'menswear': '🤵',
    'bridal wear': '👰', 'bridal sets': '💎', 'polki & kundan': '💎', 'contemporary': '💍', 'costume': '🎭',
    'fabric house': '🧵', 'handloom': '🧶', 'design': '✏️', 'film & media': '🎞️', 'academy': '🎓',
    'unit stay': '🛏️', 'bridal suite': '🛎️', 'on-location': '📍',
  };

  @override
  Widget build(BuildContext context) {
    final fs = app.filtersFor(app.activeCat);
    if (fs.length < 2) return const SizedBox.shrink();
    final narrow = isNarrow(context);
    final cat = catOf(app.activeCat);
    return SizedBox(
      height: narrow ? 104 : 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 20),
        itemCount: fs.length,
        separatorBuilder: (_, __) => SizedBox(width: narrow ? 8 : 12),
        itemBuilder: (_, i) {
          final f = fs[i];
          final on = app.filter == f;
          final emoji = _emoji[f.toLowerCase()] ?? cat?.icon ?? '✦';
          return Semantics(
            button: true,
            selected: on,
            label: f == 'All' ? 'All looks' : f,
            child: HoverFx(
              onTap: () => app.setFilter(f),
              builder: (h) => SizedBox(
                width: narrow ? 72 : 82,
                child: Column(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: narrow ? 66 : 74,
                    height: narrow ? 66 : 74,
                    decoration: BoxDecoration(
                      gradient: T.grPoster(i + 1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: on ? accent : (h ? accent.withValues(alpha: .5) : Colors.transparent), width: 2.5),
                      boxShadow: on
                          ? [BoxShadow(color: accent.withValues(alpha: .3), blurRadius: 14, offset: const Offset(0, 4))]
                          : null,
                    ),
                    child: Stack(children: [
                      Center(
                        child: AnimatedScale(
                          scale: on || h ? 1.12 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: Text(emoji, style: TextStyle(fontSize: narrow ? 28 : 31)),
                        ),
                      ),
                      if (on)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                            child: Icon(Icons.check_rounded, size: 11, color: T.onAccent(accent)),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 7),
                  Text(f == 'All' ? 'All looks' : f,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: F.syne(size: 11.5, weight: on ? FontWeight.w800 : FontWeight.w600, color: on ? accent : T.text)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ── Results toolbar ──────────────────────────────────────────────
class ResultsToolbar extends StatelessWidget {
  final AppState app;
  final Color accent;
  final int count;
  final bool listView;
  final ValueChanged<bool> onListView;
  const ResultsToolbar({
    super.key,
    required this.app,
    required this.accent,
    required this.count,
    required this.listView,
    required this.onListView,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    final place = app.location;
    final headline = app.listingsLoading && count == 0
        ? Text('Loading…', style: F.syne(size: 14, weight: FontWeight.w700, color: T.text))
        : app.listingsFailed && count == 0
            ? Text('Couldn\'t load', style: F.syne(size: 14, weight: FontWeight.w700, color: T.text))
            : Text.rich(
                TextSpan(children: [
                  TextSpan(text: '$count', style: F.fraunces(size: 20, weight: FontWeight.w700, color: T.cream)),
                  TextSpan(
                      text: count == 1 ? ' result' : ' results',
                      style: F.syne(size: 14, weight: FontWeight.w700, color: T.cream)),
                  TextSpan(text: '  in $place', style: F.syne(size: 13, weight: FontWeight.w500, color: T.mut)),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );

    final controls = <Widget>[
      _SortChip(app: app, accent: accent),
      _ToggleChip(
        label: 'Verified',
        icon: Icons.verified_rounded,
        on: app.verifiedOnly,
        accent: accent,
        onTap: app.toggleVerifiedOnly,
      ),
      if (app.query.isNotEmpty)
        _ToggleChip(label: '"${app.query}"', icon: Icons.close_rounded, on: true, accent: accent, onTap: app.clearQuery),
    ];

    final viewSwitch = _ViewSwitch(listView: listView, accent: accent, onChanged: onListView);

    return Padding(
      padding: EdgeInsets.fromLTRB(narrow ? 16 : 20, 16, narrow ? 16 : 20, 14),
      child: narrow
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [Expanded(child: headline), viewSwitch]),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: controls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => controls[i],
                ),
              ),
            ])
          : Row(children: [
              Expanded(child: headline),
              for (final c in controls) ...[c, const SizedBox(width: 8)],
              const SizedBox(width: 4),
              viewSwitch,
            ]),
    );
  }
}

class _SortChip extends StatelessWidget {
  final AppState app;
  final Color accent;
  const _SortChip({required this.app, required this.accent});

  @override
  Widget build(BuildContext context) {
    final active = app.sortBy != 'recommended';
    return PopupMenuButton<String>(
      tooltip: 'Sort results',
      color: T.card,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: T.bdr)),
      onSelected: app.setSort,
      itemBuilder: (_) => [
        for (final e in AppState.sortLabels.entries)
          PopupMenuItem(
            value: e.key,
            height: 40,
            child: Row(children: [
              SizedBox(
                width: 22,
                child: app.sortBy == e.key ? Icon(Icons.check_rounded, size: 16, color: accent) : null,
              ),
              Text(e.value,
                  style: F.syne(size: 13, weight: app.sortBy == e.key ? FontWeight.w800 : FontWeight.w500, color: T.text)),
            ]),
          ),
      ],
      child: _chipBody(
        accent: accent,
        on: active,
        icon: Icons.swap_vert_rounded,
        label: active ? AppState.sortLabels[app.sortBy]! : 'Sort',
        trailing: Icons.keyboard_arrow_down_rounded,
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool on;
  final Color accent;
  final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.icon, required this.on, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => _chipBody(accent: accent, on: on, icon: icon, label: label, hover: h),
      );
}

Widget _chipBody({
  required Color accent,
  required bool on,
  required IconData icon,
  required String label,
  IconData? trailing,
  bool hover = false,
}) =>
    AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: on ? accent.withValues(alpha: .1) : (hover ? T.surf : T.card),
        border: Border.all(color: on ? accent : T.bdr),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: on ? accent : T.mut),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: F.syne(size: 12.5, weight: FontWeight.w700, color: on ? accent : T.text)),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 2),
          Icon(trailing, size: 16, color: on ? accent : T.mut),
        ],
      ]),
    );

class _ViewSwitch extends StatelessWidget {
  final bool listView;
  final Color accent;
  final ValueChanged<bool> onChanged;
  const _ViewSwitch({required this.listView, required this.accent, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: T.surf,
          border: Border.all(color: T.bdr),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _seg(Icons.grid_view_rounded, 'Portfolio grid', !listView, () => onChanged(false)),
          _seg(Icons.view_agenda_outlined, 'List', listView, () => onChanged(true)),
        ]),
      );

  Widget _seg(IconData icon, String tip, bool on, VoidCallback onTap) => Tooltip(
        message: tip,
        child: HoverFx(
          onTap: onTap,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? T.card : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              boxShadow: on ? [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 4)] : null,
            ),
            child: Icon(icon, size: 16, color: on ? accent : (h ? T.text : T.dim)),
          ),
        ),
      );
}

/// ── Casting desk card ────────────────────────────────────────────
/// Sits inside the results (and stands in for them when a category is
/// empty): hand the brief to the desk and get a shortlist back.
class DeskCard extends StatelessWidget {
  final Cat cat;
  final String place;
  final VoidCallback onTap;
  /// Empty-category version: different words, same action.
  final bool empty;
  const DeskCard({super.key, required this.cat, required this.place, required this.onTap, this.empty = false});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5E1020), T.maroon, Color(0xFF3A0E16)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: h ? T.marigold : Colors.transparent, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            Positioned.fill(
              child: DivisionFx(divisionId: 'crew', accent: T.marigold, intensity: h ? 1.8 : 1.1, fadeToward: Alignment.centerLeft),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('CASTING DESK',
                      style: F.syne(size: 10.5, weight: FontWeight.w800, color: T.marigold, letterSpacing: 2)),
                  const SizedBox(height: 10),
                  Text(empty ? 'Nobody listed here yet — we can still find them.' : 'Not sure who to pick?',
                      style: F.fraunces(size: 21, weight: FontWeight.w700, color: T.posterInk, height: 1.2)),
                  const SizedBox(height: 8),
                  Text(
                    'Tell us the brief. Our desk hand-picks ${cat.name.toLowerCase()} in $place and sends you a shortlist of five within 24 hours.',
                    style: F.syne(size: 13, weight: FontWeight.w400, color: T.posterInkMuted, height: 1.55),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: h ? const Color(0xFFFFB84A) : T.marigold,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text('Get my shortlist →',
                        style: F.syne(size: 13, weight: FontWeight.w800, color: const Color(0xFF2A1404))),
                  ),
                ],
              ),
            ),
          ]),
        ),
      );
}

/// ── Floating shortlist pill ──────────────────────────────────────
class ShortlistPill extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const ShortlistPill({super.key, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
          decoration: BoxDecoration(
            color: h ? const Color(0xFF2A1A1C) : const Color(0xFF1F1513),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .28), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.favorite_rounded, size: 16, color: Color(0xFFFF6B81)),
            const SizedBox(width: 8),
            Text('Shortlist', style: F.syne(size: 13, weight: FontWeight.w700, color: T.posterInk)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: T.marigold, borderRadius: BorderRadius.circular(10)),
              child: Text('$count', style: F.syne(size: 12, weight: FontWeight.w800, color: const Color(0xFF2A1404))),
            ),
          ]),
        ),
      );
}

/// ── Sheets ───────────────────────────────────────────────────────

Future<R?> _sheet<R>(BuildContext context, Widget Function(BuildContext) builder) => showModalBottomSheet<R>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: T.bg,
      constraints: const BoxConstraints(maxWidth: 640),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .9),
        child: builder(ctx),
      ),
    );

class _SheetHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget? leading;
  const _SheetHeader({required this.eyebrow, required this.title, this.leading});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: T.bdhi, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 10, 12),
          child: Row(children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(eyebrow.toUpperCase(),
                    style: F.syne(size: 10, weight: FontWeight.w800, color: T.gold, letterSpacing: 1.8)),
                const SizedBox(height: 3),
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: F.fraunces(size: 19, weight: FontWeight.w700, color: T.cream, height: 1.2)),
              ]),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(Icons.close_rounded, color: T.mut),
            ),
          ]),
        ),
        Container(height: 1, color: T.bdr),
      ]);
}

Widget _avatar(Map<String, dynamic> item, double size) {
  final url = '${item['avatarUrl'] ?? ''}'.trim();
  final accent = T.ac(item['cat'] as String?);
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: accent.withValues(alpha: .12),
      border: Border.all(color: accent.withValues(alpha: .4)),
    ),
    clipBehavior: Clip.antiAlias,
    alignment: Alignment.center,
    child: url.isEmpty
        ? Text('${item['emoji'] ?? '✦'}', style: TextStyle(fontSize: size * .45))
        : Image.network(url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Text('${item['emoji'] ?? '✦'}', style: TextStyle(fontSize: size * .45))),
  );
}

/// Enquire straight from the results — the profile's own brief form, in a
/// sheet, so a visitor comparing several doesn't lose their place.
Future<void> showQuickEnquiry(BuildContext context, Map<String, dynamic> item) {
  final cat = '${item['cat'] ?? ''}';
  final accent = T.ac(cat);
  return _sheet(
    context,
    (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
      _SheetHeader(eyebrow: 'Send a brief', title: '${item['name'] ?? ''}', leading: _avatar(item, 44)),
      Flexible(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: LeadForm(
            name: '${item['name'] ?? ''}',
            cat: cat,
            accent: accent,
            vendorId: '${item['id'] ?? ''}',
          ),
        ),
      ),
    ]),
  );
}

/// The casting-desk brief. With [shortlist], it briefs the desk on those
/// profiles in one go instead of asking it to find people.
Future<void> showDeskBrief(BuildContext context, {required Cat cat, List<Map<String, dynamic>> shortlist = const []}) =>
    _sheet(context, (ctx) => _DeskBriefForm(cat: cat, shortlist: shortlist));

class _DeskBriefForm extends StatefulWidget {
  final Cat cat;
  final List<Map<String, dynamic>> shortlist;
  const _DeskBriefForm({required this.cat, required this.shortlist});

  @override
  State<_DeskBriefForm> createState() => _DeskBriefFormState();
}

class _DeskBriefFormState extends State<_DeskBriefForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _when = TextEditingController();
  final _notes = TextEditingController();
  String _budget = 'Not sure yet';
  bool _busy = false;
  bool _done = false;

  static const _budgets = ['Not sure yet', 'Under ₹10,000', '₹10,000 – ₹50,000', '₹50,000 – ₹2,00,000', 'Above ₹2,00,000'];

  bool get _forShortlist => widget.shortlist.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // A signed-in visitor shouldn't have to type themselves in again.
    final u = context.read<AppState>().currentUser;
    _name.text = '${u?['name'] ?? ''}';
    _phone.text = '${u?['phone'] ?? ''}';
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _when, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final app = context.read<AppState>();
    final phone = cleanIndianMobile(_phone.text);
    if (_name.text.trim().isEmpty || phone == null) {
      app.showToast('Check the form', 'Your name and a 10-digit mobile number', '⚠️');
      return;
    }
    setState(() => _busy = true);
    final ok = await app.submitLead(_forShortlist ? 'shortlist_brief' : 'desk_brief', {
      'name': _name.text.trim(),
      'phone': phone,
      'category': widget.cat.id,
      'category_name': widget.cat.name,
      'city': app.location,
      'when': _when.text.trim(),
      'budget': _budget,
      'message': _notes.text.trim(),
      if (_forShortlist) ...{
        'vendor_ids': [for (final s in widget.shortlist) '${s['id']}'],
        'vendor_names': [for (final s in widget.shortlist) '${s['name']}'],
      },
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = ok;
    });
    if (!ok) app.showToast('Couldn\'t send', 'Check your connection and try again', '⚠️');
  }

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    Widget pair(Widget a, Widget b) => narrow
        ? Column(children: [a, const SizedBox(height: 12), b])
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: a),
            const SizedBox(width: 12),
            Expanded(child: b),
          ]);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      _SheetHeader(
        eyebrow: _forShortlist ? 'Brief your shortlist' : 'Casting desk',
        title: _forShortlist
            ? 'One brief to ${widget.shortlist.length} ${widget.shortlist.length == 1 ? 'profile' : 'profiles'}'
            : 'Get a shortlist of ${widget.cat.name.toLowerCase()}',
      ),
      Flexible(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: _done
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('✅', style: TextStyle(fontSize: 30)),
                  const SizedBox(height: 10),
                  Text(_forShortlist ? 'Brief sent to your shortlist' : 'The desk is on it',
                      style: F.fraunces(size: 21, weight: FontWeight.w700, color: T.cream)),
                  const SizedBox(height: 6),
                  Text(
                    _forShortlist
                        ? 'The AOneGo9 desk will check availability with each of them and call you back.'
                        : 'Expect a call and a shortlist of five within 24 hours.',
                    style: F.syne(size: 14, weight: FontWeight.w400, color: T.mut, height: 1.6),
                  ),
                  const SizedBox(height: 18),
                  _PrimaryBtn(label: 'Done', onTap: () => Navigator.of(context).maybePop()),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_forShortlist) ...[
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final s in widget.shortlist)
                        Container(
                          padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                          decoration: BoxDecoration(
                            color: T.card,
                            border: Border.all(color: T.bdr),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            _avatar(s, 22),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Text('${s['name'] ?? ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: F.syne(size: 12, weight: FontWeight.w600, color: T.text)),
                            ),
                          ]),
                        ),
                    ]),
                    const SizedBox(height: 16),
                  ] else ...[
                    Text(
                      'Tell us what the job is. A person on our desk — not an algorithm — picks five who fit, checks they are free, and sends them to you.',
                      style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.55),
                    ),
                    const SizedBox(height: 16),
                  ],
                  pair(
                    Field('Your name', Fi('Full name', controller: _name)),
                    Field('Mobile', Fi('+91 …', keyboardType: TextInputType.phone, controller: _phone)),
                  ),
                  const SizedBox(height: 12),
                  pair(
                    Field('When', Fi('Date or "flexible"', controller: _when)),
                    Field('Budget', FiSelect(options: _budgets, value: _budget, onChanged: (v) => _budget = v ?? _budget)),
                  ),
                  const SizedBox(height: 12),
                  Field('The brief', Fi('Shoot type, look, hours, location…', controller: _notes, minLines: 3)),
                  const SizedBox(height: 18),
                  _PrimaryBtn(
                    label: _forShortlist ? 'Send brief to all →' : 'Get my shortlist →',
                    busy: _busy,
                    onTap: _submit,
                  ),
                ]),
        ),
      ),
    ]);
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool busy;
  const _PrimaryBtn({required this.label, required this.onTap, this.busy = false});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: busy ? () {} : onTap,
        builder: (h) => Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(color: h ? T.goldDark : T.gold, borderRadius: BorderRadius.circular(10)),
          child: busy
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: T.onAccent(T.gold)))
              : Text(label, style: F.syne(size: 14, weight: FontWeight.w700, color: T.onAccent(T.gold))),
        ),
      );
}

/// The shortlist: open, remove, brief them all, or share the list.
Future<void> showShortlistSheet(BuildContext context) => _sheet(context, (ctx) => const _ShortlistSheet());

class _ShortlistSheet extends StatelessWidget {
  const _ShortlistSheet();

  Future<void> _shareAll(BuildContext context, AppState app) async {
    final lines = [
      'My AOneGo9 shortlist:',
      for (final s in app.shortlist) '• ${s['name']} (${catOf(s['cat'] as String?)?.name ?? ''}) — ${app.shareLink(s)}',
    ];
    final ok = await LinkService.shareOnWhatsApp(lines.join('\n'));
    if (!ok) app.showToast('Couldn\'t open WhatsApp', 'Try again in a moment', '⚠️');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = app.shortlist;
    // Briefing a mixed pile goes to the desk under the first profile's
    // category; the desk sees every name either way.
    final cat = catOf(list.isEmpty ? app.activeCat : list.first['cat'] as String?) ?? catalogue.first;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      _SheetHeader(eyebrow: 'Your shortlist', title: list.isEmpty ? 'Nothing saved yet' : '${list.length} saved'),
      if (list.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
          child: Text('Tap ♥ on any profile to keep it here while you compare.',
              textAlign: TextAlign.center, style: F.syne(size: 14, weight: FontWeight.w500, color: T.mut)),
        )
      else ...[
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, __) => Container(height: 1, margin: const EdgeInsets.only(left: 76), color: T.bdr),
            itemBuilder: (_, i) {
              final s = list[i];
              final rating = (s['rating'] as num?)?.toDouble() ?? 0;
              final sub = [
                catOf(s['cat'] as String?)?.name ?? '',
                '${s['loc'] ?? ''}',
                if (rating > 0) '★ ${rating.toStringAsFixed(1)}',
              ].where((e) => e.trim().isNotEmpty).join('  ·  ');
              return HoverFx(
                onTap: () {
                  Navigator.of(context).maybePop();
                  app.openShortlisted(s);
                },
                builder: (h) => Container(
                  color: h ? T.surf : Colors.transparent,
                  padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
                  child: Row(children: [
                    _avatar(s, 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${s['name'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: F.syne(size: 14, weight: FontWeight.w700, color: T.cream)),
                        const SizedBox(height: 2),
                        Text(sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: F.syne(size: 12, weight: FontWeight.w500, color: T.mut)),
                      ]),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () => app.removeFromShortlist('${s['id']}'),
                      icon: Icon(Icons.close_rounded, size: 18, color: T.dim),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
        Container(height: 1, color: T.bdr),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(children: [
            _PrimaryBtn(
              label: 'Send one brief to all ${list.length} →',
              onTap: () {
                final pile = List<Map<String, dynamic>>.from(list);
                Navigator.of(context).maybePop();
                showDeskBrief(context, cat: cat, shortlist: pile);
              },
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: HoverFx(
                  onTap: () => _shareAll(context, app),
                  builder: (h) => Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: h ? const Color(0xFF1FA855) : const Color(0xFF1FA855).withValues(alpha: .1),
                      border: Border.all(color: const Color(0xFF1FA855).withValues(alpha: .5)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Share on WhatsApp',
                        style: F.syne(size: 13, weight: FontWeight.w700, color: h ? Colors.white : const Color(0xFF17803F))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              HoverFx(
                onTap: app.clearShortlist,
                builder: (h) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    border: Border.all(color: h ? T.redText : T.bdr),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Clear', style: F.syne(size: 13, weight: FontWeight.w700, color: h ? T.redText : T.mut)),
                ),
              ),
            ]),
          ]),
        ),
      ],
    ]);
  }
}

/// ── Loading skeletons ────────────────────────────────────────────
/// Card-shaped placeholders that breathe while listings load, so the page
/// already has its shape instead of a lone spinner in white space.
class ListingSkeletons extends StatefulWidget {
  final int cols;
  final bool row;
  final double gap;
  final String? note;
  const ListingSkeletons({super.key, required this.cols, required this.row, required this.gap, this.note});

  @override
  State<ListingSkeletons> createState() => _ListingSkeletonsState();
}

class _ListingSkeletonsState extends State<ListingSkeletons> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _bar(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(color: T.surf, borderRadius: BorderRadius.circular(5)),
      );

  Widget _card(double width) => Container(
        width: width,
        decoration: BoxDecoration(
          color: T.card,
          border: Border.all(color: T.bdr),
          borderRadius: BorderRadius.circular(widget.row ? 12 : 14),
        ),
        clipBehavior: Clip.antiAlias,
        child: widget.row
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 108, height: 136, decoration: BoxDecoration(color: T.surf, borderRadius: BorderRadius.circular(9))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _bar(double.infinity, 16),
                      const SizedBox(height: 10),
                      _bar(90, 14),
                      const SizedBox(height: 10),
                      _bar(140, 12),
                      const SizedBox(height: 10),
                      _bar(double.infinity, 12),
                    ]),
                  ),
                ]),
              )
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                AspectRatio(aspectRatio: 4 / 3.6, child: Container(color: T.surf)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _bar(double.infinity, 16),
                    const SizedBox(height: 10),
                    _bar(100, 14),
                    const SizedBox(height: 10),
                    _bar(150, 12),
                    const SizedBox(height: 16),
                    _bar(double.infinity, 40),
                  ]),
                ),
              ]),
      );

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: .45, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: LayoutBuilder(builder: (context, bc) {
          final w = (bc.maxWidth - widget.gap * (widget.cols - 1)) / widget.cols;
          final count = widget.cols * (widget.row ? 2 : 1).clamp(1, 4);
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (widget.note != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(widget.note!,
                    textAlign: TextAlign.center, style: F.syne(size: 13, weight: FontWeight.w500, color: T.mut)),
              ),
            Wrap(spacing: widget.gap, runSpacing: widget.gap, children: [
              for (var i = 0; i < count.clamp(2, 6); i++) _card(w),
            ]),
          ]);
        }),
      );
}
