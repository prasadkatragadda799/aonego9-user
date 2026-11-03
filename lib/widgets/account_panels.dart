import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/api_client.dart';
import '../data/user_repository.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'common.dart';
import 'form_fields.dart';

String _when(dynamic raw) {
  final d = DateTime.tryParse('${raw ?? ''}')?.toLocal();
  if (d == null) return '';
  final now = DateTime.now();
  if (DateUtils.isSameDay(d, now)) return DateFormat('h:mm a').format(d);
  if (d.year == now.year) return DateFormat('d MMM').format(d);
  return DateFormat('d MMM yyyy').format(d);
}

String _errorText(Object e, String fallback) => e is ApiException ? e.message : fallback;

Widget _loading() => const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
    );

/// Solid accent button used by the account panels.
class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool busy;
  const _PrimaryBtn({required this.label, required this.onTap, this.busy = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    // Full-width on phones, sized to its label on wider screens.
    final btn = HoverFx(
      onTap: enabled ? onTap : null,
      builder: (h) => Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: enabled ? (h ? T.goldLight : T.gold) : T.surf,
          border: enabled ? null : Border.all(color: T.bdr),
          borderRadius: BorderRadius.circular(8),
        ),
        child: busy
            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: T.gold))
            : Text(label, style: F.syne(size: 13, weight: FontWeight.w700, color: enabled ? T.onAccent(T.gold) : T.dim)),
      ),
    );
    return MediaQuery.sizeOf(context).width < 600 ? btn : IntrinsicWidth(child: btn);
  }
}

// ─────────────────────────────────────────────────────────────────
// MESSAGES — conversations with vendors. A thread opens when the client
// sends an inquiry; vendors reply from their console.
// ─────────────────────────────────────────────────────────────────

class MessagesPanel extends StatefulWidget {
  const MessagesPanel({super.key});
  @override
  State<MessagesPanel> createState() => _MessagesPanelState();
}

class _MessagesPanelState extends State<MessagesPanel> {
  final _repo = UserRepository();
  List<Map<String, dynamic>>? _threads; // null = loading
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await _repo.myThreads();
      if (mounted) setState(() { _threads = t; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _threads = []; _error = _errorText(e, 'Could not load your messages.'); });
    }
  }

  Future<void> _open(Map<String, dynamic> t) async {
    await showDialog<void>(context: context, builder: (_) => _ThreadDialog(threadId: '${t['id']}', vendorName: '${t['vendor_name'] ?? 'Vendor'}'));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Blk(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const BlkHeader('Messages'),
        if (_threads == null)
          _loading()
        else if (_error != null)
          EmptyState(icon: Icons.wifi_off_outlined, title: 'Messages unavailable', message: _error!, actionLabel: 'Try again', onAction: () {
            setState(() => _threads = null);
            _load();
          })
        else if (_threads!.isEmpty)
          const EmptyState(
            icon: Icons.forum_outlined,
            title: 'No conversations yet',
            message: 'Send an inquiry to a vendor and your conversation with them appears here.',
          )
        else
          for (final t in _threads!) _threadRow(t),
      ]),
    );
  }

  Widget _threadRow(Map<String, dynamic> t) {
    final name = '${t['vendor_name'] ?? 'Vendor'}';
    return HoverFx(
      onTap: () => _open(t),
      builder: (h) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: T.surf,
          border: Border.all(color: h ? T.bdhi : T.bdr),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: T.gold.withValues(alpha: .12), shape: BoxShape.circle),
            child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                style: F.fraunces(size: 16, weight: FontWeight.w700, color: T.gold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(
                  child: Text(name,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: F.syne(size: 13, weight: FontWeight.w700, color: T.text)),
                ),
                const SizedBox(width: 8),
                Text(_when(t['last_message_at']), style: F.syne(size: 11, weight: FontWeight.w400, color: T.dim)),
              ]),
              const SizedBox(height: 3),
              Text('${t['last_message'] ?? ''}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: F.syne(size: 12, weight: FontWeight.w400, color: T.mut)),
            ]),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, color: h ? T.text : T.mut),
        ]),
      ),
    );
  }
}

class _ThreadDialog extends StatefulWidget {
  final String threadId;
  final String vendorName;
  const _ThreadDialog({required this.threadId, required this.vendorName});
  @override
  State<_ThreadDialog> createState() => _ThreadDialogState();
}

