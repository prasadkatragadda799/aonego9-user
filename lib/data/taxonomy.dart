/// ─────────────────────────────────────────────────────────────────
/// TAXONOMY — the marketplace's two-level shape: DIVISION → CATEGORY.
///
/// The app shipped with six flat categories (venue, photo, video, modelF,
/// modelM, events). The brief adds ten more verticals — makeup artists and
/// studios, four kinds of post-production editor, fashion designers, cloth
/// showrooms, jewellery, hotels and academies. Sixteen flat tabs in one rail
/// is not a navigation system, so categories now sit inside a division and
/// the browse rail switches on divisions first.
///
/// Nothing here invents a category the brief didn't ask for, and every one of
/// the original six keeps its exact id, so existing deep links (?go=browse/photo),
/// saved accents (T.catAccent) and backend category strings all still resolve.
library;

/// A top-level grouping shown as the primary rail on Browse.
class Division {
  final String id;
  final String name;
  final String icon;
  final String blurb;
  const Division({
    required this.id,
    required this.name,
    required this.icon,
    required this.blurb,
  });
}

/// A bookable vertical. [searchTerm] is what actually gets sent to the
/// backend's free-text category match — vendors self-report a category
/// string at registration, so the id and the search term rarely line up 1:1.
class Cat {
  final String id;
  final String name;
  final String icon;
  final String division;
  final String searchTerm;

  /// Filter chips shown above the grid for this category.
  final List<String> filters;

  /// Shoot/work types this category's portfolios are organised by — this is
  /// the brief's "portfolio by types of shoot division".
  final List<String> shootTypes;

  /// Hero copy: [h1] is set in cream, [h2] in the category accent.
  final String h1;
  final String h2;
  final String sub;

  /// Talent categories get the comp card, scene matrix and measurements.
  final bool isTalent;

  const Cat({
    required this.id,
    required this.name,
    required this.icon,
    required this.division,
    required this.searchTerm,
    required this.filters,
    required this.shootTypes,
    required this.h1,
    required this.h2,
    required this.sub,
    this.isTalent = false,
  });
}

const List<Division> divisions = [
  Division(
    id: 'talent',
    name: 'Talent',
    icon: '✦',
    blurb: 'Models and on-screen talent with full comp cards.',
  ),
  Division(
    id: 'crew',
    name: 'Production',
    icon: '🎬',
    blurb: 'Photographers, film crews, studios and event teams.',
  ),
  Division(
    id: 'post',
    name: 'Post & Design',
    icon: '🖥️',
    blurb: 'VFX, edit, motion, 3D and graphic design.',
  ),
  Division(
    id: 'beauty',
    name: 'Hair & Makeup',
    icon: '💄',
    blurb: 'Makeup artists, hair stylists and beauty studios.',
  ),
  Division(
    id: 'fashion',
    name: 'Fashion & Retail',
    icon: '👗',
    blurb: 'Designers, showrooms, cloth houses and jewellery.',
  ),
  Division(
    id: 'spaces',
    name: 'Venues',
    icon: '🏛️',
    blurb: 'Event spaces, heritage properties and floors.',
  ),
  Division(
    id: 'hospitality',
    name: 'Hospitality',
    icon: '🏨',
    blurb: 'Hotels and stay partners for units on location.',
  ),
  Division(
    id: 'education',
    name: 'Academy',
    icon: '🎓',
    blurb: 'Schools, colleges and training institutions.',
  ),
];

