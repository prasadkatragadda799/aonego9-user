import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aonego9_user/data/directory.dart';
import 'package:aonego9_user/data/geo.dart';
import 'package:aonego9_user/data/taxonomy.dart';
import 'package:aonego9_user/state/app_state.dart';

/// AppState's constructor kicks off network fetches. They fail in a test
/// environment and are caught internally, leaving directory feeds empty —
/// the honest default once seed content was removed.
void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('division ↔ category', () {
    test('starts on the talent division', () {
      final app = AppState();
      expect(app.activeDivision, 'talent');
      expect(app.activeCat, 'modelF');
    });

    test('switching division selects that division\'s first category', () {
      final app = AppState();
      app.switchDivision('beauty');
      expect(app.activeDivision, 'beauty');
      expect(catsByDivision['beauty']!.first.id, app.activeCat);
    });

    test('switching category keeps the division in sync', () {
      final app = AppState();
      // Picked from the footer or a deep link, not via the division rail.
      app.switchCat('jewellery');
      expect(app.activeDivision, 'fashion');
    });

    test('switching to the current division is a no-op', () {
      final app = AppState();
      app.switchCat('modelM');
      app.switchDivision('talent');
      // Must not reset the user back to the division's first category.
      expect(app.activeCat, 'modelM');
    });

    test('every division is reachable and lands on a real category', () {
      final app = AppState();
      for (final d in divisions) {
        app.switchDivision(d.id);
        expect(app.activeDivision, d.id);
        expect(catOf(app.activeCat)?.division, d.id);
      }
    });
  });

  _listingRegressionGuards();
  _placeLabelGuards();

  group('search', () {
    test('a place term moves the location instead of filtering by name', () {
      final app = AppState();
      app.setQuery('Jaipur');
      expect(app.location, 'Jaipur');
      // The term was consumed as a location, so it must not also sit in the
      // text filter and silently zero the grid.
      expect(app.query, isEmpty);
    });

    test('an area term resolves to its city', () {
      final app = AppState();
      app.setQuery('Bandra');
      expect(app.location, 'Mumbai');
    });

    test('a non-place term stays as a text filter', () {
      final app = AppState();
      app.setQuery('Priya Sharma');
      expect(app.query, 'Priya Sharma');
      expect(app.location, 'Mumbai');
    });

    test('clearQuery empties the filter', () {
      final app = AppState();
      app.setQuery('Priya Sharma');
      app.clearQuery();
      expect(app.query, isEmpty);
    });
  });

  group('location', () {
    test('reports the state for a city', () {
      final app = AppState();
      app.setLocation('Hyderabad');
      expect(app.location, 'Hyderabad');
      expect(app.locationState, 'Telangana');
    });

    test('a state has no parent state of its own', () {
      final app = AppState();
      app.setLocation('Kerala');
      expect(app.locationState, isEmpty);
    });
  });

  group('update feed', () {
    test('starts empty when the desk has published nothing', () {
      final app = AppState();
      app.setLocation(kAllIndia);
      expect(app.updateFeed, isEmpty);
      expect(app.platformEvents, isEmpty);
      expect(app.sessions, isEmpty);
      expect(app.ads, isEmpty);
      expect(app.team, isEmpty);
      expect(app.academicPartners, isEmpty);
      expect(app.brandPartners, isEmpty);
    });

    test('is sorted by date when entries exist', () {
      final app = AppState();
      app.setLocation(kAllIndia);
      final dates = app.updateFeed.map((u) => u.date).toList();
      final sorted = [...dates]..sort();
      expect(dates, sorted);
    });
  });

  group('digest verticals', () {
    test('starts with no published issues', () {
      final app = AppState();
      expect(app.newsletters, isEmpty);
      expect(app.populatedVerticals, isEmpty);
      expect(app.featuredIssue, isNull);
    });

    test('filtering an empty digest stays empty', () {
      final app = AppState();
      app.setNewsVertical('fashion');
      expect(app.happeningIssues, isEmpty);
      expect(app.trendIssues, isEmpty);
    });
  });
}

/// Guards for regressions introduced while adding the state-aware location
/// filter. Both were caught by auditing rather than by a failing screen.
void _listingRegressionGuards() {
  group('listing scope — regression guards', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    test('a state selection still resolves and is marked for local narrowing', () {
      final app = AppState();
      app.setLocation('Maharashtra');
      expect(app.location, 'Maharashtra');
      expect(GeoIndex.cityParamFor(app.location), isNull);
      expect(GeoIndex.needsClientNarrowing(app.location), isTrue);
    });

    test('a city selection delegates filtering to the backend', () {
      final app = AppState();
      app.setLocation('Mumbai');
      expect(GeoIndex.cityParamFor(app.location), 'Mumbai');
      expect(GeoIndex.needsClientNarrowing(app.location), isFalse);
    });

    test('All India neither filters nor sends a city', () {
      final app = AppState();
      app.setLocation(kAllIndia);
      expect(GeoIndex.cityParamFor(app.location), isNull);
      expect(GeoIndex.needsClientNarrowing(app.location), isFalse);
    });
  });
}

/// The marketplace's own copy of the place-label rule, guarded the same way
/// as the admin console's.
void _placeLabelGuards() {
  group('Session.placeLabel — regression guard', () {
    Session at({String city = '', String state = ''}) =>
        Session(id: '1', mode: 'workshop', title: 't', host: 'h', division: 'talent',
            city: city, state: state, date: '2026-01-01');

    test('joins a city and its state', () {
      expect(at(city: 'Mumbai', state: 'Maharashtra').placeLabel, 'Mumbai · Maharashtra');
    });

    test('does not repeat a place that is its own state', () {
      expect(at(city: 'Delhi NCR', state: 'Delhi NCR').placeLabel, 'Delhi NCR');
    });

    test('an online session shows only Online', () {
      expect(at(city: 'Online', state: 'Maharashtra').placeLabel, 'Online');
    });

    test('empty seed lists stay empty (no invented sessions)', () {
      expect(seedSessions, isEmpty);
      expect(seedAds, isEmpty);
      expect(seedTeam, isEmpty);
      expect(seedAcademicPartners, isEmpty);
      expect(seedBrandPartners, isEmpty);
    });
  });
}
