import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/taxonomy.dart';
import '../data/geo.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

/// Contact us · Join us · Apply — the three lead forms from the brief, in one
/// screen with a tab per intent.
///
/// They are one screen rather than three because they collect the same core
/// identity (name, email, phone, city) and differ only in what they ask after
/// that. Splitting them would have meant three near-identical files and three
/// places to fix a validation bug.
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  static const _tabs = [
    ('contact', 'Contact us', '✉️', 'Questions, press, bookings support.'),
    ('join', 'Join us', '🤝', 'Work at AOneGo9 — desks, editorial, partnerships.'),
    ('apply', 'Apply', '📝', 'List yourself as an artist, or your business as a vendor.'),
  ];

  late String _tab = context.read<AppState>().connectTab;

  @override
  Widget build(BuildContext context) {
    final pad = isNarrow(context) ? 16.0 : 24.0;
    final active = _tabs.firstWhere((t) => t.$1 == _tab, orElse: () => _tabs.first);

    return PageFrame(
      title: 'Connect',
      body: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageIntro(
              eyebrow: 'Talk to the desk',
              title: active.$4,
              dek: 'Everything here lands with a real person at AOneGo9. Credentials first — '
                  'the desk verifies before anything goes on the public floor.',
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _tabs)
                  _TabChip(
                    label: t.$2,
                    icon: t.$3,
                    active: _tab == t.$1,
                    onTap: () => setState(() => _tab = t.$1),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            switch (_tab) {
              'join' => const _JoinForm(),
              'apply' => const _ApplyForm(),
              _ => const _ContactForm(),
            },
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool active;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: active ? T.gold.withValues(alpha: .14) : (h ? T.card : Colors.transparent),
            border: Border.all(color: active ? T.gold : T.bdr),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            Text(label,
                style: F.syne(
                    size: 13,
                    weight: FontWeight.w700,
                    color: active ? T.gold : (h ? T.cream : T.mut))),
          ]),
        ),
      );
}

/// ── Shared form shell ───────────────────────────────────────────
/// Owns the card chrome, the submit button, the busy state and the
/// success panel, so each form below is just its fields plus a payload.
class _FormShell extends StatefulWidget {
  final String title;
  final String blurb;
  final String kind;
  final String cta;
  final String successTitle;
  final String successBody;

  /// Returns the payload, or null when validation fails (the builder is
  /// responsible for toasting what is missing).
  final Map<String, dynamic>? Function() collect;
  final List<Widget> Function() fields;

  const _FormShell({
    required this.title,
    required this.blurb,
    required this.kind,
    required this.cta,
    required this.successTitle,
    required this.successBody,
    required this.collect,
    required this.fields,
  });

  @override
  State<_FormShell> createState() => _FormShellState();
}

class _FormShellState extends State<_FormShell> {
  bool _busy = false;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();