const List<Cat> catalogue = [
  // ── Talent ──────────────────────────────────────────────────────
  Cat(
    id: 'modelF',
    name: 'Female Models',
    icon: '👗',
    division: 'talent',
    searchTerm: 'talent',
    filters: ['All', 'Fashion', 'Ethnic', 'Ramp', 'Film', 'Commercial', 'Fitness'],
    shootTypes: ['ethnic', 'fashion', 'ramp', 'commercial', 'editorial', 'fitness', 'lifestyle', 'film', 'bridal', 'artistic'],
    h1: 'Female ',
    h2: 'Models & Talent',
    sub: 'Instagram-style portfolio with labeled shoots, comp card, and professional scene availability — all before you reach out.',
    isTalent: true,
  ),
  Cat(
    id: 'modelM',
    name: 'Male Models',
    icon: '🧔',
    division: 'talent',
    searchTerm: 'talent',
    filters: ['All', 'Fashion', 'Ethnic', 'Ramp', 'Film', 'Commercial', 'Fitness'],
    shootTypes: ['ethnic', 'fashion', 'ramp', 'commercial', 'editorial', 'fitness', 'grooming', 'film', 'fragrance', 'artistic'],
    h1: 'Male ',
    h2: 'Models & Talent',
    sub: 'Full portfolio with labeled shoots, comp card, measurements, and professional film scene availability.',
    isTalent: true,
  ),

  // ── Production ──────────────────────────────────────────────────
  Cat(
    id: 'photo',
    name: 'Photography',
    icon: '📷',
    division: 'crew',
    searchTerm: 'photography',
    filters: ['All', 'Fashion', 'Wedding', 'Commercial', 'Portrait'],
    shootTypes: ['fashion', 'bridal', 'commercial', 'editorial', 'lifestyle', 'artistic'],
    h1: 'Professional ',
    h2: 'Photographers',
    sub: 'Full portfolio access, packages, and equipment specs. Browse and inquire in seconds.',
  ),
  Cat(
    id: 'video',
    name: 'Videography',
    icon: '🎬',
    division: 'crew',
    searchTerm: 'videography',
    filters: ['All', 'Brand Films', 'Wedding', 'Social Media', 'Documentary'],
    shootTypes: ['film', 'commercial', 'bridal', 'lifestyle', 'editorial'],
    h1: 'Cinematic ',
    h2: 'Videographers',
    sub: 'Brand films, weddings, social content. Watch reels, compare packages, post your brief.',
  ),
  Cat(
    id: 'studio',
    name: 'Photo Studios',
    icon: '🎞️',
    division: 'crew',
    searchTerm: 'studio',
    filters: ['All', 'Daylight', 'Cyclorama', 'Blackout', 'Equipment Rental'],
    shootTypes: ['fashion', 'commercial', 'editorial', 'artistic'],
    h1: 'Equipped ',
    h2: 'Photo & Film Studios',
    sub: 'Floors, cycloramas and lighting rooms with equipment lists published up front.',
  ),
  Cat(
    id: 'events',
    name: 'Event Services',
    icon: '🎪',
    division: 'crew',
    searchTerm: 'event',
    filters: ['All', 'Fashion Shows', 'Corporate', 'Wedding Events', 'Concerts'],
    shootTypes: ['commercial', 'bridal', 'lifestyle'],
    h1: 'Event ',
    h2: 'Production Services',
    sub: 'Full-service event management. Clear packages, inclusions, and add-ons — inquire in under 2 minutes.',
  ),

  // ── Post & Design ───────────────────────────────────────────────
  Cat(
    id: 'editVideo',
    name: 'Video Editors',
    icon: '✂️',
    division: 'post',
    searchTerm: 'editor',
    filters: ['All', 'Long Form', 'Social Cuts', 'Wedding Films', 'Colour Grade'],
    shootTypes: ['film', 'commercial', 'lifestyle'],
    h1: 'Precision ',
    h2: 'Video Editors',
    sub: 'Cut, grade and deliver. Watch reels and compare turnaround before you brief.',
  ),
  Cat(
    id: 'editVfx',
    name: 'VFX Artists',
    icon: '🪄',
    division: 'post',
    searchTerm: 'vfx',
    filters: ['All', 'Compositing', 'Clean-up', 'CGI Integration', 'Rotoscopy'],
    shootTypes: ['film', 'commercial', 'artistic'],
    h1: 'Invisible ',
    h2: 'VFX & Compositing',
    sub: 'Clean-up, comp and CGI integration for film, OTT and brand work.',
  ),
  Cat(
    id: 'edit3d',
    name: '3D & Animation',
    icon: '🧊',
    division: 'post',
    searchTerm: 'animation',
    filters: ['All', 'Product 3D', 'Character', 'Motion Graphics', 'Architectural'],
    shootTypes: ['commercial', 'artistic', 'film'],
    h1: 'Built ',
    h2: '3D & Animation',
    sub: 'Product renders, character work and motion built to a brand system.',
  ),
  Cat(
    id: 'editGraphic',
    name: 'Graphic Design',
    icon: '🎨',
    division: 'post',
    searchTerm: 'graphic',
    filters: ['All', 'Brand Identity', 'Campaign', 'Packaging', 'Social'],
    shootTypes: ['commercial', 'editorial', 'artistic'],
    h1: 'Considered ',
    h2: 'Graphic Design',
    sub: 'Identity, campaign and packaging systems with the full book on the profile.',
  ),

  // ── Hair & Makeup ───────────────────────────────────────────────
  Cat(
    id: 'makeupArtist',
    name: 'Makeup Artists',
    icon: '💄',
    division: 'beauty',
    searchTerm: 'makeup',
    filters: ['All', 'Bridal', 'Editorial', 'HD & Airbrush', 'SFX', 'Hair Styling'],
    shootTypes: ['bridal', 'editorial', 'fashion', 'commercial', 'artistic'],
    h1: 'Freelance ',
    h2: 'Makeup & Hair Artists',
    sub: 'Bridal, editorial and SFX books with kit lists, travel range and rates in the open.',
  ),
  Cat(
    id: 'makeupStudio',
    name: 'Makeup Studios',
    icon: '🪞',
    division: 'beauty',
    searchTerm: 'salon',
    filters: ['All', 'Bridal Suite', 'Academy', 'Chair Rental', 'On-Location'],
    shootTypes: ['bridal', 'editorial', 'fashion'],
    h1: 'Full-service ',
    h2: 'Makeup Studios',
    sub: 'Studios and salons with chairs, teams and bridal suites you can hold for a date.',
  ),

  // ── Fashion & Retail ────────────────────────────────────────────
  Cat(
    id: 'designer',
    name: 'Fashion Designers',
    icon: '✂️',
    division: 'fashion',
    searchTerm: 'designer',
    filters: ['All', 'Couture', 'Bridal', 'Ready-to-Wear', 'Menswear', 'Handloom'],
    shootTypes: ['ramp', 'bridal', 'ethnic', 'fashion', 'editorial'],
    h1: 'Signature ',
    h2: 'Fashion Designers',
    sub: 'Couture, bridal and ready-to-wear houses — see the collections before you commission.',
  ),
  Cat(
    id: 'clothShop',
    name: 'Cloth & Showrooms',
    icon: '🏬',
    division: 'fashion',
    searchTerm: 'showroom',
    filters: ['All', 'Bridal Wear', 'Menswear', 'Ethnic', 'Fabric House', 'Rental'],
    shootTypes: ['ethnic', 'bridal', 'fashion', 'commercial'],
    h1: 'Stocked ',
    h2: 'Cloth Houses & Showrooms',
    sub: 'Fabric houses, bridal floors and rental wardrobes with the full stock on the profile.',
  ),
  Cat(
    id: 'jewellery',
    name: 'Jewellery',
    icon: '💎',
    division: 'fashion',
    searchTerm: 'jewellery',
    filters: ['All', 'Bridal Sets', 'Polki & Kundan', 'Contemporary', 'Rental', 'Costume'],
    shootTypes: ['bridal', 'ethnic', 'editorial', 'commercial'],
    h1: 'Curated ',
    h2: 'Jewellery Houses',
    sub: 'Bridal sets, polki and shoot-rental pieces — catalogue and hold terms published.',
  ),

  // ── Venues ──────────────────────────────────────────────────────
  Cat(
    id: 'venue',
    name: 'Event Venues',
    icon: '🏛️',
    division: 'spaces',
    searchTerm: 'venue',
    filters: ['All', 'Indoor', 'Outdoor', 'Rooftop', 'Heritage'],
    shootTypes: ['bridal', 'commercial', 'lifestyle'],
    h1: 'Curated ',
    h2: 'Event Venues',
    sub: 'Handpicked spaces for every event. View capacity, pricing, and availability — post your inquiry directly.',
  ),

  // ── Hospitality ─────────────────────────────────────────────────
  Cat(
    id: 'hotel',
    name: 'Hotels',
    icon: '🏨',
    division: 'hospitality',
    searchTerm: 'hotel',
    filters: ['All', 'Unit Stay', 'Banquet', 'Resort', 'Heritage', 'Business'],
    shootTypes: ['bridal', 'lifestyle', 'commercial'],
    h1: 'Unit-ready ',
    h2: 'Hotels & Stays',
    sub: 'Rooms for travelling units, banquets for the reception, and rates held against a booking.',
  ),

  // ── Academy ─────────────────────────────────────────────────────
  Cat(
    id: 'academy',
    name: 'Schools & Academies',
    icon: '🎓',
    division: 'education',
    searchTerm: 'academy',
    filters: ['All', 'Modelling', 'Acting', 'Makeup', 'Film & Media', 'Design'],
    shootTypes: ['editorial', 'commercial', 'artistic'],
    h1: 'Accredited ',
    h2: 'Schools & Academies',
    sub: 'Colleges, universities and academies training the next intake — courses and intakes listed.',
  ),
];

