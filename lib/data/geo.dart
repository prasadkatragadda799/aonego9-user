/// ─────────────────────────────────────────────────────────────────
/// GEOGRAPHY — state → city → area, so the marketplace can be filtered the
/// way the brief asks for it ("area, cities, town, state").
///
/// The app previously shipped four hardcoded strings ('Mumbai', 'Delhi NCR',
/// 'Bangalore', 'All India') with no notion of a state, which made "search by
/// city and state" impossible to express. This is the real hierarchy.
///
/// Coverage is the working set of Indian film/fashion/event markets rather
/// than an exhaustive gazetteer — a full postal dataset belongs in the
/// backend, and [GeoIndex.resolve] already accepts any city string the API
/// returns, listed here or not.
library;

class GeoCity {
  final String name;
  final String state;

  /// Neighbourhoods/towns inside the city that talent and crews actually
  /// quote travel against.
  final List<String> areas;
  const GeoCity(this.name, this.state, {this.areas = const []});
}

class GeoState {
  final String name;
  final String short;
  final List<GeoCity> cities;
  const GeoState(this.name, this.short, this.cities);
}

/// Sentinel used wherever "don't filter by place" is meant. Kept as the same
/// literal the app already persisted so saved links (?loc=All India) survive.
const String kAllIndia = 'All India';

const List<GeoState> geoStates = [
  GeoState('Maharashtra', 'MH', [
    GeoCity('Mumbai', 'Maharashtra', areas: [
      'Bandra', 'Andheri', 'Juhu', 'Lower Parel', 'Versova', 'Malad', 'Powai', 'Colaba', 'Goregaon',
    ]),
    GeoCity('Pune', 'Maharashtra', areas: ['Koregaon Park', 'Baner', 'Kalyani Nagar', 'Viman Nagar']),
    GeoCity('Nagpur', 'Maharashtra', areas: ['Dharampeth', 'Civil Lines']),
    GeoCity('Nashik', 'Maharashtra', areas: ['Gangapur Road', 'College Road']),
  ]),
  GeoState('Delhi NCR', 'DL', [
    GeoCity('Delhi NCR', 'Delhi NCR', areas: [
      'South Delhi', 'Hauz Khas', 'Saket', 'Connaught Place', 'Gurugram', 'Noida', 'Faridabad', 'Dwarka',
    ]),
  ]),
  GeoState('Karnataka', 'KA', [
    GeoCity('Bangalore', 'Karnataka', areas: [
      'Indiranagar', 'Koramangala', 'Whitefield', 'Jayanagar', 'HSR Layout', 'MG Road',
    ]),
    GeoCity('Mysore', 'Karnataka', areas: ['Gokulam', 'Vijayanagar']),
    GeoCity('Mangalore', 'Karnataka', areas: ['Hampankatta', 'Kadri']),
  ]),
  GeoState('Telangana', 'TS', [
    GeoCity('Hyderabad', 'Telangana', areas: [
      'Banjara Hills', 'Jubilee Hills', 'Gachibowli', 'Madhapur', 'Film Nagar', 'Secunderabad',
    ]),
  ]),
  GeoState('Tamil Nadu', 'TN', [
    GeoCity('Chennai', 'Tamil Nadu', areas: ['T. Nagar', 'Adyar', 'Nungambakkam', 'ECR', 'Anna Nagar']),
    GeoCity('Coimbatore', 'Tamil Nadu', areas: ['RS Puram', 'Peelamedu']),
    GeoCity('Madurai', 'Tamil Nadu', areas: ['Anna Nagar', 'KK Nagar']),
  ]),
  GeoState('West Bengal', 'WB', [
    GeoCity('Kolkata', 'West Bengal', areas: ['Park Street', 'Salt Lake', 'Ballygunge', 'New Town']),
  ]),
  GeoState('Rajasthan', 'RJ', [
    GeoCity('Jaipur', 'Rajasthan', areas: ['C-Scheme', 'Amer', 'Malviya Nagar']),
    GeoCity('Udaipur', 'Rajasthan', areas: ['Lake Pichola', 'Fatehsagar']),
    GeoCity('Jodhpur', 'Rajasthan', areas: ['Old City', 'Ratanada']),
  ]),
  GeoState('Gujarat', 'GJ', [
    GeoCity('Ahmedabad', 'Gujarat', areas: ['SG Highway', 'Navrangpura', 'Bopal']),
    GeoCity('Surat', 'Gujarat', areas: ['Vesu', 'Adajan']),
  ]),
  GeoState('Kerala', 'KL', [
    GeoCity('Kochi', 'Kerala', areas: ['Fort Kochi', 'Kakkanad', 'Marine Drive']),
    GeoCity('Thiruvananthapuram', 'Kerala', areas: ['Kowdiar', 'Technopark']),
  ]),
  GeoState('Goa', 'GA', [
    GeoCity('Goa', 'Goa', areas: ['North Goa', 'South Goa', 'Panaji', 'Anjuna']),
  ]),
  GeoState('Uttar Pradesh', 'UP', [
    GeoCity('Lucknow', 'Uttar Pradesh', areas: ['Hazratganj', 'Gomti Nagar']),
    GeoCity('Varanasi', 'Uttar Pradesh', areas: ['Assi Ghat', 'Cantt']),
  ]),
  GeoState('Punjab', 'PB', [
    GeoCity('Chandigarh', 'Punjab', areas: ['Sector 17', 'Sector 35', 'Mohali']),
    GeoCity('Amritsar', 'Punjab', areas: ['Ranjit Avenue']),
  ]),
  GeoState('Madhya Pradesh', 'MP', [
    GeoCity('Indore', 'Madhya Pradesh', areas: ['Vijay Nagar', 'Palasia']),
    GeoCity('Bhopal', 'Madhya Pradesh', areas: ['Arera Colony', 'MP Nagar']),
  ]),
];

