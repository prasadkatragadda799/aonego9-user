import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils/phone_util.dart';
import '../data/geo.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

/// ── ADVERTISE — "Grow your business with AOneGo9" ─────────────────
///
/// The brief: the same shape as Justdial's advertise page, selling what the
/// production house actually does — listings and display ads on AOneGo9,
/// Instagram/Meta campaigns, social media management, graphic design and
/// shoots — to artists, vendors, organisations, and businesses that are not
/// on the platform yet. Every path ends in a callback from the team, so the
/// page is two lead captures (a one-field callback up top, the full brief
/// below) around the pitch.
class AdvertiseScreen extends StatefulWidget {
  const AdvertiseScreen({super.key});
  @override
  State<AdvertiseScreen> createState() => _AdvertiseScreenState();
}

class _AdvertiseScreenState extends State<AdvertiseScreen> {
  final _briefKey = GlobalKey();

  void _toBrief() {
    final ctx = _briefKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = isNarrow(context) ? 16.0 : 24.0;
    return PageFrame(
      title: 'Advertise',
      body: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro(
              eyebrow: 'Advertise with us',
              motif: 'spaces',
              title: 'Grow your business with AOneGo9.',
              dek:
                  'Listings, display ads, Instagram & Meta campaigns, and the shoots behind them — planned and produced by one team.',
            ),
            const SizedBox(height: 8),
            const _CallbackCard(),
            const SizedBox(height: 28),
            const _Benefits(),
            const SizedBox(height: 36),
            const _Label('WHO IT IS FOR'),
            const SizedBox(height: 14),
            const _Audience(),
            const SizedBox(height: 36),
            const _Label('WHAT WE DO FOR YOU'),
            const SizedBox(height: 14),
            _Services(onPick: _toBrief),
            const SizedBox(height: 36),
            const _Label('HOW IT WORKS'),
            const SizedBox(height: 14),
            const _Steps(),
            const SizedBox(height: 36),
            KeyedSubtree(key: _briefKey, child: const _BriefForm()),
            const SizedBox(height: 36),
            const _Label('QUESTIONS'),
            const SizedBox(height: 10),
            const _Faq(),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 2));
}

/// The one-field "call me" box — the first thing on the page, like the
/// mobile-number box on Justdial's.
class _CallbackCard extends StatefulWidget {
  const _CallbackCard();
  @override
  State<_CallbackCard> createState() => _CallbackCardState();
}

class _CallbackCardState extends State<_CallbackCard> {
  final _phone = TextEditingController();
  bool _busy = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _phone.text = '${context.read<AppState>().currentUser?['phone'] ?? ''}';
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = context.read<AppState>();
    final phone = cleanIndianMobile(_phone.text);
    if (phone == null) {
      app.showToast('Check the number', 'Enter a 10-digit mobile number', '⚠️');
      return;
    }
    setState(() => _busy = true);
    final ok = await app.submitLead('advertise_callback', {'phone': phone, 'city': app.location});
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(narrow ? 18 : 24),
      decoration: BoxDecoration(
        color: T.card,
        border: Border.all(color: T.gold.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: _done
          ? Row(children: [
              const Text('✅', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Thanks — our team will call you shortly to plan your campaign.',
                    style: F.syne(size: 14, weight: FontWeight.w600, color: T.text, height: 1.5)),
              ),
            ])
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Get a call from our team',
                    style: F.fraunces(size: narrow ? 19 : 22, weight: FontWeight.w700, color: T.cream)),
                const SizedBox(height: 4),
                Text('Tell us your number — we\'ll help you pick the right plan for your business.',
                    style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.5)),
                const SizedBox(height: 14),
                Flex(
                  direction: narrow ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: narrow ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: narrow ? 0 : 1,
                      child: Fi('+91  Mobile number', keyboardType: TextInputType.phone, controller: _phone),
                    ),
                    SizedBox(width: narrow ? 0 : 10, height: narrow ? 10 : 0),
                    HoverFx(
                      onTap: _busy ? () {} : _submit,
                      builder: (h) => Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: h ? T.goldDark : T.gold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _busy
                            ? SizedBox(
                                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: T.bg))
                            : Text('Get started →', style: F.syne(size: 13, weight: FontWeight.w700, color: T.bg)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('By continuing you agree to be contacted by AOneGo9 about advertising.',
                    style: F.syne(size: 11, weight: FontWeight.w400, color: T.dim)),
              ],
            ),
    );
  }
}

