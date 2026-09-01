import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/geo.dart';
import '../services/voice_search.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'common.dart';

/// The marketplace search bar — free text, a state/city/area picker, and
/// voice input.
///
/// Before this the only way to change where you were browsing was a four-item
/// popup menu of hardcoded cities, and there was no text search at all. The
/// brief asks for "search bar by city and state" plus a "voice search bar";
/// this is both, in one control.
class MarketSearch extends StatefulWidget {
  final Color accent;
  const MarketSearch({super.key, required this.accent});

  @override
  State<MarketSearch> createState() => _MarketSearchState();
}

class _MarketSearchState extends State<MarketSearch> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _listening = false;
  List<GeoSuggestion> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus) {
        _refreshSuggestions(_controller.text);
      } else {
        // Deferred so a tap on a suggestion lands before the overlay goes.
        Future.delayed(const Duration(milliseconds: 160), () {
          if (mounted && !_focus.hasFocus) _hide();
        });
      }
    });
  }

  @override
  void dispose() {
    _hide();
    _controller.dispose();
    _focus.dispose();
    VoiceSearch.stop();
    super.dispose();
  }

  void _refreshSuggestions(String q) {
    final next = GeoIndex.suggest(q);
    _suggestions = next;
    if (next.isEmpty) {
      _hide();
    } else {
      _show();
      _overlay?.markNeedsBuild();
    }
  }

  void _show() {
    if (_overlay != null) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _overlay = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_overlay!);
  }

  void _hide() {
    _overlay?.remove();
    _overlay = null;
  }

  void _pick(GeoSuggestion s) {
    final app = context.read<AppState>();
    _controller.clear();
    app.clearQuery();
    app.setLocation(s.value);
    _focus.unfocus();
    _hide();
  }

  void _submit(String raw) {
    final app = context.read<AppState>();
    app.setQuery(raw);
    // setQuery consumes the term when it resolves to a place — reflect that
    // back into the field so it doesn't keep showing a term that isn't
    // filtering anything.
    if (app.query.isEmpty) _controller.clear();
    _focus.unfocus();
    _hide();
  }

  Future<void> _startVoice() async {
    if (_listening) {
      VoiceSearch.stop();
      setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    final result = await VoiceSearch.listen();
    if (!mounted) return;
    setState(() => _listening = false);

    if (result.ok) {
      _controller.text = result.transcript;
      _submit(result.transcript);
      if (mounted) {
        context.read<AppState>().showToast('Heard you', result.transcript, '🎙️');
      }
    } else if (result.error != null && mounted) {
      context.read<AppState>().showToast('Voice search', result.error!, '🎙️');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: T.surf,
          border: Border.all(color: _focus.hasFocus ? widget.accent : T.bdr),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 18, color: _focus.hasFocus ? widget.accent : T.dim),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                onChanged: _refreshSuggestions,
                onSubmitted: _submit,
                textInputAction: TextInputAction.search,
                style: F.syne(size: 13, weight: FontWeight.w500, color: T.text),
                cursorColor: widget.accent,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  // Three tiers rather than two: at phone width the place
                  // pill takes real estate the hint used to have, and a
                  // half-truncated sentence reads worse than a short one.
                  hintText: switch (screenW(context)) {
                    < 420 => 'Search',
                    < 900 => 'Search name, city or state',
                    _ => 'Search talent, crews, studios — or a city, area or state',
                  },
                  hintStyle: F.syne(size: 13, weight: FontWeight.w400, color: T.dim),
                ),
              ),
            ),
            if (app.query.isNotEmpty)
              _IconBtn(
                icon: Icons.close_rounded,
                tooltip: 'Clear search',
                accent: widget.accent,
                onTap: () {
                  _controller.clear();
                  app.clearQuery();
                },
              ),
            // Only offered where the browser can actually do it.
            if (VoiceSearch.isSupported)
              _IconBtn(
                icon: _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                tooltip: _listening ? 'Listening — tap to stop' : 'Search by voice',
                accent: _listening ? T.redText : widget.accent,
                active: _listening,
                onTap: _startVoice,
              ),
            const SizedBox(width: 4),
            Container(width: 1, height: 22, color: T.bdr),
            const SizedBox(width: 4),
            _PlacePill(app: app, accent: widget.accent),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext ctx) {
    final box = context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 320;
    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 52),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 320),
            decoration: BoxDecoration(
              color: T.card,
              border: Border.all(color: T.bdr),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8))],
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
                  child: Text('PLACES',
                      style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 2)),
                ),
                for (final s in _suggestions)
                  HoverFx(
                    onTap: () => _pick(s),
                    builder: (h) => Container(
                      color: h ? T.surf : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Text(s.icon, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(s.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: F.syne(size: 13, weight: FontWeight.w700, color: T.text)),
                          ),
                          const SizedBox(width: 10),
                          Text(s.hint,
                              style: F.syne(size: 11, weight: FontWeight.w400, color: T.dim)),
                        ],
                      ),
                    ),
                  ),
                Container(height: 1, color: T.bdr, margin: const EdgeInsets.symmetric(vertical: 6)),
                HoverFx(
                  onTap: () => _pick(const GeoSuggestion(kAllIndia, 'Everywhere', GeoKind.state)),
                  builder: (h) => Container(
                    color: h ? T.surf : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(children: [
                      const Text('🇮🇳', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 10),
                      Text('All India',
                          style: F.syne(size: 13, weight: FontWeight.w700, color: T.gold)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The current place, and a menu to change it by state → city.
///
/// Density is decided from the width this pill can actually take, not from
/// the screen width: the search row is full-bleed on a phone, so the city
/// name fits there even though it would not fit in the desktop nav's leftovers.
/// Hiding it everywhere under 768px left phone users with no way to see which
/// city they were browsing.
class _PlacePill extends StatelessWidget {
  final AppState app;
  final Color accent;
  const _PlacePill({required this.app, required this.accent});

  @override
  Widget build(BuildContext context) {
    final st = app.locationState;
    final avail = screenW(context);
    // Below this the row genuinely cannot spare the label.
    final compact = avail < 330;
    final showState = st.isNotEmpty && avail >= 460;
    return PopupMenuButton<String>(
      tooltip: 'Browsing ${app.location}${st.isEmpty ? '' : ', $st'} — tap to change',
      color: T.surf,
      elevation: 8,
      constraints: const BoxConstraints(maxHeight: 420, minWidth: 240),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: T.bdr),
      ),
      position: PopupMenuPosition.under,
      onSelected: app.setLocation,
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          height: 30,
          child: Text('STATES & CITIES',
              style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 1.5)),
        ),
        PopupMenuItem(
          value: kAllIndia,
          height: 38,
          child: Row(children: [
            Icon(app.location == kAllIndia ? Icons.public : Icons.public_outlined,
                size: 16, color: app.location == kAllIndia ? T.gold : T.mut),
            const SizedBox(width: 10),
            Text('All India',
                style: F.syne(
                    size: 13,
                    weight: FontWeight.w700,
                    color: app.location == kAllIndia ? T.gold : T.text)),
          ]),
        ),
        for (final state in geoStates) ...[
          PopupMenuItem(
            value: state.name,
            height: 34,
            child: Row(children: [
              Text(state.short,
                  style: F.mono(size: 10, color: app.location == state.name ? T.gold : T.faint)),
              const SizedBox(width: 10),
              Text(state.name,
                  style: F.syne(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: app.location == state.name ? T.gold : T.text)),
            ]),
          ),
          for (final city in state.cities)
            // A single-city state would just repeat the row above it.
            if (state.cities.length > 1 || city.name != state.name)
              PopupMenuItem(
                value: city.name,
                height: 30,
                child: Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(city.name,
                      style: F.syne(
                          size: 12,
                          weight: FontWeight.w500,
                          color: app.location == city.name ? T.gold : T.mut)),
                ),
              ),
        ],
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 7),
        decoration: BoxDecoration(
          color: T.gold.withValues(alpha: .08),
          border: Border.all(color: T.gold.withValues(alpha: .3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 13, color: T.gold),
            if (!compact) ...[
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(app.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: F.syne(size: 12, weight: FontWeight.w700, color: T.gold)),
                    if (showState)
                      Text(st,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: F.mono(size: 9, color: T.dim)),
                  ],
                ),
              ),
            ],
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, size: 15, color: T.gold),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color accent;
  final bool active;
  final VoidCallback onTap;
  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.accent,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: HoverFx(
          onTap: onTap,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: active ? accent.withValues(alpha: .16) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 17, color: (h || active) ? accent : T.dim),
          ),
        ),
      );
}
