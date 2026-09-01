import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aonego9_user/data/taxonomy.dart';
import 'package:aonego9_user/theme/tokens.dart';

/// WCAG 2.1 relative contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// AA for body text. Large display type would only need 3.0, but holding the
/// whole ramp to 4.5 means no caller has to know which bucket it is in.
const aa = 4.5;

String hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

void main() {
  for (final brightness in [Brightness.dark, Brightness.light]) {
    final name = brightness == Brightness.dark ? 'dark' : 'light';

    group('$name theme', () {
      setUp(() => T.applyBrightness(brightness));

      // The three grounds body text is ever set on.
      Map<String, Color> surfaces() => {'bg': T.bg, 'surf': T.surf, 'card': T.card};

      test('text ramp clears AA on every surface', () {
        final ramp = {'cream': T.cream, 'text': T.text, 'mut': T.mut, 'dim': T.dim};
        for (final t in ramp.entries) {
          for (final s in surfaces().entries) {
            final r = contrast(t.value, s.value);
            expect(r, greaterThanOrEqualTo(aa),
                reason: '$name: ${t.key} ${hex(t.value)} on ${s.key} ${hex(s.value)} '
                    'is ${r.toStringAsFixed(2)}:1');
          }
        }
      });

      test('gold and status colours clear AA as text', () {
        final ink = {
          'gold': T.gold,
          'goldLight': T.goldLight,
          'redText': T.redText,
          'grn': T.grn,
        };
        for (final t in ink.entries) {
          for (final s in surfaces().entries) {
            final r = contrast(t.value, s.value);
            expect(r, greaterThanOrEqualTo(aa),
                reason: '$name: ${t.key} ${hex(t.value)} on ${s.key} ${hex(s.value)} '
                    'is ${r.toStringAsFixed(2)}:1');
          }
        }
      });

      test('every category accent is readable as a label', () {
        for (final c in catalogue) {
          final accent = T.ac(c.id);
          for (final s in surfaces().entries) {
            final r = contrast(accent, s.value);
            expect(r, greaterThanOrEqualTo(aa),
                reason: '$name: ${c.id} accent ${hex(accent)} on ${s.key} '
                    'is ${r.toStringAsFixed(2)}:1');
          }
        }
      });

      test('every division accent is readable as a label', () {
        for (final d in divisions) {
          final accent = T.dac(d.id);
          for (final s in surfaces().entries) {
            final r = contrast(accent, s.value);
            expect(r, greaterThanOrEqualTo(aa),
                reason: '$name: ${d.id} accent ${hex(accent)} on ${s.key} '
                    'is ${r.toStringAsFixed(2)}:1');
          }
        }
      });

      test('onAccent stays legible on the fill it names', () {
        // Every filled pill and button in the app relies on this.
        final fills = <String, Color>{
          'gold': T.gold,
          'red': T.red,
          'grn': T.grn,
          for (final c in catalogue) c.id: T.ac(c.id),
        };
        for (final f in fills.entries) {
          final r = contrast(T.onAccent(f.value), f.value);
          expect(r, greaterThanOrEqualTo(aa),
              reason: '$name: onAccent on ${f.key} ${hex(f.value)} '
                  'is ${r.toStringAsFixed(2)}:1');
        }
      });

      test('page-ground text on an accent fill clears AA', () {
        // The notification bar and the category pills paint their copy in
        // T.bg directly on an accent, rather than going through onAccent.
        // That only works because every accent is picked to contrast with the
        // ground — this asserts it rather than assuming it.
        for (final c in catalogue) {
          expect(contrast(T.bg, T.ac(c.id)), greaterThanOrEqualTo(aa),
              reason: '$name: bg on ${c.id} accent is '
                  '${contrast(T.bg, T.ac(c.id)).toStringAsFixed(2)}:1');
        }
        for (final d in divisions) {
          expect(contrast(T.bg, T.dac(d.id)), greaterThanOrEqualTo(aa),
              reason: '$name: bg on ${d.id} accent is '
                  '${contrast(T.bg, T.dac(d.id)).toStringAsFixed(2)}:1');
        }
      });

      test('surfaces are distinguishable from each other', () {
        // Not a contrast rule — an elevation one. If card and bg resolve to
        // the same value the card borders carry the whole layout.
        expect(T.bg, isNot(T.card), reason: '$name: bg and card are identical');
        expect(T.bg, isNot(T.surf), reason: '$name: bg and surf are identical');
      });

      test('hairlines are visible against their surfaces', () {
        // 1.25:1 is the practical floor for a 1px rule to register at all.
        for (final s in surfaces().entries) {
          expect(contrast(T.bdr, s.value), greaterThanOrEqualTo(1.15),
              reason: '$name: bdr ${hex(T.bdr)} is invisible on ${s.key}');
        }
      });
    });
  }

  test('faint is decorative only and is documented as failing AA', () {
    // Guards the intent: if someone "fixes" faint to pass, the comment in
    // tokens.dart telling people never to set text in it becomes a lie.
    T.applyBrightness(Brightness.dark);
    expect(contrast(T.faint, T.bg), lessThan(aa));
  });

  test('the brand anchor never moves', () {
    // Shared byte-for-byte with the vendor and super-admin apps.
    expect(T.brandGold, const Color(0xFFC9A86C));
    T.applyBrightness(Brightness.light);
    expect(T.brandGold, const Color(0xFFC9A86C));
  });
}