/// Wraps [children] into 1–[maxCols] equal columns depending on width.
Widget _grid(List<Widget> children, {int maxCols = 3, double gap = 12}) => LayoutBuilder(builder: (context, bc) {
      final cols = bc.maxWidth >= 840 ? maxCols : (bc.maxWidth >= 520 ? 2 : 1);
      final w = (bc.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final c in children) SizedBox(width: w, child: c)],
      );
    });

class _InfoCard extends StatelessWidget {
  final String icon;
  final String title;
  final String body;
  const _InfoCard(this.icon, this.title, this.body);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: T.card,
          border: Border.all(color: T.bdr),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 10),
            Text(title, style: F.syne(size: 14, weight: FontWeight.w700, color: T.cream)),
            const SizedBox(height: 6),
            Text(body, style: F.syne(size: 12.5, weight: FontWeight.w400, color: T.mut, height: 1.5)),
          ],
        ),
      );
}

class _Benefits extends StatelessWidget {
  const _Benefits();
  @override
  Widget build(BuildContext context) => _grid(const [
        _InfoCard('📞', 'Genuine enquiries',
            'People searching for talent, venues and vendors reach you directly by call, WhatsApp or enquiry.'),
        _InfoCard('🎬', 'Production in-house',
            'Our own team designs the graphics, shoots the photos and cuts the videos for your ads.'),
        _InfoCard('📈', 'On AOneGo9 and beyond', 'Show your ad on AOneGo9, or run it on Instagram and Meta — or both.'),
      ]);
}

class _Audience extends StatelessWidget {
  const _Audience();
  @override
  Widget build(BuildContext context) => _grid(maxCols: 4, const [
        _InfoCard('⭐', 'Artists', 'Models, makeup artists, photographers, dancers — get booked more.'),
        _InfoCard('🏪', 'Vendors', 'Venues, caterers, decorators, studios — fill your calendar.'),
        _InfoCard('🏢', 'Organisations', 'Agencies, academies and brands promoting events or programmes.'),
        _InfoCard('🚀', 'Any business', 'Not listed with us yet? We can still run your marketing.'),
      ]);
}

/// The services on offer. Shared by the cards and the brief form's chips so
/// the two can never drift apart.
const _services = <(String, String, String)>[
  (
    '📋',
    'Listing on AOneGo9',
    'A verified profile in the right category and city, so clients find you when they search.'
  ),
  ('🖼️', 'Display ads on AOneGo9', 'Photo and video banners on the home page and category pages.'),
  ('📱', 'Instagram & Meta ads', 'Campaigns planned, run and reported by our team.'),
  ('💬', 'Social media management', 'Posting, stories and replies handled for you every month.'),
  ('🎨', 'Graphic design', 'Posters, creatives and brand assets for your ads and pages.'),
  ('🎥', 'Video production', 'Reels, promos and showreels — script to final cut.'),
  ('📸', 'Photo shoots', 'Portfolio, product and campaign shoots with our crew.'),
  ('📣', 'PR & promotion', 'Events, launches and press — get your name out.'),
];

class _Services extends StatelessWidget {
  final VoidCallback onPick;
  const _Services({required this.onPick});

  @override
  Widget build(BuildContext context) => _grid(maxCols: 4, [
        for (final s in _services)
          HoverFx(
            onTap: () {
              _BriefFormState.preselect?.call(s.$2);
              onPick();
            },
            builder: (h) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: T.card,
                border: Border.all(color: h ? T.gold : T.bdr),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.$1, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 10),
                  Text(s.$2, style: F.syne(size: 14, weight: FontWeight.w700, color: T.cream)),
                  const SizedBox(height: 6),
                  Text(s.$3, style: F.syne(size: 12.5, weight: FontWeight.w400, color: T.mut, height: 1.5)),
                  const SizedBox(height: 10),
                  Text('Enquire →', style: F.syne(size: 12, weight: FontWeight.w700, color: T.gold)),
                ],
              ),
            ),
          ),
      ]);
}

