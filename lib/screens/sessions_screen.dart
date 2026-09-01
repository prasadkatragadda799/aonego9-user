import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/directory.dart';
import '../data/taxonomy.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/ad_slot.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

/// Workshops & webinars — "workshop and webinar and show and all update".
///
/// Kept separate from the events calendar because they are a different
/// commitment: an event is something happening that you might attend, a
/// session is a seat you reserve, with a fee, a host and a capacity.
class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  String _mode = 'all'; // all | workshop | webinar
  String _division = 'all';

  List<Session> _filtered(AppState app) {
    var list = app.sessions;
    if (_mode == 'workshop') list = list.where((s) => !s.isWebinar).toList();
    if (_mode == 'webinar') list = list.where((s) => s.isWebinar).toList();
    if (_division != 'all') list = list.where((s) => s.division == _division).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pad = isNarrow(context) ? 16.0 : 24.0;
    final sessions = _filtered(app);
    final present = <String>{for (final s in app.sessions) s.division};

    return PageFrame(
      title: 'Workshops & Webinars',
      maxWidth: 1180,
      body: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro(
              eyebrow: 'Learn from the desk',
              title: 'Workshops in the room. Webinars from anywhere.',
              dek: 'Comp card clinics, lighting intensives, scene protocol sessions and post-production '
                  'pipelines — hosted by the people who actually run them.',
            ),
            const SizedBox(height: 20),

            // Mode toggle
            Wrap(spacing: 8, runSpacing: 8, children: [
              _Chip(label: 'Everything', icon: '⚡', active: _mode == 'all', accent: T.gold, onTap: () => setState(() => _mode = 'all')),
              _Chip(label: 'Workshops', icon: '🎓', active: _mode == 'workshop', accent: T.ac('events'), onTap: () => setState(() => _mode = 'workshop')),
              _Chip(label: 'Webinars', icon: '💻', active: _mode == 'webinar', accent: T.ac('video'), onTap: () => setState(() => _mode = 'webinar')),
            ]),
            const SizedBox(height: 10),

            // Division filter
            Wrap(spacing: 6, runSpacing: 6, children: [
              _Chip(label: 'All divisions', icon: '◆', active: _division == 'all', accent: T.gold, small: true, onTap: () => setState(() => _division = 'all')),
              for (final d in divisions)
                if (present.contains(d.id))
                  _Chip(
                    label: d.name,
                    icon: d.icon,
                    active: _division == d.id,
                    accent: T.dac(d.id),
                    small: true,
                    onTap: () => setState(() => _division = d.id),
                  ),
            ]),
            const SizedBox(height: 22),

            if (sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Column(children: [
                    const Text('🎓', style: TextStyle(fontSize: 30)),
                    const SizedBox(height: 10),
                    Text('Nothing scheduled in this filter yet',
                        style: F.syne(size: 14, weight: FontWeight.w600, color: T.mut)),
                    const SizedBox(height: 6),
                    HoverFx(
                      onTap: () => setState(() {
                        _mode = 'all';
                        _division = 'all';
                      }),
                      builder: (h) => Text('Show everything →',
                          style: F.syne(size: 13, weight: FontWeight.w700, color: h ? T.goldLight : T.gold)),
                    ),
                  ]),
                ),
              )
            else
              LayoutBuilder(builder: (context, bc) {
                final cols = bc.maxWidth >= 980 ? 3 : (bc.maxWidth >= 620 ? 2 : 1);
                const gap = 14.0;
                final w = (bc.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(spacing: gap, runSpacing: gap, children: [
                  for (final s in sessions) SizedBox(width: w, child: _SessionCard(session: s)),
                ]);
              }),

            const SizedBox(height: 36),
            const AdSlot(height: 220),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final accent = T.dac(session.division);
    final app = context.read<AppState>();

    return HoverFx(
      onTap: session.soldOut ? null : () => _openRegister(context, app, session),
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: T.card,
          border: Border.all(color: h && !session.soldOut ? accent : T.bdr),
          borderRadius: BorderRadius.circular(13),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          // Cover band
          Container(
            height: 84,
            decoration: BoxDecoration(gradient: T.gr(session.bg)),
            child: Stack(children: [
              Center(child: Opacity(opacity: .45, child: Text(session.emoji, style: const TextStyle(fontSize: 36)))),
              Positioned(
                top: 10,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4)),
                  child: Text(session.isWebinar ? 'WEBINAR' : 'WORKSHOP',
                      style: F.syne(size: 9, weight: FontWeight.w700, color: T.bg, letterSpacing: 1.3)),
                ),
              ),
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xCC09090B),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(session.fee,
                      style: F.syne(
                          size: 10,
                          weight: FontWeight.w700,
                          color: session.isFree ? T.grn : T.cream)),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(session.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: F.fraunces(size: 17, weight: FontWeight.w700, color: T.cream, height: 1.2)),
              const SizedBox(height: 6),
              Text(session.host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: F.syne(size: 11.5, weight: FontWeight.w700, color: accent)),
              if (session.blurb.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(session.blurb,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: F.syne(size: 12, weight: FontWeight.w400, color: T.mut, height: 1.55)),
              ],
              const SizedBox(height: 12),
              Container(height: 1, color: T.bdr),
              const SizedBox(height: 10),
              Wrap(spacing: 12, runSpacing: 5, children: [
                _meta('📅', session.date),
                if (session.time.isNotEmpty) _meta('🕑', session.time),
                if (session.duration.isNotEmpty) _meta('⏱', session.duration),
                _meta(session.isWebinar ? '💻' : '📍', session.placeLabel),
              ]),
              const SizedBox(height: 12),
              if (session.soldOut)
                _pill('Fully booked', T.redText, T.red.withValues(alpha: .12))
              else
                Row(children: [
                  if (session.seats > 0)
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: 1 - (session.seatsLeft / session.seats),
                            minHeight: 3,
                            backgroundColor: T.bdr,
                            color: session.nearlyFull ? T.redText : accent,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text('${session.seatsLeft} of ${session.seats} seats left',
                            style: F.mono(size: 9.5, color: session.nearlyFull ? T.redText : T.dim)),
                      ]),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      color: h ? accent : Colors.transparent,
                      border: Border.all(color: accent),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text('Reserve →',
                        style: F.syne(
                            size: 11.5,
                            weight: FontWeight.w700,
                            color: h ? T.onAccent(accent) : accent)),
                  ),
                ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _meta(String icon, String value) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 5),
        Text(value, style: F.mono(size: 10, color: T.dim)),
      ]);

  Widget _pill(String label, Color fg, Color bg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
        child: Text(label, style: F.syne(size: 11.5, weight: FontWeight.w700, color: fg)),
      );

  void _openRegister(BuildContext context, AppState app, Session s) {
    showDialog<void>(
      context: context,
      barrierColor: T.scrim,
      builder: (_) => _RegisterDialog(session: s, app: app),
    );
  }
}