/// Flat, memoised views over [geoStates]. Rebuilding these per-frame in the
/// location picker showed up as jank on the browse rail, so they are computed
/// once here.
class GeoIndex {
  GeoIndex._();

  static final List<GeoCity> allCities =
      geoStates.expand((s) => s.cities).toList(growable: false);

  static final List<String> cityNames =
      allCities.map((c) => c.name).toList(growable: false);

  static final List<String> stateNames =
      geoStates.map((s) => s.name).toList(growable: false);

  static final Map<String, GeoCity> _byCity = {
    for (final c in allCities) c.name.toLowerCase(): c,
  };

  /// City → its state, or '' for [kAllIndia] and anything unrecognised.
  static String stateOfCity(String city) => _byCity[city.toLowerCase()]?.state ?? '';

  static List<String> areasOf(String city) => _byCity[city.toLowerCase()]?.areas ?? const [];

  static List<String> citiesOfState(String state) => geoStates
      .firstWhere(
        (s) => s.name.toLowerCase() == state.toLowerCase(),
        orElse: () => const GeoState('', '', []),
      )
      .cities
      .map((c) => c.name)
      .toList();

  static final Set<String> _cityKeys = {for (final c in allCities) c.name.toLowerCase()};
  static final Set<String> _stateKeys = {for (final s in geoStates) s.name.toLowerCase()};

  static bool isCity(String place) => _cityKeys.contains(place.trim().toLowerCase());
  static bool isState(String place) => _stateKeys.contains(place.trim().toLowerCase());

  /// What to send as the backend's `city` query parameter for [place], or
  /// null to fetch broadly.
  ///
  /// A STATE is not a city: sending "Maharashtra" as `city` matches nothing
  /// server-side, so a state selection fetches broadly and is narrowed by
  /// [needsClientNarrowing] instead. Some names — "Delhi NCR", "Goa" — are
  /// both, and the city reading wins because it lets the backend do the work.
  static String? cityParamFor(String place) {
    if (place.isEmpty || place == kAllIndia) return null;
    if (isCity(place)) return place;
    if (isState(place)) return null;
    // An unrecognised place is still passed through — the backend may well
    // know a city this app's working-set geo data does not.
    return place;
  }

