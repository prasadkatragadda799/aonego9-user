import 'package:flutter_test/flutter_test.dart';
import 'package:aonego9_user/data/geo.dart';

void main() {
  group('GeoIndex.matches', () {
    test('All India shows everything', () {
      expect(GeoIndex.matches(selected: kAllIndia, listingCity: 'Mumbai'), isTrue);
      expect(GeoIndex.matches(selected: kAllIndia, listingCity: 'Kochi'), isTrue);
    });

    test('a city matches only itself', () {
      expect(GeoIndex.matches(selected: 'Mumbai', listingCity: 'Mumbai'), isTrue);
      expect(GeoIndex.matches(selected: 'Mumbai', listingCity: 'Pune'), isFalse);
    });

    test('a STATE matches every city inside it', () {
      // This is the capability the old four-city picker could not express.
      expect(GeoIndex.matches(selected: 'Maharashtra', listingCity: 'Mumbai'), isTrue);
      expect(GeoIndex.matches(selected: 'Maharashtra', listingCity: 'Pune'), isTrue);
      expect(GeoIndex.matches(selected: 'Maharashtra', listingCity: 'Bangalore'), isFalse);
    });

    test('a city also matches listings recorded as one of its areas', () {
      expect(GeoIndex.matches(selected: 'Mumbai', listingCity: 'Bandra'), isTrue);
      expect(GeoIndex.matches(selected: 'Mumbai', listingCity: 'Koramangala'), isFalse);
    });

    test('pan-India and blank listings always show', () {
      expect(GeoIndex.matches(selected: 'Mumbai', listingCity: ''), isTrue);
      expect(GeoIndex.matches(selected: 'Mumbai', listingCity: 'All India'), isTrue);
    });

    test('matching is case-insensitive', () {
      expect(GeoIndex.matches(selected: 'Mumbai', listingCity: 'mumbai'), isTrue);
      expect(GeoIndex.matches(selected: 'maharashtra', listingCity: 'PUNE'), isTrue);
    });
  });

  group('GeoIndex.resolve', () {
    test('resolves cities, states and areas', () {
      expect(GeoIndex.resolve('Mumbai'), 'Mumbai');
      expect(GeoIndex.resolve('kerala'), 'Kerala');
      expect(GeoIndex.resolve('bandra'), 'Mumbai');
    });

    test('resolves a prefix', () {
      expect(GeoIndex.resolve('hyder'), 'Hyderabad');
    });

    test('returns null for a non-place so search can fall through to names', () {
      expect(GeoIndex.resolve('priya sharma'), isNull);
      expect(GeoIndex.resolve(''), isNull);
    });

    test('india means everywhere', () {
      expect(GeoIndex.resolve('india'), kAllIndia);
    });
  });

  _regressionGuards();

  group('GeoIndex lookups', () {
    test('stateOfCity', () {
      expect(GeoIndex.stateOfCity('Mumbai'), 'Maharashtra');
      expect(GeoIndex.stateOfCity('Kochi'), 'Kerala');
      expect(GeoIndex.stateOfCity(kAllIndia), '');
      expect(GeoIndex.stateOfCity('Nowhere'), '');
    });

    test('suggest surfaces states, cities and areas', () {
      final s = GeoIndex.suggest('ban');
      expect(s, isNotEmpty);
      expect(s.any((x) => x.label == 'Bangalore'), isTrue);
      expect(s.any((x) => x.label == 'Bandra'), isTrue);
      // An area suggestion resolves to its parent city when picked.
      expect(s.firstWhere((x) => x.label == 'Bandra').value, 'Mumbai');
    });

    test('city names are unique', () {
      final names = GeoIndex.cityNames;
      expect(names.toSet().length, names.length);
    });
  });
}

void _regressionGuards() {
  group('request shape — regression guards', () {
    test('a STATE is never sent as the backend city parameter', () {
      // Sending "Maharashtra" as `city` matches nothing server-side, which
      // would make the whole state feature return an empty grid.
      expect(GeoIndex.cityParamFor('Maharashtra'), isNull);
      expect(GeoIndex.cityParamFor('Kerala'), isNull);
      expect(GeoIndex.cityParamFor(kAllIndia), isNull);
    });

    test('a CITY is sent through so the backend does the filtering', () {
      expect(GeoIndex.cityParamFor('Mumbai'), 'Mumbai');
      expect(GeoIndex.cityParamFor('Hyderabad'), 'Hyderabad');
    });

    test('a name that is both city and state is treated as a city', () {
      // Delhi NCR and Goa are modelled as both; the city reading wins because
      // it lets the backend filter instead of us over-fetching.
      expect(GeoIndex.cityParamFor('Delhi NCR'), 'Delhi NCR');
      expect(GeoIndex.cityParamFor('Goa'), 'Goa');
      expect(GeoIndex.needsClientNarrowing('Delhi NCR'), isFalse);
    });

    test('an unrecognised place is still passed to the backend', () {
      // The dataset here is a working set, not a gazetteer — the backend may
      // know a city this app does not.
      expect(GeoIndex.cityParamFor('Ghaziabad'), 'Ghaziabad');
      expect(GeoIndex.needsClientNarrowing('Ghaziabad'), isFalse);
    });

    test('client-side narrowing happens ONLY for a pure state', () {
      expect(GeoIndex.needsClientNarrowing('Maharashtra'), isTrue);
      expect(GeoIndex.needsClientNarrowing('Mumbai'), isFalse);
      expect(GeoIndex.needsClientNarrowing(kAllIndia), isFalse);
      expect(GeoIndex.needsClientNarrowing(''), isFalse);
    });

    test('a city the dataset does not know is never filtered out', () {
      // Regression: browsing "Delhi NCR" once hid a vendor listed in
      // Ghaziabad, because the client re-filtered what the backend had
      // already filtered. narrowing must be off for any city selection.
      expect(GeoIndex.needsClientNarrowing('Delhi NCR'), isFalse);
      expect(GeoIndex.needsClientNarrowing('Mumbai'), isFalse);
    });
  });
}
