import 'package:flutter_test/flutter_test.dart';
import 'package:aonego9_user/data/taxonomy.dart';

void main() {
  group('catIdFromBackend', () {
    test('does not file female models as male', () {
      // Regression: the old inline mapping used rawCat.contains('male'),
      // which matches the "male" inside "female" — every female model was
      // being categorised as modelM.
      expect(catIdFromBackend('Female Model'), 'modelF');
      expect(catIdFromBackend('female models'), 'modelF');
      expect(catIdFromBackend('Male Model'), 'modelM');
    });

    test('prefers the more specific vertical', () {
      expect(catIdFromBackend('Makeup Studio'), 'makeupStudio');
      expect(catIdFromBackend('Makeup Artist'), 'makeupArtist');
      expect(catIdFromBackend('Video Editor'), 'editVideo');
      expect(catIdFromBackend('Videography'), 'video');
      expect(catIdFromBackend('Photo Studio'), 'studio');
      expect(catIdFromBackend('Photography'), 'photo');
    });

    test('maps every new vertical the brief added', () {
      expect(catIdFromBackend('VFX'), 'editVfx');
      expect(catIdFromBackend('3D Animation'), 'edit3d');
      expect(catIdFromBackend('Graphic Designer'), 'editGraphic');
      expect(catIdFromBackend('Fashion Designer'), 'designer');
      expect(catIdFromBackend('Cloth Showroom'), 'clothShop');
      expect(catIdFromBackend('Jewellery Shop'), 'jewellery');
      expect(catIdFromBackend('Hotel'), 'hotel');
      expect(catIdFromBackend('Modelling Academy'), 'academy');
    });

    test('falls back rather than throwing on junk', () {
      expect(catIdFromBackend(''), 'modelF');
      expect(catIdFromBackend('   '), 'modelF');
      expect(catIdFromBackend('qwertyuiop'), 'modelF');
    });
  });

  group('catalogue integrity', () {
    test('every category id is unique', () {
      final ids = catalogue.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every category belongs to a real division', () {
      for (final c in catalogue) {
        expect(divisionById.containsKey(c.division), isTrue,
            reason: '${c.id} points at unknown division ${c.division}');
      }
    });

    test('every division holds at least one category', () {
      for (final d in divisions) {
        expect(catsByDivision[d.id], isNotEmpty, reason: '${d.id} is empty');
      }
    });

    test('the original six ids survive so old deep links still resolve', () {
      for (final id in ['venue', 'photo', 'video', 'modelF', 'modelM', 'events']) {
        expect(catById.containsKey(id), isTrue, reason: '$id disappeared');
      }
    });

    test('legacy slugs still map', () {
      expect(catIdFromSlug('venues'), 'venue');
      expect(catIdFromSlug('photography'), 'photo');
      expect(catIdFromSlug('models'), 'modelF');
      expect(catIdFromSlug('event-services'), 'events');
      // A slug that is already an id passes through untouched.
      expect(catIdFromSlug('jewellery'), 'jewellery');
    });

    test('divisionOf resolves for every category', () {
      for (final c in catalogue) {
        expect(divisionOf(c.id), c.division);
      }
    });
  });
}
