import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../data/programs.dart';
import '../widgets/chrome.dart';
import '../services/link_service.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/program_kit.dart';

/// Events — live events, fashion shows, entertainment, workshops and
/// webinars, split into the two sectors the platform keeps apart:
/// entertainment and education.
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _sector = 'all';
  String _type = 'All';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pad = isNarrow(context) ? 16.0 : 24.0;
    final all = app.platformEvents;
    final events = all
        .where((e) => _sector == 'all' || eventSectorOf(e) == _sector)
        .where((e) => eventMatchesType(e, _type))
        .toList();
    final sessionsInSector = _sector == 'education' ? app.sessions.length : 0;
    return PageFrame(
      title: 'Events',
      body: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageIntro(
              eyebrow: 'On the calendar',
              motif: 'crew',
              title: 'Live events, shows, workshops & webinars.',
              dek: 'Fashion shows, entertainment programmes, castings, fests and education sessions from AOneGo9 and '
                  'third-party organisations — with tickets, registrations and participation in one tap.',
            ),
            const SizedBox(height: 16),
            SegTabs(
              tabs: const [
                ('all', 'All sectors', '🗓️'),
                ('entertainment', 'Entertainment', '🎤'),
                ('education', 'Education', '🎓'),
              ],
              active: _sector,
              onChanged: (v) => setState(() => _sector = v),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in eventTypes) PickChip(label: t, active: _type == t, onTap: () => setState(() => _type = t)),
            ]),
            const SizedBox(height: 16),
            if (app.eventsLoading && all.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: T.gold)),
              )
            else if (events.isEmpty)
              EmptyState(
                icon: Icons.event_outlined,
                title: all.isEmpty ? 'No events on the calendar yet' : 'No events match these filters',
                message: all.isEmpty
                    ? 'Castings, fashion shows, fests and workshops appear here as soon as organisers publish them.'
                    : (sessionsInSector > 0
                        ? '$sessionsInSector workshop${sessionsInSector == 1 ? '' : 's'} and webinars are open on the sessions page.'
                        : 'Try another sector or event type.'),
                actionLabel: all.isEmpty ? 'Get the digest' : (sessionsInSector > 0 ? 'Open sessions' : 'Clear filters'),
                onAction: all.isEmpty
                    ? () => app.setView('newsletter')
                    : (sessionsInSector > 0
                        ? () => app.setView('sessions')
                        : () => setState(() {
                              _sector = 'all';
                              _type = 'All';
                            })),
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
            const SectionTitle('More on the calendar'),
            AutoGrid(minItemWidth: 230, gap: 12, children: [
              _LinkCard(icon: '🎓', title: 'Workshops & webinars', body: 'Seats with a host, a fee and a capacity.', onTap: () => app.setView('sessions')),
              _LinkCard(icon: '🏫', title: 'AOneGo9 Open School', body: 'Courses, intakes and admission forms.', onTap: () => app.setView('academy')),
              _LinkCard(icon: '🎪', title: 'Publish your event', body: 'Organisers: sell tickets and manage registrations.', onTap: () => app.openOnboard('organiser')),
              _LinkCard(icon: '✨', title: 'Plan an event', body: 'AI-assisted budget, timeline and guest notebook.', onTap: () => app.setView('planner')),
            ]),
          ],
        ),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  final String icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  const _LinkCard({required this.icon, required this.title, required this.body, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: title,
        child: HoverFx(
          onTap: onTap,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: T.card,
              border: Border.all(color: h ? T.gold : T.bdr),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: F.syne(size: 13.5, weight: FontWeight.w800, color: T.cream)),
                  const SizedBox(height: 3),
                  Text(body, style: F.syne(size: 11.5, color: T.dim, height: 1.4)),
                ]),
              ),
            ]),
          ),
        ),
      );
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
                      _Pill(text: eventSectorOf(event).toUpperCase(), gold: false),
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
