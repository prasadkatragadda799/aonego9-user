import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/programs.dart';
import '../data/taxonomy.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/lead_capture.dart';
import '../widgets/program_kit.dart';

/// AOneGo9 Open School — the platform's own academy, the education sector's
/// listings (schools, colleges, universities, classes, coaches), and the
/// admission form.
class AcademyScreen extends StatelessWidget {
  const AcademyScreen({super.key});

  static const _streamIcons = ['💃', '🎭', '💄', '📷', '🎬', '✂️', '🕺', '🎪', '📱'];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pad = isNarrow(context) ? 16.0 : 24.0;
    final eduSessions = app.sessions.where((s) => s.division == 'education').toList();

    return PageFrame(
      title: 'Open School',
      body: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 56),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const PageIntro(
            eyebrow: 'Education sector · AOneGo9 Open School',
            motif: 'education',
            title: 'Learn the craft from the people who book it.',
            dek: 'Courses in modelling, acting, makeup, photography, film and design from the AOneGo9 Open School — '
                'alongside verified schools, colleges, universities, classes and coaches.',
          ),
          const SectionTitle('What you can study'),
          AutoGrid(minItemWidth: 190, gap: 10, children: [
            for (var i = 0; i < openSchoolStreams.length; i++)
              PCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(children: [
                  Text(_streamIcons[i % _streamIcons.length], style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(openSchoolStreams[i], style: F.syne(size: 13, weight: FontWeight.w700, color: T.cream))),
                ]),
              ),
          ]),
          SectionTitle('Programmes & intakes',
              dek: 'Open School courses with fees, duration and the next intake.',
              action: 'Workshops & webinars',
              onAction: () => app.setView('sessions')),
          if (app.programsLoading && app.courses.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else if (app.courses.isEmpty)
            EmptyState(
              icon: Icons.school_outlined,
              title: 'The next intake is being finalised',
              message: eduSessions.isEmpty
                  ? 'Programmes are published here with fees and dates. Apply below and we\'ll hold a seat for you.'
                  : 'Meanwhile, ${eduSessions.length} education workshop${eduSessions.length == 1 ? ' is' : 's are'} open for registration.',
              actionLabel: eduSessions.isEmpty ? null : 'See workshops',
              onAction: eduSessions.isEmpty ? null : () => app.setView('sessions'),
            )
          else
            AutoGrid(minItemWidth: 290, maxCols: 3, children: [for (final c in app.courses) _CourseCard(course: c)]),
          const SectionTitle('Apply for admission',
              dek: 'One form for every Open School programme. The admissions desk calls you within two working days.'),
          const _AdmissionForm(),
          const SectionTitle('Schools, colleges & coaches on AOneGo9',
              dek: 'Third-party education profiles — browse verified institutions near you.'),
          AutoGrid(minItemWidth: 230, gap: 12, children: [
            for (final c in catsByDivision['education'] ?? const <Cat>[]) _EduCat(cat: c),
          ]),
          const SizedBox(height: 22),
          PCard(
            child: Wrap(
              spacing: 14,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Run a school, college or academy?', style: F.fraunces(size: 18, weight: FontWeight.w700, color: T.cream)),
                    const SizedBox(height: 4),
                    Text('List your institution, run admission campaigns, manage student records and fees, and plan your '
                        'fests and annual days with the AI event planner.',
                        style: F.syne(size: 13, color: T.mut, height: 1.5)),
                  ]),
                ),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  PrimaryBtn('List your institution', icon: Icons.add_business_outlined, onTap: () => app.openOnboard('school')),
                  OutlineBtn('Plan an institution event', icon: Icons.auto_awesome_outlined, onTap: () => app.setView('planner')),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final c = course;
    final facts = [
      if (c.duration.isNotEmpty) ('Duration', c.duration),
      ('Mode', c.mode),
      if (c.fee.isNotEmpty) ('Fee', c.fee),
      if (c.intake.isNotEmpty) ('Next intake', c.intake),
    ];
    return Container(
      decoration: BoxDecoration(color: T.card, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(height: 90, child: GradientArt(bgIndex: c.bg, emoji: c.emoji, emojiSize: 34)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (c.stream.isNotEmpty) ...[Tag(c.stream), const SizedBox(height: 8)],
            Text(c.title, style: F.fraunces(size: 17, weight: FontWeight.w700, color: T.cream, height: 1.25)),
            if (c.blurb.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(c.blurb, maxLines: 3, overflow: TextOverflow.ellipsis, style: F.syne(size: 12.5, color: T.mut, height: 1.5)),
            ],
            const SizedBox(height: 10),
            for (final f in facts)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  SizedBox(width: 92, child: Text(f.$1, style: F.syne(size: 11.5, weight: FontWeight.w600, color: T.dim))),
                  Expanded(child: Text(f.$2, style: F.syne(size: 12, weight: FontWeight.w600, color: T.text))),
                ]),
              ),
            if (c.city.isNotEmpty || c.seats > 0)
              Text([if (c.city.isNotEmpty) c.city, if (c.seats > 0) '${c.seats} seats'].join(' · '), style: F.mono(size: 10.5, color: T.dim)),
            const SizedBox(height: 12),
            PrimaryBtn('Apply for admission',
                expand: true,
                onTap: () => showProgramDialog<void>(
                      context,
                      eyebrow: 'Admission',
                      title: c.title,
                      sub: [c.mode, c.intake].where((s) => s.isNotEmpty).join(' · '),
                      body: (_) => _AdmissionForm(course: c),
                    )),
          ]),
        ),
      ]),
    );
  }
}

