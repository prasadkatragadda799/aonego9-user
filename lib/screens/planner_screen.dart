import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/geo.dart';
import '../data/programs.dart';
import '../data/taxonomy.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/program_kit.dart';

/// Event planner & notebooks — for institutions, organisers and anyone
/// planning an event.
///
///   · Plan: an AI-assisted plan (budget split, timeline, checklist, tips),
///     with every budget head linked to the AOneGo9 category that supplies it.
///   · Notebooks: a digital planning notebook per event — guest list with
///     RSVPs, a budget ledger (accounting), tasks, notes and an activity
///     history. Kept on the device so it works signed out.
class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  String _tab = 'plan';
  String? _openId;
  EventPlan? _plan;

  /// Anchors the tab bar, so switching views brings it back into sight
  /// instead of leaving the visitor at the old scroll position.
  final _topKey = GlobalKey();

  void _toTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _topKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic, alignment: .05);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pad = isNarrow(context) ? 16.0 : 24.0;
    Notebook? open;
    for (final n in app.notebooks) {
      if (n.id == _openId) open = n;
    }

    return PageFrame(
      title: 'Event planner',
      body: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 56),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const PageIntro(
            eyebrow: 'AI-assisted event planning',
            motif: 'crew',
            title: 'Plan the event. Keep the notebook.',
            dek: 'Celebrity events, fashion shows, fests, anniversaries, New Year and summer celebrations — get a budget split, '
                'a timeline and the vendors to book, then run it all from a planning notebook with guests, accounts and tasks.',
          ),
          const SizedBox(height: 18),
          SegTabs(
            key: _topKey,
            tabs: [
              ('plan', 'Plan an event', '✨'),
              ('notebooks', 'Notebooks (${app.notebooks.length})', '📓'),
            ],
            active: _tab,
            onChanged: (t) => setState(() {
              _tab = t;
              _openId = null;
            }),
          ),
          const SizedBox(height: 18),
          if (_tab == 'plan')
            _PlanTab(
              plan: _plan,
              onPlan: (p) => setState(() => _plan = p),
              onSaved: (nb) {
                setState(() {
                  _tab = 'notebooks';
                  _openId = nb.id;
                });
                _toTop();
              },
            )
          else if (open != null)
            _NotebookView(
                key: ValueKey(open.id),
                nb: open,
                onBack: () {
                  setState(() => _openId = null);
                  _toTop();
                })
          else
            _NotebookList(onOpen: (id) {
              setState(() => _openId = id);
              _toTop();
            }),
        ]),
      ),
    );
  }
}

// ── Plan tab ─────────────────────────────────────────────────────

class _PlanTab extends StatefulWidget {
  final EventPlan? plan;
  final ValueChanged<EventPlan> onPlan;
  final ValueChanged<Notebook> onSaved;
  const _PlanTab({required this.plan, required this.onPlan, required this.onSaved});

