import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../data/app_data.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

/// Shared `.pnav` bar for vendor screens.
class _Pnav extends StatelessWidget {
  final String title;
  final String? backLabel;
  final VoidCallback? onBack;
  final List<Widget> actions;
  const _Pnav({required this.title, this.backLabel, this.onBack, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xF709090B),
        border: Border(bottom: BorderSide(color: T.bdr)),
      ),
      child: Row(children: [
        if (backLabel != null) ...[
          _PnavBtn(label: backLabel!, onTap: onBack!, back: true),
          const SizedBox(width: 12),
        ],
        Expanded(child: Text(title, style: F.syne(size: 13, weight: FontWeight.w700, color: T.text))),
        ...actions,
      ]),
    );
  }
}

class _PnavBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool back;
  const _PnavBtn({required this.label, required this.onTap, this.back = false});
  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          padding: EdgeInsets.symmetric(horizontal: back ? 14 : 12, vertical: back ? 6 : 5),
          decoration: BoxDecoration(
            color: back ? null : Colors.white.withOpacity(.03),
            border: Border.all(color: h ? (back ? T.bdhi : T.gold) : T.bdr),
            borderRadius: BorderRadius.circular(back ? 6 : 5),
          ),
          child: Text(label, style: F.syne(size: back ? 12 : 11, weight: FontWeight.w600, color: h ? (back ? T.text : T.gold) : T.mut)),
        ),
      );
}

class _PubButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _PubButton({required this.label, required this.onTap, this.color = T.gold});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9)),
          child: Text(label, style: F.syne(size: 15, weight: FontWeight.w700, color: T.bg)),
        ),
      );
}

class _ActButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(color: T.gold, borderRadius: BorderRadius.circular(7)),
          child: Text(label, style: F.syne(size: 13, weight: FontWeight.w700, color: T.bg)),
        ),
      );
}

/// ── VENDOR AUTH ──────────────────────────────
class VendorAuth extends StatefulWidget {
  const VendorAuth({super.key});
  @override
  State<VendorAuth> createState() => _VendorAuthState();
}

