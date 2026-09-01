/// ─────────────────────────────────────────────
/// BROWSE DATA — derived from [taxonomy.dart].
///
/// These used to be six hand-maintained const maps. They are now projections
/// of the single catalogue, so adding a vertical means editing one list
/// instead of five, and the browse rail, footer, hero copy, filter chips and
/// inquiry form can never drift out of sync with each other.
///
/// The shapes (`List<Map<String, dynamic>>`, `Map<String, List<String>>`) are
/// kept exactly as they were so existing call sites need no changes.
///
/// The old file also carried three hardcoded model portfolios and their scene
/// matrices from the original prototype. Every one of those is now loaded from
/// the backend per profile, and nothing referenced them any more — they are
/// gone rather than left to rot as a second, silently-wrong source of truth.
library;

import 'taxonomy.dart';

/// Browse categories, in catalogue order.
final List<Map<String, dynamic>> cats = [
  for (final c in catalogue)
    {'id': c.id, 'name': c.name, 'icon': c.icon, 'division': c.division},
];

/// Filter chips per category.
final Map<String, List<String>> filters = {
  for (final c in catalogue) c.id: c.filters,
};

/// Hero copy per category.
final Map<String, Map<String, String>> heroCopy = {
  for (final c in catalogue) c.id: {'h1': c.h1, 'h2': c.h2, 'sub': c.sub},
};

/// Type definitions for portfolio items (label, color hex, icon).
/// Keyed by the shoot types referenced in [Cat.shootTypes].
const Map<String, Map<String, dynamic>> portTypes = {
  'ethnic': {'label': 'Traditional Ethnic', 'color': 0xFFC4A870, 'icon': '🥻'},
  'fashion': {'label': 'Western Fashion', 'color': 0xFFC898AA, 'icon': '👗'},
  'ramp': {'label': 'Ramp Walk', 'color': 0xFF8898B6, 'icon': '👠'},
  'commercial': {'label': 'Commercial Brand', 'color': 0xFF7C9EC8, 'icon': '📢'},
  'editorial': {'label': 'Magazine Editorial', 'color': 0xFFC4B098, 'icon': '📖'},
  'fitness': {'label': 'Fitness & Athletic', 'color': 0xFF7DB5A0, 'icon': '💪'},
  'lifestyle': {'label': 'Lifestyle', 'color': 0xFF7DB5A0, 'icon': '🌿'},
  'film': {'label': 'Film & Cinematic', 'color': 0xFFA080C4, 'icon': '🎬'},
  'bridal': {'label': 'Bridal & Wedding', 'color': 0xFFC898AA, 'icon': '💒'},
  'grooming': {'label': 'Grooming & Menswear', 'color': 0xFF8898B6, 'icon': '✂️'},
  'fragrance': {'label': 'Fragrance & Luxury', 'color': 0xFFC9A86C, 'icon': '✨'},
  'artistic': {'label': 'Artistic & Fine Art', 'color': 0xFFC4B098, 'icon': '🎨'},
};

/// Story-circle filters on a portfolio — "portfolio by types of shoot".
/// Derived from [portTypes] so a new shoot type shows up automatically;
/// short labels keep the chips from wrapping.
const Map<String, String> _shortTypeLabel = {
  'ethnic': 'Ethnic',
  'fashion': 'Fashion',
  'ramp': 'Ramp',
  'commercial': 'Brand',
  'editorial': 'Editorial',
  'fitness': 'Fitness',
  'lifestyle': 'Lifestyle',
  'film': 'Film',
  'bridal': 'Bridal',
  'grooming': 'Grooming',
  'fragrance': 'Fragrance',
  'artistic': 'Art',
};

final List<Map<String, String>> storyFilters = [
  {'id': 'all', 'icon': '⚡', 'label': 'All'},
  for (final e in portTypes.entries)
    {
      'id': e.key,
      'icon': e.value['icon'] as String,
      'label': _shortTypeLabel[e.key] ?? e.value['label'] as String,
    },
];

/// Inquiry types offered on the lead form, per category.
///
/// Every category in the catalogue has an entry — a missing one used to fall
/// back to the event-services list, which offered "Event Booking" to someone
/// enquiring with a makeup artist.
const Map<String, List<String>> inqTypes = {
  'modelF': ['Model Booking', 'Campaign Collaboration', 'Film / TVC Role', 'Test Shoot', 'Brand Tie-up'],
  'modelM': ['Model Booking', 'Campaign Collaboration', 'Film / TVC Role', 'Test Shoot', 'Brand Tie-up'],
  'photo': ['Photography Booking', 'Package Inquiry', 'Commercial Project', 'Test Shoot'],
  'video': ['Videography Booking', 'Brand Film Project', 'Package Inquiry', 'Social Content'],
  'studio': ['Studio Booking', 'Floor + Equipment', 'Half-day Hold', 'Recce Visit'],
  'events': ['Event Booking', 'Package Inquiry', 'Add-on Services', 'Custom Event Quote'],
  'editVideo': ['Edit Project', 'Social Cut-downs', 'Colour Grade', 'Retainer Inquiry'],
  'editVfx': ['VFX Shot Bid', 'Clean-up / Roto', 'CGI Integration', 'Retainer Inquiry'],
  'edit3d': ['3D Project', 'Product Render', 'Motion Graphics', 'Character Work'],
  'editGraphic': ['Design Project', 'Brand Identity', 'Campaign Artwork', 'Packaging'],
  'makeupArtist': ['Makeup Booking', 'Bridal Trial', 'Editorial Shoot', 'On-Location Team'],
  'makeupStudio': ['Studio Booking', 'Bridal Suite', 'Chair Rental', 'Team Booking'],
  'designer': ['Commission Inquiry', 'Collection Showcase', 'Bridal Order', 'Costume Rental'],
  'clothShop': ['Stock Inquiry', 'Bulk / Wholesale', 'Wardrobe Rental', 'Showroom Visit'],
  'jewellery': ['Catalogue Inquiry', 'Bridal Set', 'Shoot Rental', 'Custom Order'],
  'venue': ['Venue Booking', 'Site Visit Request', 'Package Query', 'Availability Check'],
  'hotel': ['Unit Stay Inquiry', 'Banquet Booking', 'Group Rate', 'Site Visit Request'],
  'academy': ['Course Inquiry', 'Admission / Intake', 'Workshop Booking', 'Campus Visit'],
};

const List<String> budgetRanges = [
  '₹10K – ₹50K', '₹50K – ₹1 Lakh', '₹1L – ₹5L', '₹5L – ₹20L', '₹20L+', 'Discuss on call',
];