  @override
  State<_PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<_PlanTab> {
  String _type = plannerEventTypes.first;
  final _guests = TextEditingController(text: '300');
  final _budget = TextEditingController(text: '500000');
  late final _city = TextEditingController(text: _defaultCity());
  DateTime? _date;
  bool _busy = false;
  String? _guestErr;
  String? _budgetErr;

  String _defaultCity() {
    final loc = context.read<AppState>().location;
    return loc == kAllIndia ? 'Mumbai' : loc;
  }

  @override
  void dispose() {
    for (final c in [_guests, _budget, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _generate() async {
    final g = int.tryParse(_guests.text.trim()) ?? 0;
    final b = double.tryParse(_budget.text.trim()) ?? 0;
    setState(() {
      _guestErr = g <= 0 ? 'Enter the expected guest count' : null;
      _budgetErr = b < 1000 ? 'Enter a budget of at least ₹1,000' : null;
    });
    if (_guestErr != null || _budgetErr != null) return;
    setState(() => _busy = true);
    final plan = await context.read<AppState>().generatePlan(
          type: _type,
          guests: g,
          budget: b,
          city: _city.text.trim().isEmpty ? 'your city' : _city.text.trim(),
          date: _date?.toIso8601String().substring(0, 10) ?? '',
        );
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onPlan(plan);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 60)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final plan = widget.plan;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PCard(
        padding: EdgeInsets.all(isNarrow(context) ? 16 : 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Fl('Event type'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in plannerEventTypes) PickChip(label: t, active: _type == t, onTap: () => setState(() => _type = t)),
          ]),
          const SizedBox(height: 14),
          FieldPair(
            LabeledInput(
              label: 'Guests',
              hint: '300',
              controller: _guests,
              keyboardType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              error: _guestErr,
              required: true,
            ),
            LabeledInput(
              label: 'Budget (₹)',
              hint: '500000',
              controller: _budget,
              keyboardType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              error: _budgetErr,
              required: true,
            ),
          ),
          const SizedBox(height: 12),
          FieldPair(
            LabeledInput(label: 'City', hint: 'Mumbai', controller: _city),
            Field(
              'Date',
              HoverFx(
                onTap: _pickDate,
                builder: (h) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(color: T.surf, border: Border.all(color: h ? T.gold : T.bdr), borderRadius: BorderRadius.circular(7)),
                  child: Row(children: [
                    Icon(Icons.event_rounded, size: 16, color: T.dim),
                    const SizedBox(width: 8),
                    Text(_date == null ? 'Optional' : _fmtDate(_date!), style: F.syne(size: 13, color: _date == null ? T.dim : T.text)),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          PrimaryBtn(plan == null ? 'Generate my plan' : 'Regenerate plan',
              icon: Icons.auto_awesome_rounded, busy: _busy, onTap: _generate, expand: true),
        ]),
      ),
      if (plan != null) ...[
        const SizedBox(height: 22),
        Row(children: [
          Expanded(
            child: Text('${plan.type} · ${plan.city}',
                style: F.fraunces(size: isNarrow(context) ? 20 : 24, weight: FontWeight.w700, color: T.cream)),
          ),
          Tag(app.lastPlanFromAi ? 'AI plan' : 'Smart planner', color: T.grn),
        ]),
        const SizedBox(height: 12),
        AutoGrid(minItemWidth: 150, gap: 10, children: [
          StatTile(inr(plan.budget), 'Budget'),
          StatTile('${plan.guests}', 'Guests'),
          StatTile(inr(plan.perGuest), 'Per guest'),
          StatTile('${plan.budgetLines.length}', 'Budget heads'),
        ]),
        const SectionTitle('Budget split', dek: 'Tap a line to find that vendor on AOneGo9.'),
        PCard(
          child: Column(children: [
            for (final l in plan.budgetLines) _BudgetLineRow(line: l),
          ]),
        ),
        LayoutBuilder(builder: (context, bc) {
          final timeline = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SectionTitle('Timeline'),
            PCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final s in plan.timeline)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 108, child: Text(s.when, style: F.mono(size: 10.5, color: T.gold))),
                      Expanded(child: Text(s.task, style: F.syne(size: 12.5, color: T.text, height: 1.45))),
                    ]),
                  ),
              ]),
            ),
          ]);
          final checklist = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SectionTitle('Checklist'),
            PCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final c in plan.checklist)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.check_box_outline_blank_rounded, size: 16, color: T.dim),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c, style: F.syne(size: 12.5, color: T.text, height: 1.4))),
                    ]),
                  ),
              ]),
            ),
          ]);
          if (bc.maxWidth < 820) return Column(children: [timeline, checklist]);
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: timeline),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: checklist),
          ]);
        }),
        const SectionTitle('Planner tips'),
        PCard(
          color: T.gold.withValues(alpha: .06),
          border: T.gold.withValues(alpha: .35),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final t in plan.tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('💡', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t, style: F.syne(size: 12.5, color: T.text, height: 1.45))),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 18),
        Wrap(spacing: 10, runSpacing: 10, children: [
          PrimaryBtn('Save as notebook', icon: Icons.book_outlined, onTap: () {
            final nb = app.addNotebook(Notebook.fromPlan(plan,
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                date: _date?.toIso8601String().substring(0, 10) ?? ''));
            app.showToast('Notebook saved', nb.title, '📓');
            widget.onSaved(nb);
          }),
          OutlineBtn('Talk to an event planner', icon: Icons.support_agent_rounded, onTap: () => app.openResults(cat: 'events')),
        ]),
      ],
    ]);
  }
}

