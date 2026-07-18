import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

/// Shared `.pnav` bar, matching the vendor screens' header.
class _Pnav extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _Pnav({required this.title, required this.onBack});

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
        _PnavBtn(label: '← Back to Browse', onTap: onBack),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: F.syne(size: 13, weight: FontWeight.w700, color: T.text))),
      ]),
    );
  }
}

class _PnavBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PnavBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(border: Border.all(color: h ? T.bdhi : T.bdr), borderRadius: BorderRadius.circular(6)),
          child: Text(label, style: F.syne(size: 12, weight: FontWeight.w600, color: h ? T.text : T.mut)),
        ),
      );
}

class _PubButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PubButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: onTap == null ? T.gold.withOpacity(.4) : T.gold,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(label, style: F.syne(size: 15, weight: FontWeight.w700, color: T.bg)),
        ),
      );
}

/// ── CUSTOMER AUTH — sign in / create account, wired to the real backend ──
class UserAuth extends StatefulWidget {
  const UserAuth({super.key});
  @override
  State<UserAuth> createState() => _UserAuthState();
}

class _UserAuthState extends State<UserAuth> {
  bool _register = false;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(AppState app) async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty || (_register && _name.text.trim().isEmpty)) {
      app.showToast('Missing details', _register ? 'Name, email and password are required' : 'Email and password are required', '⚠️');
      return;
    }
    final ok = _register
        ? await app.registerUser(name: _name.text.trim(), email: _email.text.trim(), password: _password.text, phone: _phone.text.trim())
        : await app.loginUser(_email.text.trim(), _password.text);
    if (ok) app.setView('browse');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Container(
      color: T.bg,
      child: Column(children: [
        _Pnav(title: _register ? 'Create Account' : 'Sign In', onBack: app.backToBrowse),
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
                          Text(_register ? '✨' : '🔐', style: const TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text(_register ? 'Create Your Account' : 'Welcome Back', style: F.fraunces(size: 26, weight: FontWeight.w700, color: T.cream)),
                          const SizedBox(height: 5),
                          Text(
                            _register
                                ? 'Sign up to track your inquiries and bookings across AOneGo9.'
                                : 'Sign in to track your inquiries, bookings and saved profiles.',
                            textAlign: TextAlign.center,
                            style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.6),
                          ),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          if (_register) ...[
                            Field('Full Name', Fi('Your name', controller: _name)),
                            const SizedBox(height: 11),
                          ],
                          Field('Email', Fi('you@example.com', keyboardType: TextInputType.emailAddress, controller: _email)),
                          const SizedBox(height: 11),
                          if (_register) ...[
                            Field('Phone (optional)', Fi('+91 98765 43210', keyboardType: TextInputType.phone, controller: _phone)),
                            const SizedBox(height: 11),
                          ],
                          Field('Password', Fi('••••••••', obscure: true, controller: _password)),
                          if (app.authError != null) ...[
                            const SizedBox(height: 12),
                            Text(app.authError!, style: F.syne(size: 12, weight: FontWeight.w600, color: T.red)),
                          ],
                          const SizedBox(height: 15),
                          _PubButton(
                            label: app.authBusy ? 'Please wait…' : (_register ? 'Create Account →' : 'Sign In →'),
                            onTap: app.authBusy ? null : () => _submit(app),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Wrap(children: [
                              Text(_register ? 'Already have an account? ' : "Don't have an account? ",
                                  style: F.syne(size: 12, weight: FontWeight.w400, color: T.dim)),
                              GestureDetector(
                                onTap: () => setState(() => _register = !_register),
                                child: Text(_register ? 'Sign In' : 'Create One',
                                    style: F.syne(size: 12, weight: FontWeight.w700, color: T.gold)),
                              ),
                            ]),
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