/// Fast lookups. Built once at load rather than scanned per-frame, because
/// the browse rail and every listing card resolve a category on every build.
final Map<String, Cat> catById = {for (final c in catalogue) c.id: c};
final Map<String, Division> divisionById = {for (final d in divisions) d.id: d};

/// Categories belonging to a division, in declaration order.
final Map<String, List<Cat>> catsByDivision = {
  for (final d in divisions) d.id: catalogue.where((c) => c.division == d.id).toList(),
};

Cat? catOf(String? id) => id == null ? null : catById[id];

/// The division a category sits in — used to keep the rail in sync when a
/// deep link or a search result jumps straight to a category.
String divisionOf(String catId) => catById[catId]?.division ?? 'talent';

/// Free-text category string from the backend → our category id.
///
/// Vendors type their own category at registration, so this matches on
/// substrings and checks the most specific terms first: "makeup studio" must
/// not fall through to "makeup", and "video editor" must not become "video".
String catIdFromBackend(String raw) {
  final s = raw.toLowerCase().trim();
  if (s.isEmpty) return 'modelF';

  // Most specific first — order is load-bearing.
  const ordered = <List<String>>[
    ['makeupStudio', 'makeup studio', 'beauty studio', 'salon', 'makeup academy'],
    ['makeupArtist', 'makeup', 'mua', 'hair stylist', 'hairstylist', 'beautician'],
    ['editVfx', 'vfx', 'compositing', 'roto'],
    ['edit3d', '3d', 'animation', 'animator', 'cgi'],
    ['editGraphic', 'graphic', 'illustrat', 'branding designer'],
    ['editVideo', 'video editor', 'editor', 'post production', 'post-production'],
    ['studio', 'photo studio', 'film studio', 'shooting floor'],
    ['jewellery', 'jewellery', 'jewelry', 'jeweller'],
    ['clothShop', 'showroom', 'cloth', 'fabric', 'boutique', 'garment'],
    ['designer', 'designer', 'couture', 'fashion house'],
    ['hotel', 'hotel', 'resort', 'stay', 'banquet'],
    ['academy', 'academy', 'school', 'college', 'university', 'institute', 'training'],
    ['venue', 'venue', 'hall', 'lawn', 'palace'],
    ['events', 'event', 'wedding planner', 'production house'],
    ['photo', 'photograph'],
    ['video', 'videograph', 'cinematograph', 'film crew'],
    // Female terms are checked BEFORE male ones on purpose: the string
    // "female model" contains the substring "male model", so testing male
    // first files every female model as modelM. The generic 'model' /
    // 'talent' fallback has to come after both, or it would swallow
    // "male model" before the male row is ever reached.
    ['modelF', 'female model', 'female', 'actress', 'women model'],
    ['modelM', 'male model', 'men model', 'mens model', 'actor', 'male'],
    ['modelF', 'model', 'talent'],
  ];

  for (final row in ordered) {
    for (var i = 1; i < row.length; i++) {
      if (s.contains(row[i])) return row[0];
    }
  }
  return 'modelF';
}

/// Legacy slug used by GET /browse/categories → category id.
String catIdFromSlug(String slug) => switch (slug) {
      'venues' => 'venue',
      'photography' => 'photo',
      'videography' => 'video',
      'models' => 'modelF',
      'event-services' => 'events',
      _ => catById.containsKey(slug) ? slug : catIdFromBackend(slug),
    };