String _fmtDate(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

class _BudgetLineRow extends StatelessWidget {
  final BudgetLine line;
  const _BudgetLineRow({required this.line});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final cat = catOf(line.catId);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Expanded(
          flex: 5,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(line.label, style: F.syne(size: 13, weight: FontWeight.w700, color: T.cream)),
            if (cat != null) Text('Find ${cat.name} →', style: F.syne(size: 11, weight: FontWeight.w600, color: T.gold)),
          ]),
        ),
        Expanded(
          flex: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(children: [
              Container(height: 8, color: T.surf),
              FractionallySizedBox(widthFactor: (line.share / .35).clamp(0.0, 1.0), child: Container(height: 8, color: T.gold)),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(width: 36, child: Text('${(line.share * 100).round()}%', textAlign: TextAlign.right, style: F.mono(size: 11, color: T.dim))),
        SizedBox(
          width: 92,
          child: Text(inr(line.amount), textAlign: TextAlign.right, style: F.syne(size: 12.5, weight: FontWeight.w700, color: T.text)),
        ),
      ]),
    );
    if (cat == null) return row;
    return HoverFx(onTap: () => app.openResults(cat: cat.id), builder: (_) => row);
  }
}

// ── Notebooks ────────────────────────────────────────────────────

class _NotebookList extends StatelessWidget {
  final ValueChanged<String> onOpen;
  const _NotebookList({required this.onOpen});

  void _new(BuildContext context) {
    final app = context.read<AppState>();
    final title = TextEditingController();
    String type = plannerEventTypes.first;
    showProgramDialog<void>(
      context,
      eyebrow: 'New notebook',
      title: 'Start a planning notebook',
      body: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LabeledInput(label: 'Event name', hint: 'Annual Day 2026', controller: title, required: true),
          const SizedBox(height: 12),
          Field('Event type', FiSelect(options: plannerEventTypes, value: type, onChanged: (v) => set(() => type = v ?? type))),
          const SizedBox(height: 18),
          PrimaryBtn('Create notebook', expand: true, onTap: () {
            final t = title.text.trim();
            if (t.isEmpty) {
              app.showToast('Name the event', 'A short name is enough', '✏️');
              return;
            }
            final nb = Notebook(id: DateTime.now().microsecondsSinceEpoch.toString(), title: t, type: type, city: app.location)
              ..log('Notebook created');
            app.addNotebook(nb);
            Navigator.of(ctx).maybePop();
            onOpen(nb.id);
          }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
          child: Text('Saved on this device. Each notebook keeps guests, accounts, tasks and a history of changes.',
              style: F.syne(size: 12.5, color: T.mut, height: 1.5)),
        ),
        const SizedBox(width: 12),
        PrimaryBtn('New', icon: Icons.add_rounded, onTap: () => _new(context)),
      ]),
      const SizedBox(height: 16),
      if (app.notebooks.isEmpty)
        EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'No notebooks yet',
          message: 'Generate a plan and save it, or start a blank notebook for an event you are already running.',
          actionLabel: 'Start a blank notebook',
          onAction: () => _new(context),
        )
      else
        AutoGrid(minItemWidth: 280, maxCols: 3, children: [
          for (final n in app.notebooks)
            Semantics(
              button: true,
              label: 'Open notebook ${n.title}',
              child: HoverFx(
                onTap: () => onOpen(n.id),
                builder: (h) => AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: T.card,
                    border: Border.all(color: h ? T.gold : T.bdr),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Text('📓', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(n.title,
                            maxLines: 2, overflow: TextOverflow.ellipsis, style: F.syne(size: 14, weight: FontWeight.w800, color: T.cream)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text([n.type, n.city, n.date].where((s) => s.isNotEmpty).join(' · '), style: F.mono(size: 10.5, color: T.dim)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: StatTile('${n.headcount}', 'Guests')),
                      const SizedBox(width: 8),
                      Expanded(child: StatTile('${n.tasksDone}/${n.tasks.length}', 'Tasks')),
                    ]),
                    const SizedBox(height: 8),
                    StatTile('${inr(n.spent)} of ${inr(n.budget)}', 'Spent of budget', accent: n.remaining < 0 ? T.redText : null),
                  ]),
                ),
              ),
            ),
        ]),
    ]);
  }
}