  /// True only when the backend could not have applied the filter itself.
  ///
  /// Deliberately narrow: re-filtering a city the backend already filtered
  /// would hide any listing whose city string this app's dataset happens not
  /// to list, which is a real risk because [geoStates] is a working set, not
  /// a gazetteer.
  static bool needsClientNarrowing(String place) =>
      place.isNotEmpty && place != kAllIndia && !isCity(place) && isState(place);

  /// True when a listing in [listingCity] should be visible to someone
  /// browsing [selected].
  ///
  /// [selected] may be [kAllIndia] (everything), a state name (any city in
  /// that state), or a city name. Pan-India vendors — the ones who set their
  /// city to "All India" or left it blank — always match, which is the rule
  /// the app already applied for cities and which the brief keeps.
  static bool matches({required String selected, required String listingCity}) {
    if (selected.isEmpty || selected == kAllIndia) return true;
    final listing = listingCity.trim();
    if (listing.isEmpty || listing.toLowerCase() == kAllIndia.toLowerCase()) return true;
    if (listing.toLowerCase() == selected.toLowerCase()) return true;

    // Selected a state → match every city inside it.
    if (stateNames.any((s) => s.toLowerCase() == selected.toLowerCase())) {
      return stateOfCity(listing).toLowerCase() == selected.toLowerCase();
    }

    // Selected a city → also match listings that only recorded an area of it.
    final areas = areasOf(selected);
    return areas.any((a) => a.toLowerCase() == listing.toLowerCase());
  }

  /// Best-effort place resolution for free-text search: "bandra" → Mumbai,
  /// "kerala" → Kerala, "hyd" → Hyderabad. Returns null when the query isn't
  /// a place at all, so the caller can fall through to a name/tag search.
  static String? resolve(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return null;
    if (q == 'india' || q == 'all india' || q == 'all') return kAllIndia;

    for (final s in stateNames) {
      if (s.toLowerCase() == q) return s;
    }
    for (final c in cityNames) {
      if (c.toLowerCase() == q) return c;
    }
    // Prefix match before substring, so "mad" prefers Madurai over Ahmedabad.
    for (final c in cityNames) {
      if (c.toLowerCase().startsWith(q)) return c;
    }
    for (final s in stateNames) {
      if (s.toLowerCase().startsWith(q)) return s;
    }
    for (final c in allCities) {
      if (c.areas.any((a) => a.toLowerCase() == q)) return c.name;
    }
    return null;
  }

  /// Type-ahead suggestions across states, cities and areas.
  static List<GeoSuggestion> suggest(String query, {int limit = 8}) {
    final q = query.trim().toLowerCase();
    final out = <GeoSuggestion>[];
    if (q.isEmpty) {
      for (final c in allCities.take(limit)) {
        out.add(GeoSuggestion(c.name, c.state, GeoKind.city));
      }
      return out;
    }
    for (final s in geoStates) {
      if (s.name.toLowerCase().contains(q)) {
        out.add(GeoSuggestion(s.name, '${s.cities.length} cities', GeoKind.state));
      }
    }
    for (final c in allCities) {
      if (c.name.toLowerCase().contains(q)) {
        out.add(GeoSuggestion(c.name, c.state, GeoKind.city));
      }
    }
    for (final c in allCities) {
      for (final a in c.areas) {
        if (a.toLowerCase().contains(q)) {
          out.add(GeoSuggestion(a, '${c.name} · ${c.state}', GeoKind.area, city: c.name));
        }
      }
    }
    return out.take(limit).toList();
  }
}

enum GeoKind { state, city, area }

class GeoSuggestion {
  final String label;
  final String hint;
  final GeoKind kind;

  /// For an area, the city it resolves to when picked.
  final String? city;
  const GeoSuggestion(this.label, this.hint, this.kind, {this.city});

  /// What [AppState.location] should become when this suggestion is chosen.
  String get value => kind == GeoKind.area ? (city ?? label) : label;

  String get icon => switch (kind) {
        GeoKind.state => '🗺️',
        GeoKind.city => '📍',
        GeoKind.area => '🏙️',
      };
}
