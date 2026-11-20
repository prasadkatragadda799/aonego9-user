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
    id: 'stars',
    name: 'Stars & Experts',
    icon: '🌟',
    blurb: 'Celebrities, directors, casting, influencers and industry experts.',
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
    id: 'business',
    name: 'Brands & Business',
    icon: '🏢',
    blurb: 'Brands, sponsors, malls, agencies and local service businesses.',
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
    blurb: 'Schools, colleges, universities, classes and coaches.',
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

  // ── Stars & Experts ─────────────────────────────────────────────
  Cat(
    id: 'celebrity',
    name: 'Celebrities',
    icon: '🌟',
    division: 'stars',
    searchTerm: 'celebrity',
    filters: ['All', 'Film & OTT', 'Television', 'Music', 'Sports', 'Fashion'],
    shootTypes: ['commercial', 'editorial', 'film', 'fashion'],
    h1: 'Book ',
    h2: 'Celebrities & Stars',
    sub: 'Appearances, endorsements and event hosting — managed through verified desks and agencies.',
  ),
  Cat(
    id: 'director',
    name: 'Directors',
    icon: '🎬',
    division: 'stars',
    searchTerm: 'director',
    filters: ['All', 'Film', 'Ad Films', 'Music Videos', 'Fashion Films', 'Documentary'],
    shootTypes: ['film', 'commercial', 'artistic', 'fashion'],
    h1: 'Visionary ',
    h2: 'Directors',
    sub: 'Feature, ad-film and music-video directors with showreels and past credits on the profile.',
  ),
  Cat(
    id: 'castingDirector',
    name: 'Casting Directors',
    icon: '🎭',
    division: 'stars',
    searchTerm: 'casting',
    filters: ['All', 'Film & OTT', 'Ad Films', 'Fashion', 'Theatre'],
    shootTypes: ['film', 'commercial', 'fashion'],
    h1: 'Trusted ',
    h2: 'Casting Directors',
    sub: 'Casting desks running open calls, auditions and brand castings across India.',
  ),
  Cat(
    id: 'influencer',
    name: 'Influencers',
    icon: '📱',
    division: 'stars',
    searchTerm: 'influencer',
    filters: ['All', 'Fashion', 'Beauty', 'Lifestyle', 'Food', 'Travel', 'Tech'],
    shootTypes: ['lifestyle', 'fashion', 'commercial', 'editorial'],
    h1: 'Reach-ready ',
    h2: 'Influencers & Creators',
    sub: 'Creators with audience size, niche and collaboration rates listed before you pitch.',
  ),
  Cat(
    id: 'expert',
    name: 'Industry Experts',
    icon: '🧠',
    division: 'stars',
    searchTerm: 'expert',
    filters: ['All', 'Grooming', 'Styling', 'Brand Strategy', 'Mentorship', 'Choreography'],
    shootTypes: ['editorial', 'commercial', 'artistic'],
    h1: 'Seasoned ',
    h2: 'Industry Experts',
    sub: 'Mentors, stylists, consultants and judges — the people who shape careers and shows.',
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

  Cat(
    id: 'productionHouse',
    name: 'Production Houses',
    icon: '🎥',
    division: 'crew',
    searchTerm: 'production',
    filters: ['All', 'Ad Films', 'Film & OTT', 'Music Videos', 'Corporate', 'Digital Content'],
    shootTypes: ['film', 'commercial', 'fashion', 'lifestyle'],
    h1: 'End-to-end ',
    h2: 'Production Houses',
    sub: 'Concept to final cut — houses with crews, kit and delivery timelines on the profile.',
  ),
  Cat(
    id: 'agency',
    name: 'Modelling Agencies',
    icon: '🗂️',
    division: 'crew',
    searchTerm: 'agency',
    filters: ['All', 'Fashion', 'Commercial', 'Kids', 'Plus Size', 'Celebrity Management'],
    shootTypes: ['fashion', 'commercial', 'ramp', 'editorial'],
    h1: 'Verified ',
    h2: 'Modelling Agencies',
    sub: 'Agencies with boards, rosters and booking terms — request a package in one brief.',
  ),
  Cat(
    id: 'organiser',
    name: 'Show Organisers',
    icon: '🎤',
    division: 'crew',
    searchTerm: 'organiser',
    filters: ['All', 'Fashion Shows', 'Music', 'Dance', 'Talent Hunts', 'Pageants'],
    shootTypes: ['ramp', 'commercial', 'lifestyle'],
    h1: 'On-stage ',
    h2: 'Fashion, Music & Talent Shows',
    sub: 'Organisers of fashion weeks, concerts, dance battles and talent hunts — with tickets and registrations.',
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

  // ── Brands & Business ───────────────────────────────────────────
  Cat(
    id: 'brand',
    name: 'Brands & Sponsors',
    icon: '🏷️',
    division: 'business',
    searchTerm: 'brand',
    filters: ['All', 'Fashion', 'Beauty', 'Lifestyle', 'Food & Beverage', 'Tech', 'Sponsorship'],
    shootTypes: ['commercial', 'editorial', 'fashion', 'lifestyle'],
    h1: 'Leading ',
    h2: 'Brands & Sponsors',
    sub: 'Brands promoting their offerings and sponsoring shows, campaigns and talent — listed by city, state and country.',
  ),
  Cat(
    id: 'mall',
    name: 'Malls & Retail',
    icon: '🛍️',
    division: 'business',
    searchTerm: 'mall',
    filters: ['All', 'Malls', 'Department Stores', 'High Street', 'Pop-ups'],
    shootTypes: ['commercial', 'lifestyle', 'fashion'],
    h1: 'Busy ',
    h2: 'Malls & Retail Floors',
    sub: 'Malls and retail floors for activations, mall shows, fashion walks and promotional displays.',
  ),
  Cat(
    id: 'adAgency',
    name: 'Agencies',
    icon: '📣',
    division: 'business',
    searchTerm: 'marketing',
    filters: ['All', 'Advertising', 'Digital Marketing', 'PR', 'Social Media', 'Events & Activation'],
    shootTypes: ['commercial', 'lifestyle', 'editorial'],
    h1: 'Creative ',
    h2: 'Advertising & Marketing Agencies',
    sub: 'Ad, PR and social media agencies — online and offline campaigns, branding and promotion.',
  ),
  Cat(
    id: 'localVendor',
    name: 'Local Vendors',
    icon: '🧰',
    division: 'business',
    searchTerm: 'service',
    filters: ['All', 'Catering', 'Decor', 'Sound & Light', 'Printing', 'Transport', 'Florists'],
    shootTypes: ['commercial', 'bridal', 'lifestyle'],
    h1: 'Reliable ',
    h2: 'Local Vendors & Services',
    sub: 'Goods and service businesses near you — caterers, decorators, printers, sound and transport.',
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
  Cat(
    id: 'college',
    name: 'Colleges & Universities',
    icon: '🏫',
    division: 'education',
    searchTerm: 'college',
    filters: ['All', 'Fashion', 'Film & Media', 'Performing Arts', 'Design', 'Management'],
    shootTypes: ['editorial', 'commercial', 'lifestyle'],
    h1: 'Recognised ',
    h2: 'Colleges & Universities',
    sub: 'Institutions with programmes, admissions, campus events and fests — all on one profile.',
  ),
  Cat(
    id: 'coach',
    name: 'Teachers & Choreographers',
    icon: '💃',
    division: 'education',
    searchTerm: 'teacher',
    filters: ['All', 'Dance', 'Acting', 'Music', 'Grooming', 'Fitness', 'Ramp Walk'],
    shootTypes: ['artistic', 'lifestyle', 'commercial'],
    h1: 'Professional ',
    h2: 'Teachers & Choreographers',
    sub: 'Classes, coaches and choreographers for shows, weddings, events and personal training.',
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
  // "mall" is a substring of "small", so it is only matched as a word.
  if (s == 'mall') return 'mall';

  // Most specific first — order is load-bearing.
  const ordered = <List<String>>[
    ['makeupStudio', 'makeup studio', 'beauty studio', 'salon', 'makeup academy'],
    ['makeupArtist', 'makeup', 'mua', 'hair stylist', 'hairstylist', 'beautician'],
    ['editVfx', 'vfx', 'compositing', 'roto'],
    ['edit3d', '3d', 'animation', 'animator', 'cgi'],
    ['editGraphic', 'graphic', 'illustrat', 'branding designer'],
    ['adAgency', 'advertising', 'ad agency', 'marketing', 'digital agency', 'media agency', 'pr agency', 'social media agency'],
    ['agency', 'modelling agency', 'modeling agency', 'model agency', 'talent agency', 'model management'],
    ['castingDirector', 'casting'],
    ['director', 'director', 'filmmaker', 'film maker'],
    ['influencer', 'influencer', 'content creator', 'creator', 'blogger', 'youtuber'],
    ['celebrity', 'celebrity', 'celeb', 'film star', 'superstar'],
    ['productionHouse', 'production house', 'production company', 'productions'],
    ['organiser', 'organiser', 'organizer', 'talent show', 'talent hunt', 'music show', 'dance show', 'pageant', 'fashion week'],
    ['coach', 'choreograph', 'teacher', 'trainer', 'coach', 'tutor', 'classes'],
    ['college', 'college', 'university'],
    ['expert', 'expert', 'consultant', 'mentor'],
    ['editVideo', 'video editor', 'editor', 'post production', 'post-production'],
    ['studio', 'photo studio', 'film studio', 'shooting floor'],
    ['jewellery', 'jewellery', 'jewelry', 'jeweller'],
    ['clothShop', 'showroom', 'cloth', 'fabric', 'boutique', 'garment'],
    ['designer', 'designer', 'couture', 'fashion house'],
    ['hotel', 'hotel', 'resort', 'stay', 'banquet'],
    ['academy', 'academy', 'school', 'institute', 'training'],
    ['mall', 'shopping mall', 'malls', ' mall', 'retail', 'department store'],
    ['brand', 'brand', 'sponsor'],
    ['localVendor', 'caterer', 'catering', 'decorator', 'decor', 'florist', 'printing', 'transport', 'local vendor', 'service provider', 'agency'],
    ['venue', 'venue', 'hall', 'lawn', 'palace'],
    ['events', 'event', 'wedding planner'],
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
