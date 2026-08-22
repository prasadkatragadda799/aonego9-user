import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../data/editorial.dart';
import '../data/upload_service.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

class NewsletterScreen extends StatelessWidget {
  const NewsletterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pad = isNarrow(context) ? 16.0 : 24.0;
    return PageFrame(
      title: 'Newsletter',
      body: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro(
              eyebrow: 'AOneGo9 Digest',
              title: 'What\'s happening, and what\'s next.',
              dek: 'Castings, venues, campaigns — plus the trends crews are actually booking. Submitted stories go live after credentials are checked.',
            ),
            const SizedBox(height: 8),
            _Tabs(active: app.newsletterTab, onChange: app.setNewsletterTab),
            const SizedBox(height: 22),
            if (app.selectedIssue != null) ...[
              _IssueDetail(issue: app.selectedIssue!),
              const SizedBox(height: 28),
            ],
            _Grid(issues: app.newsletterTab == 'trend' ? app.trendIssues : app.happeningIssues),
            const SizedBox(height: 48),
            const _SubscribeBlock(),
            const SizedBox(height: 28),
            const _ContributeBlock(),
          ],
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final String active;
  final ValueChanged<String> onChange;
  const _Tabs({required this.active, required this.onChange});

  @override
  Widget build(BuildContext context) {
    Widget tab(String id, String label, String hint) {
      final on = active == id;
      return HoverFx(
        onTap: () => onChange(id),
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: on ? T.gold.withValues(alpha: .12) : T.card,
            border: Border.all(color: on || h ? T.gold : T.bdr, width: on ? 1.4 : 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: F.syne(size: 13.5, weight: FontWeight.w700, color: on ? T.gold : T.cream)),
              const SizedBox(height: 2),
              Text(hint, style: F.syne(size: 11, weight: FontWeight.w400, color: T.dim)),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        tab('happening', 'What\'s happening', 'Castings, weeks, new books'),
        tab('trend', 'Trends', 'How the floor is actually moving'),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  final List<NewsletterIssue> issues;
  const _Grid({required this.issues});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (issues.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text('Nothing in this section yet — check back Friday.',
            style: F.syne(size: 14, weight: FontWeight.w400, color: T.mut)),
      );
    }
    return LayoutBuilder(builder: (context, bc) {
      final cols = bc.maxWidth >= 860 ? 2 : 1;
      const gap = 16.0;
      final w = (bc.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final issue in issues)
            SizedBox(
              width: w,
              child: _IssueCard(
                issue: issue,
                selected: app.selectedIssue?.id == issue.id,
                onTap: () => app.openIssue(issue),
              ),
            ),
        ],
      );
    });
  }
}

