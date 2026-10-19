import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../widgets/chrome.dart';
import '../services/link_service.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pad = isNarrow(context) ? 16.0 : 24.0;
    final events = app.platformEvents;
    return PageFrame(
      title: 'Events',
      body: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro(
              eyebrow: 'On the calendar',
              motif: 'crew',
              title: 'Castings, open houses, weeks.',
              dek: 'Live and upcoming AOneGo9 events. Anything marked on the poster also runs in the red LIVE bar at the top of browse.',
            ),
            const SizedBox(height: 8),
            if (app.eventsLoading && events.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: T.gold)),
              )
            else if (events.isEmpty)
              EmptyState(
                icon: Icons.event_outlined,
                title: 'No events on the calendar yet',
                message: 'Castings, open houses and weeks appear here as soon as the desk posts them.',
                actionLabel: 'Get the digest',
                onAction: () => app.setView('newsletter'),
              )
            else
              LayoutBuilder(builder: (context, bc) {
                final cols = bc.maxWidth >= 840 ? 2 : 1;
                const gap = 16.0;
                final w = (bc.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final e in events) SizedBox(width: w, child: _EventCard(event: e)),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final onPoster = event['on_poster'] == true;
    final date = '${event['date'] ?? ''}';
    final end = '${event['end_date'] ?? ''}';
    final dateLine = end.isNotEmpty && end != date ? '$date  →  $end' : date;
    final bg = (event['bg'] as num?)?.toInt() ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: T.card,
        border: Border.all(color: onPoster ? T.gold.withValues(alpha: .4) : T.bdr),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: AspectRatio(
              aspectRatio: 0.72,
              child: GradientArt(
                bgIndex: bg,
                emoji: event['emoji']?.toString() ?? '📅',
                emojiSize: 32,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Pill(text: '${event['status'] ?? 'upcoming'}'.toUpperCase(), gold: false),
                      if (onPoster) const _Pill(text: 'ON POSTER', gold: true),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(event['title']?.toString() ?? '',
                      style: F.fraunces(size: 18, weight: FontWeight.w700, color: T.cream, height: 1.2)),
                  const SizedBox(height: 8),
                  Text(dateLine, style: F.mono(size: 11, color: T.gold)),
                  const SizedBox(height: 6),
                  Text(
                    [event['venue'], event['city']].where((s) => (s ?? '').toString().isNotEmpty).join('  ·  '),
                    style: F.syne(size: 12.5, weight: FontWeight.w500, color: T.mut),
                  ),
                  if ((event['blurb'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(event['blurb'].toString(),
                        style: F.syne(size: 13, weight: FontWeight.w400, color: T.dim, height: 1.5)),
                  ],
                  if ('${event['status'] ?? ''}'.toLowerCase() != 'past') ...[
                    const SizedBox(height: 14),
                    HoverFx(
                      onTap: () => showEventBooking(context, context.read<AppState>(), event),
                      builder: (h) => AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: h ? T.gold : T.cream,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.confirmation_number_outlined, size: 15, color: T.onAccent(h ? T.gold : T.cream)),
                          const SizedBox(width: 7),
                          Text('Book a spot',
                              style: F.syne(size: 12.5, weight: FontWeight.w700, color: T.onAccent(h ? T.gold : T.cream))),
                        ]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final bool gold;
  const _Pill({required this.text, required this.gold});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: gold ? T.gold.withValues(alpha: .12) : T.surf,
        border: Border.all(color: gold ? T.gold.withValues(alpha: .4) : T.bdr),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: F.syne(size: 9.5, weight: FontWeight.w700, color: gold ? T.gold : T.dim, letterSpacing: 1.2)),
    );
  }
}

/// Book a place at an event. Events with their own ticketing link go there;
/// the rest collect name / email / phone / party size and send it to the desk.
void showEventBooking(BuildContext context, AppState app, Map<String, dynamic> event) {
  final url = '${event['register_url'] ?? ''}'.trim();
  if (url.isNotEmpty) {
    LinkService.open(url).then((ok) {
      if (!ok) app.showToast('Could not open booking link', url, '⚠️');
    });
    return;
  }
  showDialog<void>(
    context: context,
    barrierColor: T.scrim,
    builder: (_) => _EventBookingDialog(event: event, app: app),
  );
}

class _EventBookingDialog extends StatefulWidget {
  final Map<String, dynamic> event;
  final AppState app;
  const _EventBookingDialog({required this.event, required this.app});

  @override
  State<_EventBookingDialog> createState() => _EventBookingDialogState();
}

class _EventBookingDialogState extends State<_EventBookingDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  int _guests = 1;
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
    for (final c in [_name, _email, _phone, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final where = [e['venue'], e['city']].where((x) => '${x ?? ''}'.isNotEmpty).join(' · ');
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isNarrow(context) ? 16 : 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          decoration: BoxDecoration(color: T.card, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                decoration: BoxDecoration(color: T.surf, border: Border(bottom: BorderSide(color: T.bdr))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('BOOK A SPOT',
                      style: F.syne(size: 9.5, weight: FontWeight.w800, color: T.gold, letterSpacing: 1.6)),
                  const SizedBox(height: 8),
                  Text('${e['title'] ?? ''}', style: F.fraunces(size: 19, weight: FontWeight.w700, color: T.cream, height: 1.2)),
                  const SizedBox(height: 6),
                  Text([e['date'], where].where((x) => '${x ?? ''}'.isNotEmpty).join(' · '),
                      style: F.mono(size: 10.5, color: T.dim)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Field('Your name', Fi('Full name', controller: _name)),
                  const SizedBox(height: 12),
                  Field('Email', Fi('you@example.com', keyboardType: TextInputType.emailAddress, controller: _email)),
                  const SizedBox(height: 12),
                  Field('Phone', Fi('+91 …', keyboardType: TextInputType.phone, controller: _phone)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Text('Guests', style: F.syne(size: 13, weight: FontWeight.w600, color: T.text))),
                    _Step(icon: Icons.remove_rounded, onTap: _guests > 1 ? () => setState(() => _guests--) : null),
                    SizedBox(
                      width: 40,
                      child: Text('$_guests',
                          textAlign: TextAlign.center, style: F.syne(size: 15, weight: FontWeight.w700, color: T.cream)),
                    ),
                    _Step(icon: Icons.add_rounded, onTap: _guests < 10 ? () => setState(() => _guests++) : null),
                  ]),
                  const SizedBox(height: 12),
                  Field('Note (optional)', Fi('Role, agency, anything the desk should know', controller: _note)),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(
                      child: HoverFx(
                        onTap: () => Navigator.of(context).maybePop(),
                        builder: (h) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(border: Border.all(color: h ? T.bdhi : T.bdr), borderRadius: BorderRadius.circular(6)),
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
                            color: _busy ? T.goldDark : (h ? T.gold : T.cream),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_busy ? 'Booking…' : 'Request booking',
                              style: F.syne(
                                  size: 12.5,
                                  weight: FontWeight.w700,
                                  color: T.onAccent(_busy ? T.goldDark : (h ? T.gold : T.cream)))),
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
            ]),
          ),
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
    final ok = await widget.app.bookEvent(widget.event, {
      'name': _name.text.trim(),
      'email': email,
      'phone': _phone.text.trim(),
      'guests': _guests,
      'message': _note.text.trim(),
    });
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).maybePop();
    } else {
      // Keep what they typed so a retry is one tap.
      setState(() => _busy = false);
    }
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _Step({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: onTap == null ? T.bdr : (h ? T.gold : T.bdhi)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: onTap == null ? T.faint : T.text),
        ),
      );
}