class _Steps extends StatelessWidget {
  const _Steps();

  static const items = [
    ['01', 'Tell us', 'Leave your number or the brief below.'],
    ['02', 'Plan', 'We call you, understand the business and suggest a plan.'],
    ['03', 'Produce', 'Our team designs, shoots and edits the creatives.'],
    ['04', 'Go live', 'Your ads run on AOneGo9, Instagram or Meta — and the enquiries come to you.'],
  ];

  @override
  Widget build(BuildContext context) => _grid(maxCols: 4, [
        for (final s in items)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: T.card,
              border: Border.all(color: T.bdr),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s[0], style: F.fraunces(size: 18, weight: FontWeight.w700, color: T.gold)),
                const SizedBox(height: 8),
                Text(s[1], style: F.syne(size: 14, weight: FontWeight.w700, color: T.cream)),
                const SizedBox(height: 6),
                Text(s[2], style: F.syne(size: 12.5, weight: FontWeight.w400, color: T.mut, height: 1.5)),
              ],
            ),
          ),
      ]);
}

/// The full brief: who they are, what they want, how to reach them.
class _BriefForm extends StatefulWidget {
  const _BriefForm();
  @override
  State<_BriefForm> createState() => _BriefFormState();
}

class _BriefFormState extends State<_BriefForm> {
  /// Lets a service card tick its chip here before scrolling down.
  static void Function(String)? preselect;

  final _name = TextEditingController();
  final _business = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _msg = TextEditingController();
  final Set<String> _picked = {};
  String _type = 'Artist';
  String _city = 'Mumbai';
  String _budget = 'Not sure yet';
  bool _busy = false;
  bool _done = false;

  static const _types = ['Artist', 'Vendor', 'Organisation', 'Other business'];
  static const _budgets = [
    'Not sure yet',
    'Under ₹10,000 / month',
    '₹10,000 – ₹50,000 / month',
    'Above ₹50,000 / month'
  ];

  @override
  void initState() {
    super.initState();
    preselect = (s) => setState(() => _picked.add(s));
    // A signed-in visitor shouldn't have to type themselves in again.
    final u = context.read<AppState>().currentUser;
    _name.text = '${u?['name'] ?? ''}';
    _phone.text = '${u?['phone'] ?? ''}';
    _email.text = '${u?['email'] ?? ''}';
  }

