import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tokens.dart';
import 'common.dart';

/// Shared building blocks for the programme pages (Shoots, Campaigns,
/// Onboarding, Open School, Planner). Each is a thin wrapper over the same
/// tokens the rest of the app uses, so the new pages cannot drift from the
/// established look.

/// Section title + optional dek and trailing action.
class SectionTitle extends StatelessWidget {
  final String title;
  final String? dek;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;
  const SectionTitle(this.title,
      {super.key, this.dek, this.action, this.onAction, this.padding = const EdgeInsets.fromLTRB(0, 32, 0, 14)});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    final heading = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: F.fraunces(size: narrow ? 20 : 23, weight: FontWeight.w700, color: T.cream, height: 1.2)),
      if (dek != null) ...[
        const SizedBox(height: 6),
        Text(dek!, style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut, height: 1.55)),
      ],
    ]);
    final hasAction = action != null && onAction != null;
    final link = hasAction
        ? Semantics(
            button: true,
            label: action,
            child: HoverFx(
              onTap: onAction,
              builder: (h) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('$action →', style: F.syne(size: 12.5, weight: FontWeight.w700, color: h ? T.goldLight : T.gold)),
              ),
            ),
          )
        : null;
    return Padding(
      padding: padding,
      // On a phone the action sits under the heading: side by side, a long
      // title and a long action fight for 288px and one of them overflows.
      child: narrow
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [heading, if (link != null) ...[const SizedBox(height: 6), link]])
          : Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: heading),
              if (link != null) ...[const SizedBox(width: 12), link],
            ]),
    );
  }
}

/// Small uppercase pill.
class Tag extends StatelessWidget {
  final String text;
  final Color? color;
  final bool solid;
  const Tag(this.text, {super.key, this.color, this.solid = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? T.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: solid ? c : c.withValues(alpha: .10),
        border: Border.all(color: c.withValues(alpha: solid ? 1 : .38)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text.toUpperCase(),
          style: F.syne(size: 9.5, weight: FontWeight.w800, color: solid ? T.onAccent(c) : c, letterSpacing: 1.1)),
    );
  }
}

/// Selectable chip used for filters and multi-select choices.
class PickChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final String? icon;
  final Color? accent;
  const PickChip({super.key, required this.label, required this.active, required this.onTap, this.icon, this.accent});

  @override
  Widget build(BuildContext context) {
    final a = accent ?? T.gold;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: HoverFx(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? a.withValues(alpha: .14) : (h ? T.surf : T.card),
            border: Border.all(color: active ? a : (h ? T.bdhi : T.bdr)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Text(icon!, style: const TextStyle(fontSize: 13)), const SizedBox(width: 6)],
            if (active && icon == null) ...[Icon(Icons.check_rounded, size: 13, color: a), const SizedBox(width: 4)],
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: F.syne(size: 12, weight: FontWeight.w700, color: active ? a : T.text)),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Primary solid button (cream → gold on hover), matching the app's CTA.
class PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool busy;
  final bool expand;
  const PrimaryBtn(this.label, {super.key, this.onTap, this.icon, this.busy = false, this.expand = false});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null || busy;
    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      child: HoverFx(
        onTap: disabled ? null : onTap,
        builder: (h) {
          final bg = disabled ? T.goldDark.withValues(alpha: busy ? 1 : .45) : (h ? T.gold : T.cream);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: T.onAccent(bg)))
                else if (icon != null)
                  Icon(icon, size: 16, color: T.onAccent(bg)),
                if (busy || icon != null) const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: F.syne(size: 13, weight: FontWeight.w700, color: T.onAccent(bg))),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Outline button.
class OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expand;
  const OutlineBtn(this.label, {super.key, this.onTap, this.icon, this.expand = false});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: HoverFx(
          onTap: onTap,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: h ? T.gold.withValues(alpha: .08) : Colors.transparent,
              border: Border.all(color: h ? T.gold : T.bdhi),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 15, color: h ? T.gold : T.text), const SizedBox(width: 7)],
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: F.syne(size: 12.5, weight: FontWeight.w700, color: h ? T.gold : T.text)),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Two-to-four way segmented tabs.
class SegTabs extends StatelessWidget {
  final List<(String id, String label, String icon)> tabs;
  final String active;
  final ValueChanged<String> onChanged;
  const SegTabs({super.key, required this.tabs, required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: T.surf, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        for (final t in tabs)
          Expanded(
            child: Semantics(
              button: true,
              selected: t.$1 == active,
              label: t.$2,
              child: HoverFx(
                onTap: () => onChanged(t.$1),
                builder: (h) {
                  final on = t.$1 == active;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: EdgeInsets.symmetric(vertical: narrow ? 10 : 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: on ? T.gold : (h ? T.card : Colors.transparent),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(t.$3, style: TextStyle(fontSize: narrow ? 13 : 15)),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(t.$2,
                            overflow: TextOverflow.ellipsis,
                            style: F.syne(
                                size: narrow ? 12 : 13.5,
                                weight: FontWeight.w700,
                                color: on ? T.onAccent(T.gold) : T.text)),
                      ),
                    ]),
                  );
                },
              ),
            ),
          ),
      ]),
    );
  }
}

/// Plain bordered card.
class PCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? border;
  final Color? color;
  const PCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.border, this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? T.card,
          border: Border.all(color: border ?? T.bdr),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );
}