    if (_done) {
      return Container(
        padding: EdgeInsets.all(isNarrow(context) ? 22 : 32),
        decoration: BoxDecoration(
          color: T.surf,
          border: Border.all(color: T.grn.withValues(alpha: .35)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: T.grn.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('✓', style: TextStyle(fontSize: 18, color: T.grn)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(widget.successTitle,
                  style: F.fraunces(size: 22, weight: FontWeight.w700, color: T.cream)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(widget.successBody,
              style: F.syne(size: 13.5, weight: FontWeight.w400, color: T.mut, height: 1.7)),
          const SizedBox(height: 18),
          HoverFx(
            onTap: () => setState(() => _done = false),
            builder: (h) => Text('Send another →',
                style: F.syne(size: 12.5, weight: FontWeight.w700, color: h ? T.goldLight : T.gold)),
          ),
        ]),
      );
    }

    return Container(
      padding: EdgeInsets.all(isNarrow(context) ? 18 : 28),
      decoration: BoxDecoration(
        color: T.surf,
        border: Border.all(color: T.bdr),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: F.fraunces(size: 24, weight: FontWeight.w700, color: T.cream)),
          const SizedBox(height: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(widget.blurb,
                style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.65)),
          ),
          const SizedBox(height: 20),
          ...widget.fields(),
          const SizedBox(height: 20),
          HoverFx(
            onTap: _busy
                ? null
                : () async {
                    final payload = widget.collect();
                    if (payload == null) return;
                    setState(() => _busy = true);
                    final ok = await app.submitLead(widget.kind, payload);
                    if (!mounted) return;
                    setState(() {
                      _busy = false;
                      _done = ok;
                    });
                    if (!ok) {
                      app.showToast('Could not send', 'Check your connection and try again', '⚠️');
                    }
                  },
            builder: (h) => AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              decoration: BoxDecoration(
                color: _busy ? T.goldDark : (h ? T.goldLight : T.gold),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(_busy ? 'Sending…' : widget.cta,
                  style: F.syne(size: 13.5, weight: FontWeight.w700, color: T.bg)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two fields side by side on desktop, stacked on a phone.
class _Pair extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _Pair({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    if (isNarrow(context)) {
      return Column(children: [left, const SizedBox(height: 12), right]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 14),
        Expanded(child: right),
      ],
    );
  }
}

bool _emailLooksReal(String v) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(v.trim());

/// ── Contact ─────────────────────────────────────────────────────
class _ContactForm extends StatefulWidget {
  const _ContactForm();
  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _msg = TextEditingController();
  String _topic = 'General inquiry';
  String _city = 'Mumbai';

  static const _topics = [
    'General inquiry',
    'Booking support',
    'Report a listing',
    'Press & media',
    'Partnership',
    'Billing & subscription',
  ];

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _msg]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      kind: 'contact',
      title: 'Contact us',
      blurb: 'Questions about a booking, a listing or the platform. The desk replies within one working day.',
      cta: 'Send message →',
      successTitle: 'Message received',
      successBody: 'A member of the desk will reply to the email you gave, usually within one working day.',
      collect: () {
        final app = context.read<AppState>();
        if (_name.text.trim().isEmpty || !_emailLooksReal(_email.text) || _msg.text.trim().length < 10) {
          app.showToast('Check the form', 'Name, a valid email and a message of at least 10 characters', '⚠️');
          return null;
        }
        return {
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'city': _city,
          'topic': _topic,
          'message': _msg.text.trim(),
        };
      },
      fields: () => [
        _Pair(
          left: Field('Your name', Fi('Full name', controller: _name)),
          right: Field('Email', Fi('you@example.com', keyboardType: TextInputType.emailAddress, controller: _email)),
        ),
        const SizedBox(height: 12),
        _Pair(
          left: Field('Phone', Fi('+91 …', keyboardType: TextInputType.phone, controller: _phone)),
          right: Field('City', FiSelect(options: GeoIndex.cityNames, value: _city, onChanged: (v) => _city = v ?? _city)),
        ),
        const SizedBox(height: 12),
        Field('What is this about', FiSelect(options: _topics, value: _topic, onChanged: (v) => _topic = v ?? _topic)),
        const SizedBox(height: 12),
        Field('Message', Fi('Tell us what you need…', controller: _msg, minLines: 4)),
      ],
    );
  }
}

/// ── Join us ─────────────────────────────────────────────────────
class _JoinForm extends StatefulWidget {
  const _JoinForm();
  @override
  State<_JoinForm> createState() => _JoinFormState();
}

class _JoinFormState extends State<_JoinForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _portfolio = TextEditingController();
  final _note = TextEditingController();
  String _desk = 'Casting Desk';
  String _experience = '1–3 years';
  String _city = 'Mumbai';

  static const _desks = [
    'Casting Desk',
    'Production Desk',
    'Verification & KYC',
    'Editorial / The Digest',
    'Partnerships',
    'Engineering & Product',
    'Marketing & Social',
  ];
  static const _experiences = ['Student / intern', '0–1 years', '1–3 years', '3–6 years', '6+ years'];

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _portfolio, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      kind: 'join',
      title: 'Join the desk',
      blurb: 'AOneGo9 runs on people who have actually worked a set, a week or a shoot. '
          'Tell us which desk and what you have shipped.',
      cta: 'Send application →',
      successTitle: 'Application in',
      successBody: 'We read every one. If your background fits an open desk you will hear from us directly.',
      collect: () {
        final app = context.read<AppState>();
        if (_name.text.trim().isEmpty || !_emailLooksReal(_email.text) || _note.text.trim().length < 20) {
          app.showToast('Check the form', 'Name, a valid email and a few lines about your work', '⚠️');
          return null;
        }
        return {
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'city': _city,
          'desk': _desk,
          'experience': _experience,
          'portfolio': _portfolio.text.trim(),
          'message': _note.text.trim(),
        };
      },
      fields: () => [
        _Pair(
          left: Field('Your name', Fi('Full name', controller: _name)),
          right: Field('Email', Fi('you@example.com', keyboardType: TextInputType.emailAddress, controller: _email)),
        ),
        const SizedBox(height: 12),
        _Pair(
          left: Field('Phone', Fi('+91 …', keyboardType: TextInputType.phone, controller: _phone)),
          right: Field('City', FiSelect(options: GeoIndex.cityNames, value: _city, onChanged: (v) => _city = v ?? _city)),
        ),
        const SizedBox(height: 12),
        _Pair(
          left: Field('Which desk', FiSelect(options: _desks, value: _desk, onChanged: (v) => _desk = v ?? _desk)),
          right: Field('Experience', FiSelect(options: _experiences, value: _experience, onChanged: (v) => _experience = v ?? _experience)),
        ),
        const SizedBox(height: 12),
        Field('Portfolio / LinkedIn', Fi('A link we can look at', controller: _portfolio)),
        const SizedBox(height: 12),
        Field('What have you worked on', Fi('Sets, weeks, campaigns, shipped products…', controller: _note, minLines: 4)),
      ],
    );
  }
}