class _ThreadDialogState extends State<_ThreadDialog> {
  final _repo = UserRepository();
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>>? _messages;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final t = await _repo.thread(widget.threadId);
      if (!mounted) return;
      setState(() {
        _messages = ApiClient.asList(t['messages']);
        _error = null;
      });
      _toBottom();
    } catch (e) {
      if (mounted) setState(() { _messages ??= []; _error = _errorText(e, 'Could not load this conversation.'); });
    }
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final m = await _repo.sendMessage(widget.threadId, text);
      if (!mounted) return;
      _ctrl.clear();
      setState(() => _messages = [...?_messages, m]);
      _toBottom();
    } catch (e) {
      if (mounted) context.read<AppState>().showToast('Message not sent', _errorText(e, 'Please try again.'), '⚠️');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: T.card,
      insetPadding: EdgeInsets.all(size.width < 600 ? 12 : 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: T.bdr)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: size.height * .82),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
            child: Row(children: [
              Expanded(
                child: Text(widget.vendorName,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: F.fraunces(size: 18, weight: FontWeight.w700, color: T.text)),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: T.mut, size: 20),
              ),
            ]),
          ),
          Container(height: 1, color: T.bdr),
          Flexible(
            child: _messages == null
                ? _loading()
                : _error != null && _messages!.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(_error!, textAlign: TextAlign.center, style: F.syne(size: 13, color: T.redText)),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        itemCount: _messages!.length,
                        itemBuilder: (_, i) => _bubble(_messages![i]),
                      ),
          ),
          Container(height: 1, color: T.bdr),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: F.syne(size: 13, weight: FontWeight.w400, color: T.text),
                  cursorColor: T.gold,
                  decoration: InputDecoration(
                    counterText: '',
                    isDense: true,
                    filled: true,
                    fillColor: T.surf,
                    hintText: 'Write a message…',
                    hintStyle: F.syne(size: 13, weight: FontWeight.w400, color: T.dim),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    border: OutlineInputBorder(borderSide: BorderSide(color: T.bdr), borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: T.bdr), borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: T.gold), borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _PrimaryBtn(label: 'Send', busy: _sending, onTap: _send),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _bubble(Map<String, dynamic> m) {
    final mine = m['from_vendor'] != true;
    final ink = T.onAccent(T.gold);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
        decoration: BoxDecoration(
          color: mine ? T.gold : T.surf,
          border: Border.all(color: mine ? T.gold : T.bdr),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(mine ? 12 : 3),
            bottomRight: Radius.circular(mine ? 3 : 12),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          SelectableText('${m['text'] ?? ''}',
              style: F.syne(size: 13, weight: FontWeight.w400, color: mine ? ink : T.text, height: 1.45)),
          const SizedBox(height: 3),
          Text(_when(m['sent_at']), style: F.syne(size: 10, weight: FontWeight.w400, color: mine ? ink.withValues(alpha: .75) : T.dim)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HELP — raise a ticket with the AOneGo9 desk and follow its status.
// ─────────────────────────────────────────────────────────────────

class HelpPanel extends StatefulWidget {
  const HelpPanel({super.key});
  @override
  State<HelpPanel> createState() => _HelpPanelState();
}

class _HelpPanelState extends State<HelpPanel> {
  final _repo = UserRepository();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  String _priority = 'Medium';
  bool _sending = false;
  bool _composing = false;
  String? _error;
  List<Map<String, dynamic>>? _tickets; // null = loading

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final t = await _repo.myTickets();
      if (mounted) setState(() => _tickets = t);
    } catch (_) {
      if (mounted) setState(() => _tickets = []);
    }
  }

  Future<void> _submit() async {
    final subject = _subject.text.trim();
    final body = _body.text.trim();
    if (subject.length < 3) return setState(() => _error = 'Add a short subject (at least 3 characters).');
    if (body.isEmpty) return setState(() => _error = 'Tell us what you need help with.');
    setState(() { _sending = true; _error = null; });
    final app = context.read<AppState>();
    try {
      await _repo.raiseTicket(subject: subject, body: body, priority: _priority.toLowerCase());
      if (!mounted) return;
      _subject.clear();
      _body.clear();
      setState(() { _composing = false; _priority = 'Medium'; });
      app.showToast('Request sent', 'The AOneGo9 desk will get back to you by email.', '📨');
      _load();
    } catch (e) {
      if (mounted) setState(() => _error = _errorText(e, 'Could not send your request — please try again.'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Blk(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const BlkHeader('Help & Support'),
        if (_tickets == null)
          _loading()
        else ...[
          for (final t in _tickets!) _ticketRow(t),
          if (_tickets!.isEmpty && !_composing)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text('Questions about a booking, payment or your account? Write to the AOneGo9 desk.',
                  style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.5)),
            ),
        ],
        if (_composing) _form() else Align(alignment: Alignment.centerLeft, child: _PrimaryBtn(label: 'Contact support', onTap: () => setState(() => _composing = true))),
      ]),
    );
  }

  Widget _form() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 4),
        const Fl('Subject'),
        Fi('e.g. Refund for booking AO9-123456', controller: _subject),
        const SizedBox(height: 12),
        const Fl('Priority'),
        FiSelect(options: const ['Low', 'Medium', 'High'], value: _priority, onChanged: (v) => _priority = v ?? 'Medium'),
        const SizedBox(height: 12),
        const Fl('How can we help?'),
        Fi('Share the details — booking reference, dates, what went wrong…', minLines: 4, controller: _body),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: F.syne(size: 12, weight: FontWeight.w600, color: T.redText)),
        ],
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
          _PrimaryBtn(label: 'Send request', busy: _sending, onTap: _submit),
          TextButton(
            onPressed: _sending ? null : () => setState(() { _composing = false; _error = null; }),
            child: Text('Cancel', style: F.syne(size: 12, weight: FontWeight.w600, color: T.mut)),
          ),
        ]),
      ]);

  Widget _ticketRow(Map<String, dynamic> t) {
    final status = '${t['status'] ?? 'open'}';
    final color = switch (status) { 'resolved' => T.grn, 'pending' => T.gold, _ => T.mut };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: T.surf, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(9)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('${t['subject'] ?? 'Request'}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: F.syne(size: 13, weight: FontWeight.w700, color: T.text)),
            const SizedBox(height: 3),
            Text('${t['id'] ?? ''} · ${_when(t['created_at'])}', style: F.syne(size: 11, weight: FontWeight.w400, color: T.dim)),
          ]),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            border: Border.all(color: color.withValues(alpha: .4)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(status.toUpperCase(), style: F.syne(size: 10, weight: FontWeight.w700, color: color, letterSpacing: 1)),
        ),
      ]),
    );
  }
}