class _NotebookView extends StatefulWidget {
  final Notebook nb;
  final VoidCallback onBack;
  const _NotebookView({super.key, required this.nb, required this.onBack});

  @override
  State<_NotebookView> createState() => _NotebookViewState();
}

class _NotebookViewState extends State<_NotebookView> {
  String _tab = 'guests';
  late final _notes = TextEditingController(text: widget.nb.notes);

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _save([String? log]) {
    if (log != null) widget.nb.log(log);
    context.read<AppState>().saveNotebooks();
    setState(() {});
  }

  Future<void> _delete() async {
    final app = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: T.scrim,
      builder: (ctx) => AlertDialog(
        backgroundColor: T.card,
        title: Text('Delete this notebook?', style: F.fraunces(size: 18, weight: FontWeight.w700, color: T.cream)),
        content: Text('"${widget.nb.title}" and its guests, accounts and history will be removed from this device. This cannot be undone.',
            style: F.syne(size: 13, color: T.mut, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: F.syne(size: 13, color: T.mut))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete', style: F.syne(size: 13, weight: FontWeight.w700, color: T.redText))),
        ],
      ),
    );
    if (ok == true) {
      app.deleteNotebook(widget.nb.id);
      widget.onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nb = widget.nb;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Semantics(
          button: true,
          label: 'Back to notebooks',
          child: HoverFx(
            onTap: widget.onBack,
            builder: (h) => Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: h ? T.gold : T.bdr), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.arrow_back_rounded, size: 18, color: h ? T.gold : T.mut),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nb.title, style: F.fraunces(size: 20, weight: FontWeight.w700, color: T.cream)),
            Text([nb.type, nb.city, nb.date].where((s) => s.isNotEmpty).join(' · '), style: F.mono(size: 10.5, color: T.dim)),
          ]),
        ),
        Tooltip(
          message: 'Delete notebook',
          child: HoverFx(
            onTap: _delete,
            builder: (h) => Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.delete_outline_rounded, size: 20, color: h ? T.redText : T.dim),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      AutoGrid(minItemWidth: 140, gap: 10, children: [
        StatTile('${nb.headcount}', 'Expected guests'),
        StatTile('${nb.confirmed}', 'Confirmed'),
        StatTile(inr(nb.spent), 'Committed'),
        StatTile(inr(nb.remaining), 'Remaining', accent: nb.remaining < 0 ? T.redText : T.grn),
      ]),
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final t in const [('guests', 'Guests', '👥'), ('budget', 'Accounts', '💰'), ('tasks', 'Tasks', '✅'), ('notes', 'Notes', '📝'), ('history', 'History', '🕘')])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PickChip(label: t.$2, icon: t.$3, active: _tab == t.$1, onTap: () => setState(() => _tab = t.$1)),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      switch (_tab) {
        'budget' => _Budget(nb: nb, onChanged: _save),
        'tasks' => _Tasks(nb: nb, onChanged: _save),
        'notes' => PCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              LabeledInput(label: 'Planning notes', hint: 'Ideas, contacts, run-of-show, seating…', controller: _notes, minLines: 8),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: PrimaryBtn('Save notes', icon: Icons.save_outlined, onTap: () {
                  nb.notes = _notes.text;
                  _save('Notes updated');
                  context.read<AppState>().showToast('Notes saved', nb.title, '📝');
                }),
              ),
            ]),
          ),
        'history' => PCard(
            child: nb.history.isEmpty
                ? Text('No activity yet.', style: F.syne(size: 12.5, color: T.dim))
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    for (final h in nb.history.take(60))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          SizedBox(
                            width: 120,
                            child: Text('${_fmtDate(h.at)} ${h.at.hour.toString().padLeft(2, '0')}:${h.at.minute.toString().padLeft(2, '0')}',
                                style: F.mono(size: 10.5, color: T.dim)),
                          ),
                          Expanded(child: Text(h.text, style: F.syne(size: 12.5, color: T.text, height: 1.4))),
                        ]),
                      ),
                  ]),
          ),
        _ => _Guests(nb: nb, onChanged: _save),
      },
    ]);
  }
}