/// ── Apply (artist / vendor) ─────────────────────────────────────
class _ApplyForm extends StatefulWidget {
  const _ApplyForm();
  @override
  State<_ApplyForm> createState() => _ApplyFormState();
}

class _ApplyFormState extends State<_ApplyForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _business = TextEditingController();
  final _instagram = TextEditingController();
  final _portfolio = TextEditingController();
  final _note = TextEditingController();

  /// 'artist' lists a person; 'vendor' lists a business. The brief asks for
  /// both in one "apply from types of artist and vendor".
  String _as = 'artist';
  String _catId = 'modelF';
  String _city = 'Mumbai';
  String _experience = '1–3 years';

  static const _experiences = ['Just starting', '0–1 years', '1–3 years', '3–6 years', '6+ years'];

  bool get _isVendor => _as == 'vendor';

  /// Artists pick from talent + beauty + post; vendors from everything that
  /// is a business. Offering "Hotels" to someone applying as an artist is
  /// the kind of thing that makes a form feel unconsidered.
  List<Cat> get _options {
    if (_isVendor) {
      return catalogue.where((c) => !c.isTalent).toList();
    }
    return catalogue
        .where((c) => c.isTalent || c.division == 'beauty' || c.division == 'post' || c.id == 'photo' || c.id == 'video')
        .toList();
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _business, _instagram, _portfolio, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setRole(String role) {
    setState(() {
      _as = role;
      // The previously chosen category may not exist in the new role's list.
      if (!_options.any((c) => c.id == _catId)) _catId = _options.first.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    final labels = options.map((c) => '${c.icon}  ${c.name}').toList();
    final currentLabel = labels[options.indexWhere((c) => c.id == _catId).clamp(0, labels.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _RoleCard(
            label: 'I am an artist',
            hint: 'Model, makeup artist, editor, photographer',
            icon: '✦',
            active: !_isVendor,
            onTap: () => _setRole('artist'),
          ),
          const SizedBox(width: 12),
          _RoleCard(
            label: 'I am a vendor',
            hint: 'Studio, showroom, venue, hotel, academy',
            icon: '⌂',
            active: _isVendor,
            onTap: () => _setRole('vendor'),
          ),
        ]),
        const SizedBox(height: 18),
        _FormShell(
          // The kind carries the role, so the desk can route artist and vendor
          // applications to different queues without parsing the payload.
          kind: _isVendor ? 'apply_vendor' : 'apply_artist',
          title: _isVendor ? 'List your business' : 'List yourself as talent',
          blurb: _isVendor
              ? 'Studios, showrooms, venues, hotels and academies. Verification happens before you appear on the public floor.'
              : 'Models, makeup artists, editors, photographers and crew. Bring a book we can actually look at.',
          cta: 'Submit application →',
          successTitle: 'Application received',
          successBody:
              'The verification desk reviews every application. You will get an email with what to send next — '
              'ID, work samples and, for businesses, registration details.',
          collect: () {
            final app = context.read<AppState>();
            if (_name.text.trim().isEmpty || !_emailLooksReal(_email.text) || _phone.text.trim().length < 6) {
              app.showToast('Check the form', 'Name, a valid email and a reachable phone number', '⚠️');
              return null;
            }
            if (_isVendor && _business.text.trim().isEmpty) {
              app.showToast('Business name missing', 'Vendors must give the name the business trades under', '⚠️');
              return null;
            }
            if (_portfolio.text.trim().isEmpty && _instagram.text.trim().isEmpty) {
              app.showToast('Show us the work', 'A portfolio link or an Instagram handle is required', '⚠️');
              return null;
            }
            return {
              'role': _as,
              'name': _name.text.trim(),
              'email': _email.text.trim(),
              'phone': _phone.text.trim(),
              'business_name': _business.text.trim(),
              'category': _catId,
              'category_name': catOf(_catId)?.name ?? _catId,
              'city': _city,
              'state': GeoIndex.stateOfCity(_city),
              'experience': _experience,
              'instagram': _instagram.text.trim(),
              'portfolio': _portfolio.text.trim(),
              'message': _note.text.trim(),
            };
          },
          fields: () => [
            _Pair(
              left: Field(_isVendor ? 'Contact person' : 'Your name', Fi('Full name', controller: _name)),
              right: Field('Email', Fi('you@example.com', keyboardType: TextInputType.emailAddress, controller: _email)),
            ),
            const SizedBox(height: 12),
            _Pair(
              left: Field('Phone', Fi('+91 …', keyboardType: TextInputType.phone, controller: _phone)),
              right: Field(
                _isVendor ? 'Business name' : 'Stage / professional name',
                Fi(_isVendor ? 'As registered' : 'Optional', controller: _business),
              ),
            ),
            const SizedBox(height: 12),
            _Pair(
              left: Field(
                'Category',
                FiSelect(
                  key: ValueKey('cat-$_as'),
                  options: labels,
                  value: currentLabel,
                  onChanged: (v) {
                    final i = labels.indexOf(v ?? '');
                    if (i >= 0) _catId = options[i].id;
                  },
                ),
              ),
              right: Field('City', FiSelect(options: GeoIndex.cityNames, value: _city, onChanged: (v) => _city = v ?? _city)),
            ),
            const SizedBox(height: 12),
            _Pair(
              left: Field('Experience', FiSelect(options: _experiences, value: _experience, onChanged: (v) => _experience = v ?? _experience)),
              right: Field('Instagram', Fi('@handle', controller: _instagram)),
            ),
            const SizedBox(height: 12),
            Field('Portfolio link', Fi('Drive, website, Behance, YouTube…', controller: _portfolio)),
            const SizedBox(height: 12),
            Field('Anything else', Fi('Rates, travel range, notable work…', controller: _note, minLines: 3)),
          ],
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final String hint;
  final String icon;
  final bool active;
  final VoidCallback onTap;
  const _RoleCard({
    required this.label,
    required this.hint,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: HoverFx(
          onTap: onTap,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: active ? T.gold.withValues(alpha: .10) : (h ? T.card : T.surf),
              border: Border.all(color: active ? T.gold : T.bdr, width: active ? 1.5 : 1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(children: [
              Text(icon, style: TextStyle(fontSize: 17, color: active ? T.gold : T.mut)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(label,
                      style: F.syne(size: 13, weight: FontWeight.w700, color: active ? T.gold : T.cream)),
                  const SizedBox(height: 3),
                  Text(hint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: F.syne(size: 10.5, weight: FontWeight.w400, color: T.dim, height: 1.4)),
                ]),
              ),
            ]),
          ),
        ),
      );
}
