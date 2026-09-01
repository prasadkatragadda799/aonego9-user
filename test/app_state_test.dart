import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aonego9_user/data/directory.dart';
import 'package:aonego9_user/data/geo.dart';
import 'package:aonego9_user/data/taxonomy.dart';
import 'package:aonego9_user/state/app_state.dart';

/// AppState's constructor kicks off network fetches. They fail in a test
/// environment and are all caught internally, leaving the seed content in
/// place — which is exactly the state these tests want to assert against.
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
    test('carries workshops, webinars and events together', () {
      final app = AppState();
      app.setLocation(kAllIndia);
      final kinds = app.updateFeed.map((u) => u.kind).toSet();
      expect(kinds, containsAll(<String>['workshop', 'webinar', 'event']));
    });

    test('is sorted by date', () {
      final app = AppState();
      app.setLocation(kAllIndia);
      final dates = app.updateFeed.map((u) => u.date).toList();
      final sorted = [...dates]..sort();
      expect(dates, sorted);
    });

    test('online sessions show regardless of the browsing city', () {
      final app = AppState();
      app.setLocation('Kochi');
      final webinars = app.updateFeed.where((u) => u.kind == 'webinar');
      expect(webinars, isNotEmpty);
    });

    test('scopes physical entries to the selected place', () {
      final app = AppState();
      app.setLocation('Mumbai');
      for (final u in app.updateFeed) {
        if (u.city.isEmpty || u.city.toLowerCase() == 'online') continue;
        expect(
          GeoIndex.matches(selected: 'Mumbai', listingCity: u.city),
          isTrue,
          reason: '${u.title} in ${u.city} leaked into a Mumbai feed',
        );
      }
    });

    test('a state selection widens the feed versus one city', () {
      final app = AppState();
      app.setLocation('Mumbai');
      final city = app.updateFeed.length;
      app.setLocation(kAllIndia);
      expect(app.updateFeed.length, greaterThanOrEqualTo(city));
    });

    test('place renders city and state without repeating itself', () {
      final app = AppState();
      app.setLocation(kAllIndia);
      for (final u in app.updateFeed) {
        expect(u.place.contains(' · ') && u.place.split(' · ')[0] == u.place.split(' · ')[1], isFalse,
            reason: 'duplicated place string: ${u.place}');
      }
    });
  });

  group('digest verticals', () {
    test('seed issues are tagged with a real vertical', () {
      final app = AppState();
      expect(app.populatedVerticals, isNot(contains('')));
      expect(app.populatedVerticals.length, greaterThan(1));
    });

    test('filtering narrows the digest', () {
      final app = AppState();
      final all = app.happeningIssues.length + app.trendIssues.length;
      app.setNewsVertical('fashion');
      final narrowed = app.happeningIssues.length + app.trendIssues.length;
      expect(narrowed, lessThan(all));
      expect(narrowed, greaterThan(0));
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

    test('no seeded session renders a duplicated place', () {
      for (final s in seedSessions) {
        expect(s.placeLabel.split(' · ').toSet().length, s.placeLabel.split(' · ').length,
            reason: 'duplicated place on "${s.title}": ${s.placeLabel}');
      }
    });
  });
}