class _Guests extends StatefulWidget {
  final Notebook nb;
  final void Function([String? log]) onChanged;
  const _Guests({required this.nb, required this.onChanged});

  @override
  State<_Guests> createState() => _GuestsState();
}

class _GuestsState extends State<_Guests> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  int _party = 1;
  String _filter = 'All';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _add() {
    final n = _name.text.trim();
    if (n.isEmpty) return;
    widget.nb.guests.insert(0, NbGuest(name: n, phone: _phone.text.trim(), party: _party));
    _name.clear();
    _phone.clear();
    setState(() => _party = 1);
    widget.onChanged('Guest added: $n');
  }

  @override
  Widget build(BuildContext context) {
    final nb = widget.nb;
    final shown = _filter == 'All' ? nb.guests : nb.guests.where((g) => g.rsvp == _filter).toList();
    final count = {for (final s in const ['Invited', 'Confirmed', 'Declined']) s: nb.guests.where((g) => g.rsvp == s).length};
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PCard(
        child: LayoutBuilder(builder: (context, bc) {
          final name = LabeledInput(label: 'Guest name', hint: 'Full name', controller: _name);
          final phone = LabeledInput(label: 'Phone', hint: 'Optional', controller: _phone, keyboardType: TextInputType.phone);
          final party = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Fl('Party'),
            Row(mainAxisSize: MainAxisSize.min, children: [
              _Stepper(icon: Icons.remove_rounded, onTap: _party > 1 ? () => setState(() => _party--) : null),
              SizedBox(width: 34, child: Text('$_party', textAlign: TextAlign.center, style: F.syne(size: 14, weight: FontWeight.w700, color: T.cream))),
              _Stepper(icon: Icons.add_rounded, onTap: _party < 20 ? () => setState(() => _party++) : null),
            ]),
          ]);
          final btn = PrimaryBtn('Add guest', icon: Icons.person_add_alt_1_rounded, onTap: _add);
          if (bc.maxWidth < 640) {
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              name,
              const SizedBox(height: 10),
              phone,
              const SizedBox(height: 10),
              Row(children: [party, const Spacer(), btn]),
            ]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(flex: 3, child: name),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: phone),
            const SizedBox(width: 10),
            party,
            const SizedBox(width: 10),
            btn,
          ]);
        }),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        PickChip(label: 'All (${nb.guests.length})', active: _filter == 'All', onTap: () => setState(() => _filter = 'All')),
        for (final e in count.entries)
          PickChip(label: '${e.key} (${e.value})', active: _filter == e.key, onTap: () => setState(() => _filter = e.key)),
      ]),
      const SizedBox(height: 12),
      if (shown.isEmpty)
        const EmptyState(icon: Icons.groups_outlined, title: 'No guests here yet', message: 'Add guests above and track their RSVPs.')
      else
        PCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(children: [
            for (final g in shown)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: T.bdr.withValues(alpha: .6)))),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(g.party > 1 ? '${g.name}  +${g.party - 1}' : g.name,
                          style: F.syne(size: 13, weight: FontWeight.w700, color: T.cream)),
                      if (g.phone.isNotEmpty) Text(g.phone, style: F.mono(size: 10.5, color: T.dim)),
                    ]),
                  ),
                  SizedBox(
                    width: 130,
                    child: FiSelect(
                      options: const ['Invited', 'Confirmed', 'Declined'],
                      value: g.rsvp,
                      onChanged: (v) {
                        if (v == null || v == g.rsvp) return;
                        g.rsvp = v;
                        widget.onChanged('${g.name} marked $v');
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Remove guest',
                    child: HoverFx(
                      onTap: () {
                        nb.guests.remove(g);
                        widget.onChanged('Guest removed: ${g.name}');
                      },
                      builder: (h) => Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.close_rounded, size: 16, color: h ? T.redText : T.faint),
                      ),
                    ),
                  ),
                ]),
              ),
          ]),
        ),
    ]);
  }
}

