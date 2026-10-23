import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aonego9_user/state/app_state.dart';

/// Sorting, the verified-only switch and the shortlist on the results page.
void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Map<String, dynamic> v(String id, {double rating = 0, int bookings = 0, bool verified = false}) => {
        'id': id,
        'cat': 'modelF',
        'name': 'Profile $id',
        'loc': 'Mumbai',
        'rating': rating,
        'reviewCount': bookings,
        'verified': verified,
        'isNew': bookings == 0,
      };

  final floor = [
    v('a', rating: 4.2, bookings: 30),
    v('b', rating: 4.9, bookings: 4, verified: true),
    v('c'),
    v('d', rating: 4.9, bookings: 50, verified: true),
    v('e'),
  ];

  List<String> ids(AppState app) => [for (final i in app.catItems) '${i['id']}'];

  group('sort', () {
    test('recommended keeps the backend order', () {
      final app = AppState()..debugSetListings(floor);
      expect(ids(app), ['a', 'b', 'c', 'd', 'e']);
    });

    test('top rated orders by score and keeps ties in backend order', () {
      final app = AppState()..debugSetListings(floor);
      app.setSort('rating');
      expect(ids(app), ['b', 'd', 'a', 'c', 'e']);
    });

    test('most booked orders by bookings', () {
      final app = AppState()..debugSetListings(floor);
      app.setSort('bookings');
      expect(ids(app), ['d', 'a', 'b', 'c', 'e']);
    });

    test('new faces come first', () {
      final app = AppState()..debugSetListings(floor);
      app.setSort('new');
      expect(ids(app), ['c', 'e', 'a', 'b', 'd']);
    });

    test('an unknown sort key is ignored', () {
      final app = AppState()..debugSetListings(floor);
      app.setSort('price');
      expect(app.sortBy, 'recommended');
    });
  });

  test('verified-only hides unverified profiles and reports why the grid is empty', () {
    final app = AppState()..debugSetListings([v('x'), v('y')]);
    app.toggleVerifiedOnly();
    expect(app.catItems, isEmpty);
    expect(app.filteredToNothing, isTrue);
    app.toggleVerifiedOnly();
    expect(app.catItems.length, 2);
  });

  group('shortlist', () {
    test('hearting toggles a profile in and out', () {
      final app = AppState();
      app.toggleShortlist(floor[0]);
      expect(app.isShortlisted('a'), isTrue);
      expect(app.shortlist.length, 1);
      app.toggleShortlist(floor[0]);
      expect(app.isShortlisted('a'), isFalse);
    });

    test('a profile with no id cannot be saved', () {
      final app = AppState();
      app.toggleShortlist({'name': 'No id'});
      expect(app.shortlist, isEmpty);
    });

    test('survives a reload', () async {
      final first = AppState();
      first.toggleShortlist(floor[1]);
      first.toggleShortlist(floor[3]);
      await Future<void>.delayed(Duration.zero);

      final second = AppState();
      await Future<void>.delayed(Duration.zero);
      expect([for (final s in second.shortlist) s['id']], ['b', 'd']);
      expect(second.shortlist.first['name'], 'Profile b');
    });

    test('clear empties it', () {
      final app = AppState();
      app.toggleShortlist(floor[0]);
      app.toggleShortlist(floor[1]);
      app.clearShortlist();
      expect(app.shortlist, isEmpty);
    });
  });

  group('profile search', () {
    final talent = [
      {'id': 's1', 'cat': 'modelF', 'name': 'Meher Kapoor', 'loc': 'Mumbai'},
      {'id': 's2', 'cat': 'modelF', 'name': 'Aanya Sharma', 'loc': 'Mumbai', 'tagline': 'Works with Meher often'},
      {'id': 's3', 'cat': 'modelM', 'name': 'Kabir Mehra', 'loc': 'Mumbai'},
      {'id': 's4', 'cat': 'photo', 'name': 'Meher Studios', 'loc': 'Mumbai'},
    ];

    test('finds by name across the hub, names that start with the term first', () async {
      final app = AppState()..debugSeedSearch('modelF', talent);
      final found = await app.searchProfiles('meh', ['modelF', 'modelM']);
      // s4 is a photographer — not in the artists' talent categories asked for.
      expect([for (final v in found!) v['id']], ['s1', 's2', 's3']);
    });

    test('one-letter queries do not search', () async {
      final app = AppState()..debugSeedSearch('modelF', talent);
      expect(await app.searchProfiles('m', ['modelF']), isEmpty);
    });
  });
}