class _RegisterDialog extends StatefulWidget {
  final Session session;
  final AppState app;
  const _RegisterDialog({required this.session, required this.app});

  @override
  State<_RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<_RegisterDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from the signed-in account — nobody should retype what we know.
    final u = widget.app.currentUser;
    if (u != null) {
      _name.text = '${u['name'] ?? ''}';
      _email.text = '${u['email'] ?? ''}';
      _phone.text = '${u['phone'] ?? ''}';
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final accent = T.dac(s.division);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isNarrow(context) ? 16 : 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          decoration: BoxDecoration(
            color: T.card,
            border: Border.all(color: T.bdr),
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: BoxDecoration(
                color: T.surf,
                border: Border(bottom: BorderSide(color: T.bdr)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(s.isWebinar ? 'RESERVE A WEBINAR SEAT' : 'RESERVE A WORKSHOP SEAT',
                    style: F.syne(size: 9.5, weight: FontWeight.w700, color: accent, letterSpacing: 1.6)),
                const SizedBox(height: 8),
                Text(s.title, style: F.fraunces(size: 19, weight: FontWeight.w700, color: T.cream, height: 1.2)),
                const SizedBox(height: 6),
                Text(
                  [s.date, if (s.time.isNotEmpty) s.time, s.city].where((e) => e.isNotEmpty).join(' · '),
                  style: F.mono(size: 10.5, color: T.dim),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: s.isFree ? T.grn.withValues(alpha: .12) : accent.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(s.isFree ? 'Free' : '${s.fee} · payable to the host',
                      style: F.syne(size: 10.5, weight: FontWeight.w700, color: s.isFree ? T.grn : accent)),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Field('Your name', Fi('Full name', controller: _name)),
                const SizedBox(height: 12),
                Field('Email', Fi('you@example.com', keyboardType: TextInputType.emailAddress, controller: _email)),
                const SizedBox(height: 12),
                Field('Phone', Fi('+91 …', keyboardType: TextInputType.phone, controller: _phone)),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(
                    child: HoverFx(
                      onTap: () => Navigator.of(context).maybePop(),
                      builder: (h) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: h ? T.bdhi : T.bdr),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Cancel', style: F.syne(size: 12.5, weight: FontWeight.w600, color: T.mut)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: HoverFx(
                      onTap: _busy ? null : _submit,
                      builder: (h) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _busy ? T.goldDark : accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_busy ? 'Requesting…' : 'Request seat',
                            style: F.syne(size: 12.5, weight: FontWeight.w700, color: T.onAccent(accent))),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (_name.text.trim().isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(email)) {
      widget.app.showToast('Check your details', 'A name and a valid email are required', '⚠️');
      return;
    }
    setState(() => _busy = true);
    await widget.app.registerForSession(widget.session, {
      'name': _name.text.trim(),
      'email': email,
      'phone': _phone.text.trim(),
      'session_title': widget.session.title,
      'mode': widget.session.mode,
    });
    if (mounted) Navigator.of(context).maybePop();
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String icon;
  final bool active;
  final Color accent;
  final bool small;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.icon,
    required this.active,
    required this.accent,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(horizontal: small ? 11 : 15, vertical: small ? 6 : 9),
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: .15) : Colors.transparent,
            border: Border.all(color: active ? accent : (h ? accent.withValues(alpha: .5) : T.bdr)),
            borderRadius: BorderRadius.circular(small ? 20 : 9),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(icon, style: TextStyle(fontSize: small ? 11 : 13)),
            const SizedBox(width: 7),
            Text(label,
                style: F.syne(
                    size: small ? 11.5 : 13,
                    weight: FontWeight.w700,
                    color: active ? accent : (h ? T.cream : T.mut))),
          ]),
        ),
      );
}