class _Stepper extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _Stepper({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => HoverFx(
        onTap: onTap,
        builder: (h) => Container(
          width: 34,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: onTap == null ? T.bdr : (h ? T.gold : T.bdhi)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: onTap == null ? T.faint : T.text),
        ),
      );
}

class _Budget extends StatefulWidget {
  final Notebook nb;
  final void Function([String? log]) onChanged;
  const _Budget({required this.nb, required this.onChanged});

  @override
  State<_Budget> createState() => _BudgetState();
}

class _BudgetState extends State<_Budget> {
  final _label = TextEditingController();
  final _amount = TextEditingController();
  late final _budget = TextEditingController(text: widget.nb.budget.round().toString());

  @override
  void dispose() {
    for (final c in [_label, _amount, _budget]) {
      c.dispose();
    }
    super.dispose();
  }

  void _add() {
    final l = _label.text.trim();
    final a = double.tryParse(_amount.text.trim()) ?? 0;
    if (l.isEmpty || a <= 0) {
      context.read<AppState>().showToast('Add a label and an amount', 'e.g. "Stage & lights" · 45000', '✏️');
      return;
    }
    widget.nb.expenses.insert(0, NbExpense(label: l, amount: a, category: 'Expense'));
    _label.clear();
    _amount.clear();
    widget.onChanged('Expense added: $l · ${inr(a)}');
  }

  @override
  Widget build(BuildContext context) {
    final nb = widget.nb;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: LabeledInput(
                label: 'Total budget (₹)',
                hint: '500000',
                controller: _budget,
                keyboardType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 10),
            OutlineBtn('Update', onTap: () {
              final b = double.tryParse(_budget.text.trim());
              if (b == null) return;
              nb.budget = b;
              widget.onChanged('Budget set to ${inr(b)}');
            }),
          ]),
          const SizedBox(height: 14),
          AutoGrid(minItemWidth: 130, gap: 8, children: [
            StatTile(inr(nb.budget), 'Budget'),
            StatTile(inr(nb.spent), 'Committed'),
            StatTile(inr(nb.paid), 'Paid'),
            StatTile(inr(nb.spent - nb.paid), 'Due'),
          ]),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, bc) {
            final l = LabeledInput(label: 'Expense', hint: 'Stage & lights', controller: _label);
            final a = LabeledInput(
                label: 'Amount (₹)', hint: '45000', controller: _amount, keyboardType: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly]);
            final b = PrimaryBtn('Add', icon: Icons.add_rounded, onTap: _add);
            if (bc.maxWidth < 560) {
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [l, const SizedBox(height: 10), a, const SizedBox(height: 10), b]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(flex: 3, child: l),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: a),
              const SizedBox(width: 10),
              b,
            ]);
          }),
        ]),
      ),
      const SizedBox(height: 12),
      if (nb.expenses.isEmpty)
        const EmptyState(icon: Icons.receipt_long_outlined, title: 'No entries yet', message: 'Add vendor quotes and payments to keep the accounts straight.')
      else
        PCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(children: [
            for (final e in nb.expenses)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: T.bdr.withValues(alpha: .6)))),
                child: Row(children: [
                  Tooltip(
                    message: e.paid ? 'Mark unpaid' : 'Mark paid',
                    child: HoverFx(
                      onTap: () {
                        e.paid = !e.paid;
                        widget.onChanged('${e.label} marked ${e.paid ? 'paid' : 'unpaid'}');
                      },
                      builder: (h) => Icon(e.paid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 20, color: e.paid ? T.grn : (h ? T.gold : T.dim)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.label, style: F.syne(size: 13, weight: FontWeight.w700, color: T.cream)),
                      Text(e.paid ? 'Paid' : (e.category.isEmpty ? 'Due' : '${e.category} · due'),
                          style: F.syne(size: 10.5, weight: FontWeight.w600, color: e.paid ? T.grn : T.dim)),
                    ]),
                  ),
                  Text(inr(e.amount), style: F.syne(size: 13, weight: FontWeight.w700, color: T.text)),
                  Tooltip(
                    message: 'Remove entry',
                    child: HoverFx(
                      onTap: () {
                        nb.expenses.remove(e);
                        widget.onChanged('Entry removed: ${e.label}');
                      },
                      builder: (h) => Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.close_rounded, size: 16, color: h ? T.redText : T.faint),
                      ),
                    ),
                  ),
                ]),
              ),
          ]),
        ),
    ]);
  }
}

