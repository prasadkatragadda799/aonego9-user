/// Helpers to merge backend vendor + profile-details JSON into the shape
/// [ProfileScreen] and [ListingCard] expect.
class VendorProfileUtils {
  static String displayValue(dynamic value, {String suffix = ''}) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return '';
    return '$text$suffix';
  }

  static bool hasText(dynamic value) => displayValue(value).isNotEmpty;

  /// Merge profile-details without wiping listing data with empty defaults.
  static Map<String, dynamic> mergeDetails(
    Map<String, dynamic> base,
    Map<String, dynamic> details,
  ) {
    final merged = Map<String, dynamic>.from(base);

    void setIfMeaningful(String key, dynamic value) {
      if (value == null) return;
      if (value is String) {
        if (value.trim().isEmpty) return;
        merged[key] = value.trim();
        return;
      }
      if (value is List) {
        if (value.isEmpty && _preserveWhenEmpty(key)) return;
        merged[key] = value;
        return;
      }
      merged[key] = value;
    }

    for (final entry in details.entries) {
      setIfMeaningful(entry.key, entry.value);
    }

    if (!hasText(merged['overview'])) {
      merged['overview'] = merged['tagline'] ?? '';
    }

    final detailStats = details['stats'];
    if (detailStats is List && detailStats.isNotEmpty) {
      merged['stats'] = detailStats;
    } else if ((merged['stats'] as List?)?.isEmpty ?? true) {
      merged['stats'] = buildDefaultStats(merged);
    }

    final detailTags = details['tags'];
    if (detailTags is List && detailTags.isNotEmpty) {
      merged['tags'] = detailTags;
    }

    return merged;
  }

  static bool _preserveWhenEmpty(String key) =>
      key == 'stats' || key == 'tags' || key == 'services' || key == 'amenities';

  static List<Map<String, String>> buildDefaultStats(Map<String, dynamic> p) {
    final cat = p['cat'] as String? ?? '';
    final rating = (p['rating'] as num?)?.toDouble() ?? 0.0;
    final reviews = '${p['reviewCount'] ?? 0}';
    final bookings = '${(p['_raw'] as Map?)?['total_bookings'] ?? p['reviewCount'] ?? 0}';

    if (cat == 'venue') {
      final spaces = (p['spaces'] as List?)?.length ?? 0;
      final amenities = (p['amenities'] as List?)?.length ?? 0;
      return [
        if (spaces > 0) {'n': '$spaces', 'l': 'Event Spaces'},
        if (amenities > 0) {'n': '$amenities', 'l': 'Amenities'},
        {'n': rating.toStringAsFixed(1), 'l': 'Rating'},
        {'n': reviews, 'l': 'Reviews'},
      ];
    }
    if (cat == 'events') {
      final services = (p['services'] as List?)?.length ?? 0;
      return [
        if (services > 0) {'n': '$services', 'l': 'Services'},
        if (hasText(p['exp'])) {'n': displayValue(p['exp']), 'l': 'Experience'},
        {'n': rating.toStringAsFixed(1), 'l': 'Rating'},
        {'n': bookings, 'l': 'Bookings'},
      ];
    }
    if (cat == 'photo' || cat == 'video') {
      final equip = (p['equipment'] as List?)?.length ?? 0;
      final reels = (p['reels'] as List?)?.length ?? 0;
      return [
        if (equip > 0) {'n': '$equip', 'l': 'Equipment'},
        if (reels > 0) {'n': '$reels', 'l': 'Showreels'},
        {'n': rating.toStringAsFixed(1), 'l': 'Rating'},
        {'n': reviews, 'l': 'Reviews'},
      ];
    }
    if (cat == 'modelF' || cat == 'modelM') {
      return [
        if (hasText(p['exp'])) {'n': displayValue(p['exp']), 'l': 'Experience'},
        if (hasText(p['height'])) {'n': displayValue(p['height']), 'l': 'Height'},
        {'n': rating.toStringAsFixed(1), 'l': 'Rating'},
        {'n': reviews, 'l': 'Reviews'},
      ];
    }

    final city = displayValue(p['loc']);
    return [
      {'n': bookings, 'l': 'Bookings'},
      {'n': rating.toStringAsFixed(1), 'l': 'Rating'},
      if (city.isNotEmpty) {'n': city, 'l': 'City'},
      {'n': displayValue(p['badge'], suffix: ''), 'l': 'Plan'},
    ].where((s) => s['n']!.isNotEmpty).toList();
  }

  static String categoryEmoji(String cat) => switch (cat) {
        'photo' => '📷',
        'video' => '🎥',
        'venue' => '🏛️',
        'events' => '🎪',
        'modelM' => '🧑',
        _ => '💃',
      };
}