class _AdmissionForm extends StatefulWidget {
  final Course? course;
  const _AdmissionForm({this.course});

  @override
  State<_AdmissionForm> createState() => _AdmissionFormState();
}

class _AdmissionFormState extends State<_AdmissionForm> {
  late String _stream = widget.course?.stream.isNotEmpty == true && openSchoolStreams.contains(widget.course!.stream)
      ? widget.course!.stream
      : openSchoolStreams.first;
  String _mode = 'Classroom';
  String _level = 'Beginner';
  final _age = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _age.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = LeadCapture(
      kind: 'admission',
      submitLabel: 'Submit admission form',
      successTitle: 'Admission form submitted',
      successBody: 'The admissions desk will call you to confirm the batch, fee and documents.',
      payload: () => {
        if (widget.course != null) 'course_id': widget.course!.id,
        if (widget.course != null) 'course_title': widget.course!.title,
        'stream': _stream,
        'mode': _mode,
        'level': _level,
        'age': _age.text.trim(),
        'message': _note.text.trim(),
      },
      extra: [
        if (widget.course == null)
          Field('Stream', FiSelect(options: openSchoolStreams, value: _stream, onChanged: (v) => setState(() => _stream = v ?? _stream))),
        FieldPair(
          Field('Mode',
              FiSelect(options: const ['Classroom', 'Online', 'Hybrid'], value: _mode, onChanged: (v) => setState(() => _mode = v ?? _mode))),
          Field('Level',
              FiSelect(options: const ['Beginner', 'Intermediate', 'Professional'], value: _level, onChanged: (v) => setState(() => _level = v ?? _level))),
        ),
        LabeledInput(label: 'Age', hint: 'e.g. 19', controller: _age, keyboardType: TextInputType.number),
        LabeledInput(label: 'Anything we should know', hint: 'Experience, preferred batch timings, questions', controller: _note, minLines: 2),
      ],
    );
    if (widget.course != null) return form;
    return PCard(padding: EdgeInsets.all(isNarrow(context) ? 16 : 22), child: form);
  }
}

class _EduCat extends StatelessWidget {
  final Cat cat;
  const _EduCat({required this.cat});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final a = T.ac(cat.id);
    return Semantics(
      button: true,
      label: 'Browse ${cat.name}',
      child: HoverFx(
        onTap: () => app.openResults(cat: cat.id),
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: h ? a.withValues(alpha: .08) : T.card,
            border: Border.all(color: h ? a : T.bdr),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Text(cat.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cat.name, style: F.syne(size: 13.5, weight: FontWeight.w800, color: T.cream)),
                const SizedBox(height: 3),
                Text(cat.sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: F.syne(size: 11.5, color: T.dim, height: 1.4)),
              ]),
            ),
            Icon(Icons.arrow_forward_rounded, size: 16, color: h ? a : T.faint),
          ]),
        ),
      ),
    );
  }
}