class _Tasks extends StatefulWidget {
  final Notebook nb;
  final void Function([String? log]) onChanged;
  const _Tasks({required this.nb, required this.onChanged});

  @override
  State<_Tasks> createState() => _TasksState();
}

class _TasksState extends State<_Tasks> {
  final _task = TextEditingController();

  @override
  void dispose() {
    _task.dispose();
    super.dispose();
  }

  void _add() {
    final t = _task.text.trim();
    if (t.isEmpty) return;
    widget.nb.tasks.add(NbTask(label: t));
    _task.clear();
    widget.onChanged('Task added: $t');
  }

  @override
  Widget build(BuildContext context) {
    final nb = widget.nb;
    final pct = nb.tasks.isEmpty ? 0.0 : nb.tasksDone / nb.tasks.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: LabeledInput(label: 'New task', hint: 'Confirm sound check time', controller: _task)),
            const SizedBox(width: 10),
            PrimaryBtn('Add', icon: Icons.add_rounded, onTap: _add),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: T.surf, color: T.grn),
              ),
            ),
            const SizedBox(width: 10),
            Text('${nb.tasksDone}/${nb.tasks.length} done', style: F.mono(size: 11, color: T.dim)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      if (nb.tasks.isEmpty)
        const EmptyState(icon: Icons.checklist_rounded, title: 'No tasks yet', message: 'Add tasks or save a generated plan to fill this in.')
      else
        PCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(children: [
            for (final t in nb.tasks)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: T.bdr.withValues(alpha: .6)))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  HoverFx(
                    onTap: () {
                      t.done = !t.done;
                      widget.onChanged('${t.done ? 'Done' : 'Reopened'}: ${t.label}');
                    },
                    builder: (h) => Icon(t.done ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        size: 20, color: t.done ? T.grn : (h ? T.gold : T.dim)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.label,
                          style: F.syne(
                            size: 13,
                            weight: FontWeight.w600,
                            color: t.done ? T.dim : T.text,
                            height: 1.4,
                          ).copyWith(decoration: t.done ? TextDecoration.lineThrough : null)),
                      if (t.when.isNotEmpty) Text(t.when, style: F.mono(size: 10, color: T.gold)),
                    ]),
                  ),
                  HoverFx(
                    onTap: () {
                      nb.tasks.remove(t);
                      widget.onChanged('Task removed: ${t.label}');
                    },
                    builder: (h) => Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 16, color: h ? T.redText : T.faint),
                    ),
                  ),
                ]),
              ),
          ]),
        ),
    ]);
  }
}