class _VendorAuthState extends State<VendorAuth> {
  bool _loading = false;
  void _go(AppState app) {
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _loading = false);
        app.vendorLogin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Container(
      color: T.bg,
      child: Column(children: [
        _Pnav(title: 'Vendor Portal', backLabel: '← Back to Browse', onBack: app.backToBrowse),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 80),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: FadeUp(
                  offset: 28,
                  child: Container(
                    decoration: BoxDecoration(color: T.card, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(14)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: T.bdr))),
                        child: Column(children: [
                          const Text('🔐', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text('Vendor Login', style: F.fraunces(size: 26, weight: FontWeight.w700, color: T.cream)),
                          const SizedBox(height: 5),
                          Text('Sign in to manage your profile, view leads, and update your listings on AOneGo9.',
                              textAlign: TextAlign.center, style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.6)),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          const Field('Business Email', Fi('you@yourbusiness.com', keyboardType: TextInputType.emailAddress)),
                          const SizedBox(height: 11),
                          const Field('Password', Fi('••••••••', obscure: true)),
                          const SizedBox(height: 15),
                          _PubButton(label: _loading ? 'Signing in…' : 'Sign In to Vendor Portal →', onTap: () => _go(app)),
                          const SizedBox(height: 12),
                          Center(
                            child: Wrap(children: [
                              Text('New vendor? ', style: F.syne(size: 12, weight: FontWeight.w400, color: T.dim)),
                              GestureDetector(onTap: () => _go(app), child: Text('Request Access', style: F.syne(size: 12, weight: FontWeight.w700, color: T.gold))),
                            ]),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(color: T.gold.withOpacity(.06), border: Border.all(color: T.gold.withOpacity(.15)), borderRadius: BorderRadius.circular(7)),
                            child: Text('Demo: use any credentials to log in', textAlign: TextAlign.center, style: F.syne(size: 11, weight: FontWeight.w400, color: T.mut)),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// ── VENDOR DASHBOARD ─────────────────────────
class VendorDash extends StatelessWidget {
  const VendorDash({super.key});

  static const _mockLeads = [
    {'name': 'Rahul Sharma', 'req': 'Fashion + film role inquiry for December 2026 project', 'type': 'Film Role', 'time': '2 hrs ago', 'urgent': true},
    {'name': 'Priya Menon', 'req': 'Full day brand campaign — ethnic wear + commercial', 'type': 'Model Booking', 'time': '5 hrs ago', 'urgent': false},
    {'name': 'Sneha Kapoor', 'req': 'Wedding event production — 300 pax — January 2026', 'type': 'Event Booking', 'time': 'Yesterday', 'urgent': false},
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final vp = app.vendorProfiles;
    final stats = [
      {'n': '${vp.length + 1}', 'l': 'Active Profiles'},
      {'n': '${_mockLeads.length}', 'l': 'New Leads'},
      {'n': '12', 'l': 'Leads This Month'},
      {'n': '4.8★', 'l': 'Avg. Rating'},
    ];
    final statCols = isTablet(context) ? 2 : 4;
    final cardCols = screenW(context) <= 600 ? 1 : (screenW(context) <= 940 ? 2 : 3);

    return Container(
      color: T.bg,
      child: Column(children: [
        _Pnav(
          title: 'Vendor Dashboard',
          backLabel: '← Back to Browse',
          onBack: app.backToBrowse,
          actions: [
            _PnavBtn(label: '+ New Profile', onTap: () => app.setView('vendor-edit')),
            const SizedBox(width: 6),
            _PnavBtn(label: 'Log Out', onTap: app.backToBrowse),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 80),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 940),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // head
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12, runSpacing: 12,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text('Welcome back, ${app.vendorName} 👋', style: F.fraunces(size: 26, weight: FontWeight.w700, color: T.cream)),
                        const SizedBox(height: 3),
                        Text('Manage your profiles and view incoming lead inquiries.', style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut)),
                      ]),
                      _ActButton(label: '+ Upload New Profile', onTap: () => app.setView('vendor-edit')),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // stats
                  LayoutBuilder(builder: (context, bc) {
                    const gap = 12.0;
                    final w = (bc.maxWidth - gap * (statCols - 1)) / statCols;
                    return Wrap(spacing: gap, runSpacing: gap, children: [
                      for (final s in stats)
                        Container(
                          width: w,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: T.card, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(10)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            Text(s['n']!, style: F.fraunces(size: 28, weight: FontWeight.w700, color: T.gold, height: 1)),
                            const SizedBox(height: 4),
                            Text(s['l']!, style: F.syne(size: 11, weight: FontWeight.w400, color: T.dim)),
                          ]),
                        ),
                    ]);
                  }),
                  const SizedBox(height: 22),
                  SecHeader('Your Published Profiles'),
                  LayoutBuilder(builder: (context, bc) {
                    const gap = 20.0;
                    final w = (bc.maxWidth - gap * (cardCols - 1)) / cardCols;
                    return Wrap(spacing: gap, runSpacing: gap, children: [
                      SizedBox(width: w, child: _miniCard(name: app.vendorName, accent: T.gold, badge: 'Your Profile', live: 'LIVE', emoji: '⭐', loc: 'Active · Public', foot: '3 leads this week', cta: 'Edit Profile →', onTap: () => app.setView('vendor-edit'), gradIndex: 0)),
                      for (int i = 0; i < vp.length; i++)
                        SizedBox(width: w, child: _miniCard(name: vp[i]['name'] ?? '', accent: T.ac(vp[i]['cat']), badge: null, live: 'LIVE', emoji: vp[i]['emoji'] ?? '🆕', loc: 'Just published', foot: 'New profile', cta: 'Edit →', onTap: () => app.setView('vendor-edit'), gradIndex: i + 1)),
                    ]);
                  }),
                  const SizedBox(height: 24),
                  SecHeader('Recent Leads'),
                  for (final l in _mockLeads) _leadCard(l),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _miniCard({
    required String name,
    required Color accent,
    String? badge,
    required String live,
    required String emoji,
    required String loc,
    required String foot,
    required String cta,
    required VoidCallback onTap,
    required int gradIndex,
  }) {
    return Container(
      decoration: BoxDecoration(color: T.card, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(13)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 160,
          child: Stack(fit: StackFit.expand, children: [
            Container(decoration: BoxDecoration(gradient: T.gr(gradIndex)), alignment: Alignment.center, child: Text(emoji, style: const TextStyle(fontSize: 52))),
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: .68,
                child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xF2000000)]))),
              ),
            ),
            if (badge != null)
              Positioned(top: 12, left: 12, child: _pill(badge.toUpperCase(), accent)),
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4)),
                child: Text('✓ $live', style: F.syne(size: 9, weight: FontWeight.w700, color: T.bg, letterSpacing: .5)),
              ),
            ),
            Positioned(
              left: 16, right: 16, bottom: 14,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(name, style: F.fraunces(size: 15, weight: FontWeight.w700, color: Colors.white, height: 1.15)),
                const SizedBox(height: 2),
                Text(loc, style: F.syne(size: 10, weight: FontWeight.w600, color: accent)),
              ]),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: T.bdr))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(foot, style: F.syne(size: 11, weight: FontWeight.w400, color: T.dim)),
            HoverFx(
              onTap: onTap,
              builder: (h) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: h ? accent.withOpacity(.07) : null, border: Border.all(color: Colors.white.withOpacity(.08)), borderRadius: BorderRadius.circular(6)),
                child: Text(cta, style: F.syne(size: 12, weight: FontWeight.w700, color: accent)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xE009090B), border: Border.all(color: Colors.white.withOpacity(.1)), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: F.syne(size: 9, weight: FontWeight.w700, color: color, letterSpacing: 1.5)),
      );

  Widget _leadCard(Map l) {
    final initials = (l['name'] as String).split(' ').map((w) => w.isEmpty ? '' : w[0]).join();
    return HoverFx(
      builder: (h) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(color: T.card, border: Border.all(color: h ? T.gold.withOpacity(.25) : T.bdr), borderRadius: BorderRadius.circular(10)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: T.gold.withOpacity(.1), border: Border.all(color: T.gold.withOpacity(.2)), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text(initials.length > 2 ? initials.substring(0, 2) : initials, style: F.fraunces(size: 14, weight: FontWeight.w700, color: T.gold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(l['name'] ?? '', style: F.syne(size: 13, weight: FontWeight.w700, color: T.text))),
                if (l['urgent'] == true) ...[
                  _tag('URGENT', T.red),
                  const SizedBox(width: 6),
                ],
                _tag(l['type'], T.grn),
              ]),
              const SizedBox(height: 2),
              Text(l['req'] ?? '', style: F.syne(size: 12, weight: FontWeight.w400, color: T.mut)),
              const SizedBox(height: 4),
              Text(l['time'] ?? '', style: F.syne(size: 10, weight: FontWeight.w400, color: T.dim)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _tag(String text, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: c.withOpacity(.08), border: Border.all(color: c.withOpacity(.18)), borderRadius: BorderRadius.circular(3)),
        child: Text(text.toUpperCase(), style: F.syne(size: 9, weight: FontWeight.w700, color: c, letterSpacing: .8)),
      );
}

/// ── VENDOR UPLOAD ────────────────────────────
class VendorUpload extends StatefulWidget {
  const VendorUpload({super.key});
  @override
  State<VendorUpload> createState() => _VendorUploadState();
}

class _VendorUploadState extends State<VendorUpload> {
  final Map<String, bool> _scope = {};
  bool _submitted = false;
  String _cat = 'photo';

  static const _emojiByCat = {'venue': '🏛️', 'photo': '📷', 'video': '🎬', 'modelF': '👗', 'modelM': '🧔', 'events': '🎪'};

  void _publish(AppState app) {
    setState(() => _submitted = true);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        app.publishProfile({'name': 'My New Profile', 'cat': _cat, 'emoji': _emojiByCat[_cat] ?? '🆕'});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    if (_submitted) {
      return Container(
        color: T.bg,
        child: Column(children: [
          const _Pnav(title: 'Publishing…'),
          Expanded(
            child: Center(
              child: FadeUp(
                offset: 28,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🎉', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 14),
                    Text('Profile Published!', style: F.fraunces(size: 24, weight: FontWeight.w700, color: T.cream)),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Text('Your profile is now live on AOneGo9 and visible to clients. Incoming leads will appear in your dashboard.',
                          textAlign: TextAlign.center, style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.7)),
                    ),
                    const SizedBox(height: 20),
                    _ActButton(label: 'Back to Dashboard', onTap: () => app.setView('vendor-dash')),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      );
    }

    final isModelCat = _cat == 'modelF' || _cat == 'modelM';
    final twoCol = screenW(context) > 768;

    return Container(
      color: T.bg,
      child: Column(children: [
        _Pnav(title: 'Upload / Edit Profile', backLabel: '← Dashboard', onBack: () => app.setView('vendor-dash')),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 80),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Align(alignment: Alignment.centerLeft, child: _PnavBtn(label: '← Back to Dashboard', onTap: () => app.setView('vendor-dash'), back: true)),
                  const SizedBox(height: 20),
                  SecHeader('Basic Information'),
                  _row2(twoCol, const Field('Profile / Business Name *', Fi('Your name or studio name')),
                      Field('Category *', FiSelect(options: cats.map((c) => '${c['icon']} ${c['name']}').toList(), value: '${cats.firstWhere((c) => c['id'] == _cat)['icon']} ${cats.firstWhere((c) => c['id'] == _cat)['name']}', onChanged: (v) {
                        final found = cats.firstWhere((c) => '${c['icon']} ${c['name']}' == v, orElse: () => cats.first);
                        setState(() => _cat = found['id'] as String);
                      }))),
                  const SizedBox(height: 11),
                  _row2(twoCol, const Field('City / Location *', Fi('Mumbai, Delhi...')), const Field('Experience', Fi('5 yrs / Est. 2019'))),
                  const SizedBox(height: 11),
                  const Field('Tagline *', Fi('Short description of your specialty')),
                  const SizedBox(height: 11),
                  const Field('About / Overview *', Fi('Describe your work, experience, and what makes you stand out...', minLines: 3)),
                  const SizedBox(height: 20),
                  SecHeader('Portfolio Upload'),
                  _dropzone(),
                  if (isModelCat) ...[
                    const SizedBox(height: 20),
                    SecHeader('Content & Scene Availability'),
                    Text('Select content types you are available for. Restricted scene categories require AOneGo9 admin approval and NDA process before inquiries are forwarded.',
                        style: F.syne(size: 12, weight: FontWeight.w400, color: T.mut, height: 1.65)),
                    const SizedBox(height: 12),
                    LayoutBuilder(builder: (context, bc) {
                      const gap = 7.0;
                      final w = twoCol ? (bc.maxWidth - gap) / 2 : bc.maxWidth;
                      return Wrap(spacing: gap, runSpacing: gap, children: [
                        for (final s in sceneOpts)
                          SizedBox(width: w, child: _scopeTog(s)),
                      ]);
                    }),
                    const SizedBox(height: 20),
                    SecHeader('Physical Details'),
                    _row2(twoCol, const Field('Height', Fi('5\'8"')), const Field('Weight', Fi('58 kg'))),
                    const SizedBox(height: 11),
                    _row2(twoCol, Field(_cat == 'modelF' ? 'Bust' : 'Chest', const Fi('34"')), const Field('Waist', Fi('26"'))),
                    const SizedBox(height: 11),
                    _row2(twoCol, const Field('Shoe Size', Fi('UK 7')), const Field('Skin Tone', Fi('Wheatish, Fair...'))),
                    const SizedBox(height: 11),
                    const Field('Languages', Fi('Hindi, English, Marathi...')),
                  ],
                  const SizedBox(height: 20),
                  SecHeader('Packages & Pricing'),
                  for (final pn in const ['Basic Package', 'Standard Package', 'Premium Package']) _pkgBlock(pn, twoCol),
                  const SizedBox(height: 20),
                  SecHeader('Contact & Social'),
                  _row2(twoCol, const Field('Contact Phone', Fi('+91 00000 00000')), const Field('Business Email', Fi('you@email.com'))),
                  const SizedBox(height: 11),
                  _row2(twoCol, const Field('Instagram Handle', Fi('@yourhandle')), const Field('Website / Portfolio', Fi('yoursite.com'))),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: T.gold.withOpacity(.05), border: Border.all(color: T.gold.withOpacity(.15)), borderRadius: BorderRadius.circular(9)),
                    child: Text('By publishing, you agree all details are accurate. AOneGo9 will review your profile within 2 hours before it goes live. All incoming leads will be visible in your vendor dashboard.',
                        style: F.syne(size: 12, weight: FontWeight.w400, color: T.mut, height: 1.65)),
                  ),
                  const SizedBox(height: 16),
                  _PubButton(label: 'Publish Profile to AOneGo9 →', onTap: () => _publish(app)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _row2(bool twoCol, Widget a, Widget b) {
    if (!twoCol) {
      return Column(children: [a, const SizedBox(height: 11), b]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 11), Expanded(child: b)]);
  }

  Widget _dropzone() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: T.surf,
          border: Border.all(color: T.bdr, width: 2, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          const Text('📁', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text('Upload Portfolio Images / Videos', style: F.syne(size: 13, weight: FontWeight.w700, color: T.text)),
          const SizedBox(height: 4),
          Text('JPG, PNG, MP4 · Max 20MB · Up to 12 files', style: F.syne(size: 11, weight: FontWeight.w400, color: T.dim)),
          const SizedBox(height: 10),
          Text('Click to browse or drag & drop', style: F.syne(size: 11, weight: FontWeight.w600, color: T.gold)),
        ]),
      );

  Widget _scopeTog(String s) {
    final on = _scope[s] ?? false;
    return GestureDetector(
      onTap: () => setState(() => _scope[s] = !on),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: on ? T.grn.withOpacity(.04) : T.surf,
          border: Border.all(color: on ? T.grn.withOpacity(.25) : T.bdr),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: on ? T.grn.withOpacity(.2) : null,
              border: Border.all(color: on ? T.grn.withOpacity(.4) : T.bdr),
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.center,
            child: Text(on ? '✓' : '', style: TextStyle(fontSize: 11, color: T.grn)),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(s, style: F.syne(size: 12, weight: FontWeight.w600, color: on ? T.text : T.mut))),
        ]),
      ),
    );
  }

  Widget _pkgBlock(String pn, bool twoCol) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: T.surf, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(pn, style: F.syne(size: 12, weight: FontWeight.w700, color: T.gold)),
          const SizedBox(height: 11),
          _row2(twoCol, Field('Package Name', Fi(pn)), const Field('Price', Fi('₹25,000'))),
          const SizedBox(height: 11),
          const Field("What's Included", Fi('List features...', minLines: 2)),
        ]),
      );
}