/// A number + label tile.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color? accent;
  const StatTile(this.value, this.label, {super.key, this.accent});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: T.surf, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: F.fraunces(size: 20, weight: FontWeight.w700, color: accent ?? T.cream)),
          ),
          const SizedBox(height: 2),
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: F.syne(size: 11, weight: FontWeight.w600, color: T.dim)),
        ]),
      );
}

/// Responsive grid: lays children out in as many columns of at least
/// [minItemWidth] as fit, all the same width.
class AutoGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double gap;
  final int maxCols;
  const AutoGrid({super.key, required this.children, this.minItemWidth = 260, this.gap = 14, this.maxCols = 4});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, bc) {
        final cols = ((bc.maxWidth + gap) / (minItemWidth + gap)).floor().clamp(1, maxCols);
        final w = (bc.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final c in children) SizedBox(width: w, child: c)],
        );
      });
}

/// A horizontal bar with a label and count — used for city-wise reports.
class BarRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color? color;
  const BarRow({super.key, required this.label, required this.value, required this.max, this.color});

  @override
  Widget build(BuildContext context) {
    final f = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    final c = color ?? T.gold;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 96,
          child: Text(label, overflow: TextOverflow.ellipsis, style: F.syne(size: 12, weight: FontWeight.w600, color: T.text)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(children: [
              Container(height: 10, color: T.surf),
              FractionallySizedBox(widthFactor: f, child: Container(height: 10, color: c)),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: Text('$value', textAlign: TextAlign.right, style: F.mono(size: 11.5, color: T.mut)),
        ),
      ]),
    );
  }
}

/// A text field with a label, validation message and keyboard type — the
/// programme forms need inline errors, which the base [Fi] does not show.
class LabeledInput extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int minLines;
  final String? error;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;
  final bool required;
  const LabeledInput({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.minLines = 1,
    this.error,
    this.formatters,
    this.onChanged,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder b(Color c) =>
        OutlineInputBorder(borderSide: BorderSide(color: c), borderRadius: const BorderRadius.all(Radius.circular(7)));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: label.toUpperCase()),
          if (required) TextSpan(text: ' *', style: TextStyle(color: T.redText)),
        ]), style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 1.5)),
      ),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: minLines > 1 ? minLines + 3 : 1,
        inputFormatters: formatters,
        onChanged: onChanged,
        style: F.syne(size: 13, weight: FontWeight.w400, color: T.text),
        cursorColor: T.gold,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: T.surf,
          hintText: hint,
          hintStyle: F.syne(size: 13, weight: FontWeight.w400, color: T.dim),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: b(T.bdr),
          enabledBorder: b(error != null ? T.redText : T.bdr),
          focusedBorder: b(error != null ? T.redText : T.gold),
        ),
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(error!, style: F.syne(size: 11, weight: FontWeight.w600, color: T.redText)),
        ),
    ]);
  }
}

/// Lays two form fields side by side on wide screens, stacked on phones.
class FieldPair extends StatelessWidget {
  final Widget left;
  final Widget right;
  const FieldPair(this.left, this.right, {super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, bc) {
        if (bc.maxWidth < 520) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, const SizedBox(height: 12), right]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ]);
      });
}

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
bool validEmail(String s) => _emailRe.hasMatch(s.trim());

/// Indian mobile numbers, with or without +91 / spaces / dashes.
bool validPhone(String s) {
  final d = s.replaceAll(RegExp(r'[^0-9]'), '');
  final local = d.length == 12 && d.startsWith('91') ? d.substring(2) : d;
  return local.length == 10 && RegExp(r'^[6-9]').hasMatch(local);
}

/// A modal dialog shell matching the app's booking dialogs.
Future<R?> showProgramDialog<R>(BuildContext context,
    {required String eyebrow, required String title, String? sub, required Widget Function(BuildContext) body}) {
  return showDialog<R>(
    context: context,
    barrierColor: T.scrim,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isNarrow(ctx) ? 14 : 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          decoration: BoxDecoration(color: T.card, border: Border.all(color: T.bdr), borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: BoxDecoration(color: T.surf, border: Border(bottom: BorderSide(color: T.bdr))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(eyebrow.toUpperCase(),
                          style: F.syne(size: 9.5, weight: FontWeight.w800, color: T.gold, letterSpacing: 1.6)),
                      const SizedBox(height: 8),
                      Text(title, style: F.fraunces(size: 19, weight: FontWeight.w700, color: T.cream, height: 1.2)),
                      if (sub != null) ...[
                        const SizedBox(height: 6),
                        Text(sub, style: F.syne(size: 12, weight: FontWeight.w500, color: T.dim, height: 1.5)),
                      ],
                    ]),
                  ),
                  Semantics(
                    button: true,
                    label: 'Close',
                    child: HoverFx(
                      onTap: () => Navigator.of(ctx).maybePop(),
                      builder: (h) => Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            border: Border.all(color: h ? T.bdhi : T.bdr), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.close_rounded, size: 16, color: h ? T.cream : T.mut),
                      ),
                    ),
                  ),
                ]),
              ),
              Padding(padding: const EdgeInsets.all(20), child: body(ctx)),
            ]),
          ),
        ),
      ),
    ),
  );
}