  @override
  void dispose() {
    preselect = null;
    for (final c in [_name, _business, _phone, _email, _msg]) {
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
    if (_picked.isEmpty) {
      app.showToast('Pick a service', 'Choose at least one thing you want help with', '⚠️');
      return;
    }
    setState(() => _busy = true);
    final ok = await app.submitLead('advertise', {
      'name': _name.text.trim(),
      'business_name': _business.text.trim(),
      'business_type': _type,
      'phone': phone,
      'email': _email.text.trim(),
      'city': _city,
      'services': _picked.toList(),
      'budget': _budget,
      'message': _msg.text.trim(),
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = ok;
    });
    if (!ok) app.showToast('Couldn\'t send', 'Check your connection and try again', '⚠️');
  }

  Widget _pair(Widget a, Widget b) => isNarrow(context)
      ? Column(children: [a, const SizedBox(height: 12), b])
      : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ]);

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(narrow ? 18 : 28),
      decoration: BoxDecoration(
        color: T.card,
        border: Border.all(color: T.gold.withValues(alpha: .28)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: _done
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✅', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 10),
                Text('Brief received', style: F.fraunces(size: 22, weight: FontWeight.w700, color: T.cream)),
                const SizedBox(height: 6),
                Text('Our team will call you within one working day to plan your campaign.',
                    style: F.syne(size: 14, weight: FontWeight.w400, color: T.mut, height: 1.6)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tell us about your business',
                    style: F.fraunces(size: narrow ? 20 : 24, weight: FontWeight.w700, color: T.cream)),
                const SizedBox(height: 6),
                Text('Pick what you need — one service or all of them. We\'ll come back with a plan and a price.',
                    style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.5)),
                const SizedBox(height: 18),
                const Fl('I need help with'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _services)
                      HoverFx(
                        onTap: () => setState(() => _picked.contains(s.$2) ? _picked.remove(s.$2) : _picked.add(s.$2)),
                        builder: (h) {
                          final on = _picked.contains(s.$2);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: on ? T.gold : (h ? T.gold.withValues(alpha: .08) : T.surf),
                              border: Border.all(color: on ? T.gold : T.bdr),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${s.$1}  ${s.$2}',
                                style: F.syne(size: 12.5, weight: FontWeight.w600, color: on ? T.bg : T.text)),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _pair(
                  Field('Your name', Fi('Full name', controller: _name)),
                  Field('Business / stage name', Fi('Optional', controller: _business)),
                ),
                const SizedBox(height: 12),
                _pair(
                  Field('Mobile', Fi('+91 …', keyboardType: TextInputType.phone, controller: _phone)),
                  Field('Email', Fi('Optional', keyboardType: TextInputType.emailAddress, controller: _email)),
                ),
                const SizedBox(height: 12),
                _pair(
                  Field('You are', FiSelect(options: _types, value: _type, onChanged: (v) => _type = v ?? _type)),
                  Field('City',
                      FiSelect(options: GeoIndex.cityNames, value: _city, onChanged: (v) => _city = v ?? _city)),
                ),
                const SizedBox(height: 12),
                Field('Monthly budget',
                    FiSelect(options: _budgets, value: _budget, onChanged: (v) => _budget = v ?? _budget)),
                const SizedBox(height: 12),
                Field('Anything else', Fi('What you do, what you want to promote…', controller: _msg, minLines: 3)),
                const SizedBox(height: 18),
                HoverFx(
                  onTap: _busy ? () {} : _submit,
                  builder: (h) => Container(
                    width: narrow ? double.infinity : null,
                    alignment: narrow ? Alignment.center : null,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                    decoration: BoxDecoration(color: h ? T.goldDark : T.gold, borderRadius: BorderRadius.circular(8)),
                    child: _busy
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: T.bg))
                        : Text('Send my brief →', style: F.syne(size: 13, weight: FontWeight.w700, color: T.bg)),
                  ),
                ),
                const SizedBox(height: 12),
                HoverFx(
                  onTap: () => context.read<AppState>().openConnect('apply'),
                  builder: (h) => Text('Just want a free listing? Apply here →',
                      style: F
                          .syne(size: 12.5, weight: FontWeight.w600, color: T.gold)
                          .copyWith(decoration: h ? TextDecoration.underline : TextDecoration.none)),
                ),
              ],
            ),
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq();

  static const items = [
    (
      'Do I need to be listed on AOneGo9 to advertise?',
      'No. We run Instagram, Meta and social media campaigns for businesses that are not on the platform too. If you want a listing as well, we set it up.'
    ),
    (
      'Where will my ads be shown?',
      'On AOneGo9 (home page and category pages), on Instagram and Facebook through Meta ads, or both — you choose.'
    ),
    (
      'Do you make the creatives?',
      'Yes. Our production team designs graphics, shoots photos and edits videos for your campaign.'
    ),
    (
      'How much does it cost?',
      'It depends on the services and how long you run them. Share your brief and we\'ll send a plan with a clear price.'
    ),
    (
      'Can I stop or change my plan later?',
      'Yes. Talk to your AOneGo9 contact and we\'ll pause, change or extend the campaign.'
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final q in items)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: T.card,
                  border: Border.all(color: T.bdr),
                  borderRadius: BorderRadius.circular(10),
                ),
                // A Material of its own, or the tile's ink has nothing to
                // paint on inside the decorated box.
                child: Material(
                  type: MaterialType.transparency,
                  child: ExpansionTile(
                    iconColor: T.gold,
                    collapsedIconColor: T.dim,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    title: Text(q.$1, style: F.syne(size: 13.5, weight: FontWeight.w600, color: T.text)),
                    children: [
                      Text(q.$2, style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.6)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
}
