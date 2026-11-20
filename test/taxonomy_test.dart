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

    test('maps the profile categories from the platform requirements', () {
      expect(catIdFromBackend('Celebrity'), 'celebrity');
      expect(catIdFromBackend('Film Director'), 'director');
      expect(catIdFromBackend('Casting Director'), 'castingDirector');
      expect(catIdFromBackend('Instagram Influencer'), 'influencer');
      expect(catIdFromBackend('Industry Expert'), 'expert');
      expect(catIdFromBackend('Production House'), 'productionHouse');
      expect(catIdFromBackend('Modelling Agency'), 'agency');
      expect(catIdFromBackend('Talent Show Organiser'), 'organiser');
      expect(catIdFromBackend('Event Organizer'), 'organiser');
      expect(catIdFromBackend('University'), 'college');
      expect(catIdFromBackend('Dance Choreographer'), 'coach');
      expect(catIdFromBackend('Brand'), 'brand');
      expect(catIdFromBackend('Mall'), 'mall');
      expect(catIdFromBackend('Shopping Mall'), 'mall');
      expect(catIdFromBackend('Digital Marketing Agency'), 'adAgency');
      expect(catIdFromBackend('Caterer'), 'localVendor');
    });

    test('word-level matches do not leak into unrelated strings', () {
      // "small" contains "mall"; a five-star hotel is not a celebrity.
      expect(catIdFromBackend('Small Photo Studio'), 'studio');
      expect(catIdFromBackend('Five Star Hotel'), 'hotel');
      // The original event mapping still holds.
      expect(catIdFromBackend('Wedding Planner'), 'events');
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