class _IssueCard extends StatelessWidget {
  final NewsletterIssue issue;
  final bool selected;
  final VoidCallback onTap;
  const _IssueCard({required this.issue, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoverFx(
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: T.card,
          border: Border.all(color: selected || h ? T.gold.withValues(alpha: .5) : T.bdr),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 148,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (issue.imageUrl != null)
                    Image.network(issue.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => GradientArt(bgIndex: issue.bg, emoji: issue.emoji, emojiSize: 48))
                  else
                    GradientArt(bgIndex: issue.bg, emoji: issue.emoji, emojiSize: 48),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xE009090B), borderRadius: BorderRadius.circular(4)),
                      child: Text(issue.kind == 'trend' ? 'TREND' : 'HAPPENING',
                          style: F.syne(size: 10, weight: FontWeight.w700, color: T.gold, letterSpacing: 1.4)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${issue.tag}  ·  ${issue.city}  ·  ${issue.date}',
                      style: F.mono(size: 10.5, color: T.dim)),
                  const SizedBox(height: 8),
                  Text(issue.title, style: F.fraunces(size: 20, weight: FontWeight.w700, color: T.cream, height: 1.2)),
                  const SizedBox(height: 8),
                  Text(issue.excerpt, maxLines: 3, overflow: TextOverflow.ellipsis,
                      style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.55)),
                  const SizedBox(height: 12),
                  Text('Read →', style: F.syne(size: 12.5, weight: FontWeight.w700, color: T.gold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueDetail extends StatelessWidget {
  final NewsletterIssue issue;
  const _IssueDetail({required this.issue});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: T.surf,
        border: Border.all(color: T.gold.withValues(alpha: .28)),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: isNarrow(context) ? 160 : 210,
            child: issue.imageUrl != null
                ? Image.network(issue.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => GradientArt(bgIndex: issue.bg, emoji: issue.emoji, emojiSize: 64))
                : GradientArt(bgIndex: issue.bg, emoji: issue.emoji, emojiSize: 64),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${issue.kind == 'trend' ? 'TREND' : 'HAPPENING'}  ·  ${issue.tag.toUpperCase()}  ·  ${issue.city}',
                    style: F.syne(size: 10, weight: FontWeight.w700, color: T.gold, letterSpacing: 1.8)),
                const SizedBox(height: 10),
                Text(issue.title, style: F.fraunces(size: 28, weight: FontWeight.w700, color: T.cream, height: 1.15)),
                const SizedBox(height: 8),
                Text('${issue.date}  ·  ${issue.author}', style: F.mono(size: 11, color: T.dim)),
                const SizedBox(height: 16),
                Text(issue.body, style: F.syne(size: 14.5, weight: FontWeight.w400, color: T.text, height: 1.75)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscribeBlock extends StatefulWidget {
  const _SubscribeBlock();
  @override
  State<_SubscribeBlock> createState() => _SubscribeBlockState();
}

class _SubscribeBlockState extends State<_SubscribeBlock> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String _city = 'Mumbai';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _city = app.location == 'All India' ? 'Mumbai' : app.location;
    final user = app.currentUser;
    if (user != null) {
      _name.text = user['name']?.toString() ?? '';
      _email.text = user['email']?.toString() ?? '';
      _phone.text = user['phone']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.newsletterSubscribed) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: T.gold.withValues(alpha: .08),
          border: Border.all(color: T.gold.withValues(alpha: .3)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Text('✉️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text('You\'re on the Friday digest. We\'ll only write when the floor actually moved.',
                  style: F.syne(size: 14, weight: FontWeight.w500, color: T.cream, height: 1.5)),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: EdgeInsets.all(isNarrow(context) ? 18 : 24),
      decoration: BoxDecoration(
        color: T.card,
        border: Border.all(color: T.bdr),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Get the digest', style: F.fraunces(size: 24, weight: FontWeight.w700, color: T.cream)),
          const SizedBox(height: 6),
          Text('Name, email, phone and city — so the desk can send the right city\'s floor, not a generic blast.',
              style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.6)),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (context, bc) {
            final split = bc.maxWidth > 640;
            final fields = [
              Field('Full name', Fi('Your name', controller: _name)),
              Field('Email', Fi('you@studio.com', keyboardType: TextInputType.emailAddress, controller: _email)),
              Field('Phone', Fi('+91 98765 43210', keyboardType: TextInputType.phone, controller: _phone)),
              Field(
                'City',
                FiSelect(
                  options: const ['Mumbai', 'Delhi NCR', 'Bangalore', 'Chennai', 'Hyderabad', 'Goa', 'Jaipur', 'Other'],
                  value: _city,
                  onChanged: (v) => setState(() => _city = v ?? _city),
                ),
              ),
            ];
            if (!split) {
              return Column(
                children: [
                  for (final f in fields) ...[f, const SizedBox(height: 10)],
                ],
              );
            }
            return Column(
              children: [
                Row(children: [Expanded(child: fields[0]), const SizedBox(width: 12), Expanded(child: fields[1])]),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: fields[2]), const SizedBox(width: 12), Expanded(child: fields[3])]),
              ],
            );
          }),
          const SizedBox(height: 14),
          HoverFx(
            onTap: _busy
                ? null
                : () async {
                    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) {
                      app.showToast('Missing details', 'Name and email are required', '⚠️');
                      return;
                    }
                    setState(() => _busy = true);
                    await app.subscribeNewsletter(
                      name: _name.text.trim(),
                      email: _email.text.trim(),
                      phone: _phone.text.trim(),
                      city: _city,
                    );
                    if (mounted) setState(() => _busy = false);
                  },
            builder: (h) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(color: T.gold, borderRadius: BorderRadius.circular(8)),
              child: Text(_busy ? 'Saving…' : 'Subscribe →',
                  style: F.syne(size: 13, weight: FontWeight.w700, color: T.bg)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Press / vendor contribution — credentials required before a story is accepted.
class _ContributeBlock extends StatefulWidget {
  const _ContributeBlock();
  @override
  State<_ContributeBlock> createState() => _ContributeBlockState();
}

class _ContributeBlockState extends State<_ContributeBlock> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _org = TextEditingController();
  final _role = TextEditingController();
  final _cred = TextEditingController();
  final _headline = TextEditingController();
  final _body = TextEditingController();
  String _city = 'Mumbai';
  String _kind = 'What\'s happening';
  String? _imageUrl;
  bool _busy = false;
  bool _open = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _org.dispose();
    _role.dispose();
    _cred.dispose();
    _headline.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await file.readAsBytes();
      final url = await UploadService.uploadImage(
        bytes: Uint8List.fromList(bytes),
        filename: file.name,
        folder: 'newsletter',
      );
      if (mounted) setState(() => _imageUrl = url);
    } catch (_) {
      if (mounted) context.read<AppState>().showToast('Upload skipped', 'You can still submit — we\'ll use the text', '📎');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final app = context.read<AppState>();
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _org.text.trim().isEmpty ||
        _role.text.trim().isEmpty ||
        _headline.text.trim().isEmpty ||
        _body.text.trim().isEmpty) {
      app.showToast('Credentials incomplete', 'Name, email, phone, organisation, role and the story are required', '⚠️');
      return;
    }
    setState(() => _busy = true);
    await app.contributeNewsletter({
      'author_name': _name.text.trim(),
      'author_email': _email.text.trim(),
      'author_phone': _phone.text.trim(),
      'organisation': _org.text.trim(),
      'role': _role.text.trim(),
      'credentials_url': _cred.text.trim(),
      'city': _city,
      'kind': _kind == 'Trends' ? 'trend' : 'happening',
      'title': _headline.text.trim(),
      'body': _body.text.trim(),
      'image_url': _imageUrl ?? '',
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      _open = false;
      _headline.clear();
      _body.clear();
      _imageUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isNarrow(context) ? 18 : 24),
      decoration: BoxDecoration(
        color: T.surf,
        border: Border.all(color: T.bdr),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Submit a story', style: F.fraunces(size: 24, weight: FontWeight.w700, color: T.cream)),
                    const SizedBox(height: 6),
                    Text(
                      'Press, PR, vendors and producers. We need your credentials before anything is published — so the digest stays a desk, not a rumor mill.',
                      style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          HoverFx(
            onTap: () => setState(() => _open = !_open),
            builder: (h) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                border: Border.all(color: h ? T.gold : T.bdr),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_open ? 'Close form' : 'Open contributor form',
                  style: F.syne(size: 13, weight: FontWeight.w700, color: h ? T.gold : T.cream)),
            ),
          ),
          if (_open) ...[
            const SizedBox(height: 22),
            const BlkHeader('Your credentials'),
            const SizedBox(height: 4),
            Text('The desk will verify these before the story is scheduled.',
                style: F.syne(size: 12, weight: FontWeight.w400, color: T.dim)),
            const SizedBox(height: 14),
            Field('Full name', Fi('As on your byline', controller: _name)),
            const SizedBox(height: 10),
            Field('Work email', Fi('desk@publication.com', keyboardType: TextInputType.emailAddress, controller: _email)),
            const SizedBox(height: 10),
            Field('Phone', Fi('+91 …', keyboardType: TextInputType.phone, controller: _phone)),
            const SizedBox(height: 10),
            Field('Organisation / publication', Fi('Studio, label, paper, house', controller: _org)),
            const SizedBox(height: 10),
            Field('Role / title', Fi('Editor, PR, producer, vendor', controller: _role)),
            const SizedBox(height: 10),
            Field('Press card, site or credential URL', Fi('https://…', controller: _cred)),
            const SizedBox(height: 10),
            Field(
              'City',
              FiSelect(
                options: const ['Mumbai', 'Delhi NCR', 'Bangalore', 'Chennai', 'Hyderabad', 'Goa', 'Jaipur', 'Other'],
                value: _city,
                onChanged: (v) => setState(() => _city = v ?? _city),
              ),
            ),
            const SizedBox(height: 22),
            const BlkHeader('The story'),
            const SizedBox(height: 12),
            Field(
              'Section',
              FiSelect(
                options: const ['What\'s happening', 'Trends'],
                value: _kind,
                onChanged: (v) => setState(() => _kind = v ?? _kind),
              ),
            ),
            const SizedBox(height: 10),
            Field('Headline', Fi('What should the floor know?', controller: _headline)),
            const SizedBox(height: 10),
            Field('Body', Fi('Dates, city, who is booking, why it matters.', controller: _body, minLines: 5)),
            const SizedBox(height: 12),
            HoverFx(
              onTap: _busy ? null : () { _pick(); },
              builder: (h) => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: T.card,
                  border: Border.all(color: h ? T.gold : T.bdr, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  _imageUrl != null ? 'Cover image attached' : 'Upload a cover still (optional)',
                  style: F.syne(size: 13, weight: FontWeight.w600, color: _imageUrl != null ? T.gold : T.mut),
                ),
              ),
            ),
            const SizedBox(height: 16),
            HoverFx(
              onTap: _busy ? null : () { _submit(); },
              builder: (h) => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: T.gold, borderRadius: BorderRadius.circular(9)),
                child: Text(_busy ? 'Sending…' : 'Submit for verification →',
                    style: F.syne(size: 14, weight: FontWeight.w700, color: T.bg)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
