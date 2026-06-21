import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// `.fl` — tiny uppercase field label.
class Fl extends StatelessWidget {
  final String text;
  const Fl(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text.toUpperCase(),
            style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 1.5)),
      );
}

const _fiBorder = OutlineInputBorder(
  borderSide: BorderSide(color: T.bdr),
  borderRadius: BorderRadius.all(Radius.circular(7)),
);
const _fiFocus = OutlineInputBorder(
  borderSide: BorderSide(color: T.gold),
  borderRadius: BorderRadius.all(Radius.circular(7)),
);

/// `.fi` — text input.
class Fi extends StatelessWidget {
  final String placeholder;
  final bool obscure;
  final int minLines;
  final TextInputType? keyboardType;
  const Fi(this.placeholder,
      {super.key, this.obscure = false, this.minLines = 1, this.keyboardType});
  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscure,
      minLines: minLines,
      maxLines: obscure ? 1 : (minLines > 1 ? minLines + 3 : 1),
      keyboardType: keyboardType,
      style: F.syne(size: 13, weight: FontWeight.w400, color: T.text),
      cursorColor: T.gold,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: T.surf,
        hintText: placeholder,
        hintStyle: F.syne(size: 13, weight: FontWeight.w400, color: T.dim),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: _fiBorder,
        enabledBorder: _fiBorder,
        focusedBorder: _fiFocus,
      ),
    );
  }
}

/// `.fi.fi-sel` — styled dropdown.
class FiSelect extends StatefulWidget {
  final List<String> options;
  final String? value;
  final ValueChanged<String?>? onChanged;
  const FiSelect({super.key, required this.options, this.value, this.onChanged});
  @override
  State<FiSelect> createState() => _FiSelectState();
}

class _FiSelectState extends State<FiSelect> {
  late String _val = widget.value ?? widget.options.first;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: T.surf,
        border: Border.all(color: T.bdr),
        borderRadius: BorderRadius.circular(7),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _val,
          isExpanded: true,
          isDense: true,
          dropdownColor: T.card,
          icon: const Icon(Icons.keyboard_arrow_down, color: T.dim, size: 18),
          style: F.syne(size: 13, weight: FontWeight.w400, color: T.text),
          items: [
            for (final o in widget.options)
              DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _val = v);
            widget.onChanged?.call(v);
          },
        ),
      ),
    );
  }
}

/// A labelled field group (label above input).
class Field extends StatelessWidget {
  final String label;
  final Widget child;
  const Field(this.label, this.child, {super.key});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [Fl(label), child],
      );
}
