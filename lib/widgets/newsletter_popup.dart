import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../data/editorial.dart';
import 'brand.dart';
import 'common.dart';
import 'form_fields.dart';

/// First-open digest overlay. Captures name, email, phone and city.
class NewsletterPopup extends StatefulWidget {
  const NewsletterPopup({super.key});

  @override
  State<NewsletterPopup> createState() => _NewsletterPopupState();
}

class _NewsletterPopupState extends State<NewsletterPopup> {
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
      if ((user['city'] as String?)?.isNotEmpty == true) _city = user['city'] as String;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit(AppState app) async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) {
      app.showToast('Almost there', 'Name and email let the desk reach you', '✉️');
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
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final issue = app.featuredIssue;
    final narrow = isNarrow(context);
    final maxH = MediaQuery.of(context).size.height * 0.92;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              onTap: app.dismissNewsletterPopup,
              child: Container(color: const Color(0xCC050506)),
            ),
            Center(
              child: FadeUp(
                offset: 22,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 24, vertical: 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 560, maxHeight: maxH),
                    child: Container(
                      decoration: BoxDecoration(
                        color: T.card,
                        border: Border.all(color: T.gold.withValues(alpha: .28)),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 48, offset: Offset(0, 24))],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(narrow ? 20 : 28, 22, narrow ? 20 : 28, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const BrandLogo(size: 16),
                                const Spacer(),
                                Text('ISSUE · DIGEST',
                                    style: F.syne(size: 10, weight: FontWeight.w700, color: T.gold, letterSpacing: 2)),
                                const SizedBox(width: 10),
                                HoverFx(
                                  onTap: app.dismissNewsletterPopup,
                                  builder: (h) => Container(
                                    width: 30,
                                    height: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: h ? T.bdhi : T.bdr),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.close_rounded, size: 15, color: h ? T.cream : T.mut),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text('This week on the floor',
                                style: F.fraunces(size: narrow ? 26 : 30, weight: FontWeight.w700, color: T.cream, height: 1.1, letterSpacing: -0.8)),
                            const SizedBox(height: 8),
                            Text(
                              'Castings, venues, campaigns — and the trends crews are actually booking. One email, Friday.',
                              style: F.syne(size: 13.5, weight: FontWeight.w400, color: T.mut, height: 1.65),
                            ),
                            const SizedBox(height: 18),
                            _Feature(issue: issue),
                            const SizedBox(height: 22),
                            Text('Stay on the list',
                                style: F.syne(size: 12, weight: FontWeight.w700, color: T.cream, letterSpacing: 0.2)),
                            const SizedBox(height: 4),
                            Text('We use this to send the digest and to understand who is reading the floor.',
                                style: F.syne(size: 11.5, weight: FontWeight.w400, color: T.dim, height: 1.5)),
                            const SizedBox(height: 14),
                            Field('Full name', Fi('Your name', controller: _name)),
                            const SizedBox(height: 10),
                            Field('Email', Fi('you@studio.com', keyboardType: TextInputType.emailAddress, controller: _email)),
                            const SizedBox(height: 10),
                            Field('Phone', Fi('+91 98765 43210', keyboardType: TextInputType.phone, controller: _phone)),
                            const SizedBox(height: 10),
                            Field(
                              'City',
                              FiSelect(
                                options: const ['Mumbai', 'Delhi NCR', 'Bangalore', 'Chennai', 'Hyderabad', 'Goa', 'Jaipur', 'Other'],
                                value: _city,
                                onChanged: (v) => setState(() => _city = v ?? _city),
                              ),
                            ),
                            const SizedBox(height: 16),
                            HoverFx(
                              onTap: _busy ? null : () => _submit(app),
                              builder: (h) => Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _busy ? T.surf : T.gold,
                                  border: _busy ? Border.all(color: T.bdhi) : null,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  _busy ? 'Saving…' : 'Subscribe to the digest →',
                                  style: F.syne(size: 14, weight: FontWeight.w700, color: _busy ? T.mut : T.bg),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: HoverFx(
                                onTap: app.dismissNewsletterPopup,
                                builder: (h) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                  child: Text('Maybe later',
                                      style: F.syne(size: 12, weight: FontWeight.w600, color: h ? T.text : T.dim)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final NewsletterIssue issue;
  const _Feature({required this.issue});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: T.bdr),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            height: 108,
            child: GradientArt(bgIndex: issue.bg, emoji: issue.emoji, emojiSize: 36),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${issue.tag.toUpperCase()}  ·  ${issue.city}',
                      style: F.syne(size: 10, weight: FontWeight.w700, color: T.gold, letterSpacing: 1.4)),
                  const SizedBox(height: 6),
                  Text(issue.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: F.fraunces(size: 16, weight: FontWeight.w700, color: T.cream, height: 1.2)),
                  const SizedBox(height: 6),
                  Text(issue.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: F.syne(size: 12, weight: FontWeight.w400, color: T.mut, height: 1.45)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
