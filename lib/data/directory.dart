/// ─────────────────────────────────────────────────────────────────
/// DIRECTORY — the non-marketplace content surfaces the brief asks for:
/// academic + brand partners, the team, workshops and webinars, the ad slots,
/// and the industry-news verticals.
///
/// Every list here is SEED content. The repository tries the backend first
/// and only falls back to these, which is the pattern the app already uses
/// for newsletters and events — the page is never a blank wall, and real
/// data overrides it the moment the desk publishes any.
library;

/// ── Partners ────────────────────────────────────────────────────
/// The brief splits partners into two display walls: "our academic partners"
/// and "our top brand partners", the latter grouped by brand division.
enum PartnerTier { academic, brand, institutional }

class LogoPartner {
  final String name;
  final String tagline;

  /// Real logo artwork when the desk has uploaded one. When empty the UI
  /// falls back to a typographic monogram — see [LogoMark].
  final String logoUrl;
  final PartnerTier tier;

  /// For brand partners: which brand division they sit in (Fashion, Beauty,
  /// Jewellery…). For academic partners: the stream they teach.
  final String division;
  final String city;
  final String website;
  final int bg;
  const LogoPartner({
    required this.name,
    required this.tagline,
    required this.tier,
    required this.division,
    this.logoUrl = '',
    this.city = '',
    this.website = '',
    this.bg = 0,
  });

  factory LogoPartner.fromJson(Map<String, dynamic> j) => LogoPartner(
        name: j['name'] as String? ?? '',
        tagline: j['tagline'] as String? ?? j['blurb'] as String? ?? '',
        tier: switch ((j['tier'] as String? ?? 'brand').toLowerCase()) {
          'academic' => PartnerTier.academic,
          'institutional' => PartnerTier.institutional,
          _ => PartnerTier.brand,
        },
        division: j['division'] as String? ?? j['category'] as String? ?? 'General',
        logoUrl: (j['logo_url'] as String?)?.trim() ?? '',
        city: j['city'] as String? ?? '',
        website: j['website'] as String? ?? '',
        bg: (j['bg'] as num?)?.toInt() ?? 0,
      );
}

/// Brand divisions used to group the "top brand partners" wall.
const List<String> brandDivisions = [
  'Fashion & Apparel',
  'Beauty & Cosmetics',
  'Jewellery & Luxury',
  'Sportswear & Fitness',
  'Media & Entertainment',
  'Hospitality & Travel',
];

const List<LogoPartner> seedAcademicPartners = [
  LogoPartner(
    name: 'National Institute of Fashion Technology',
    tagline: 'Design, styling and fashion communication intakes feeding the floor.',
    tier: PartnerTier.academic,
    division: 'Fashion Design',
    city: 'Delhi NCR',
    bg: 5,
  ),
  LogoPartner(
    name: 'Whistling Woods International',
    tagline: 'Film, acting and post-production graduates placed on live units.',
    tier: PartnerTier.academic,
    division: 'Film & Media',
    city: 'Mumbai',
    bg: 4,
  ),
  LogoPartner(
    name: 'Pearl Academy',
    tagline: 'Styling, communication design and fashion media programmes.',
    tier: PartnerTier.academic,
    division: 'Design & Styling',
    city: 'Jaipur',
    bg: 2,
  ),
  LogoPartner(
    name: 'Symbiosis Institute of Media',
    tagline: 'Media, advertising and brand communication cohorts.',
    tier: PartnerTier.academic,
    division: 'Media & Communication',
    city: 'Pune',
    bg: 1,
  ),
  LogoPartner(
    name: 'Lakmé Academy',
    tagline: 'Certified makeup, hair and beauty training partners.',
    tier: PartnerTier.academic,
    division: 'Beauty & Makeup',
    city: 'Mumbai',
    bg: 3,
  ),
  LogoPartner(
    name: 'Arena Animation',
    tagline: 'VFX, 3D and motion design certification pipelines.',
    tier: PartnerTier.academic,
    division: 'VFX & Animation',
    city: 'Bangalore',
    bg: 6,
  ),
  LogoPartner(
    name: 'Srishti Manipal',
    tagline: 'Art, design and visual communication practice.',
    tier: PartnerTier.academic,
    division: 'Art & Design',
    city: 'Bangalore',
    bg: 7,
  ),
  LogoPartner(
    name: 'Asian Academy of Film & Television',
    tagline: 'Direction, cinematography and acting programmes.',
    tier: PartnerTier.academic,
    division: 'Film & Media',
    city: 'Delhi NCR',
    bg: 0,
  ),
];

const List<LogoPartner> seedBrandPartners = [
  LogoPartner(name: 'Lakmé Fashion Week', tagline: 'Runway week — casting, fittings and backstage crews.', tier: PartnerTier.brand, division: 'Fashion & Apparel', city: 'Mumbai', bg: 2),
  LogoPartner(name: 'FDCI', tagline: 'Fashion council — India Fashion Week shortlists.', tier: PartnerTier.brand, division: 'Fashion & Apparel', city: 'Delhi NCR', bg: 5),
  LogoPartner(name: 'Raymond', tagline: 'Menswear campaigns and made-to-measure editorials.', tier: PartnerTier.brand, division: 'Fashion & Apparel', city: 'Mumbai', bg: 1),
  LogoPartner(name: 'Nykaa', tagline: 'Beauty campaigns, creator shoots and product films.', tier: PartnerTier.brand, division: 'Beauty & Cosmetics', city: 'Mumbai', bg: 3),
  LogoPartner(name: 'Forest Essentials', tagline: 'Luxury ayurveda — natural-light stills and craft films.', tier: PartnerTier.brand, division: 'Beauty & Cosmetics', city: 'Delhi NCR', bg: 7),
  LogoPartner(name: 'Tanishq', tagline: 'Bridal and polki campaigns with heritage locations.', tier: PartnerTier.brand, division: 'Jewellery & Luxury', city: 'Bangalore', bg: 0),
  LogoPartner(name: 'CaratLane', tagline: 'Contemporary jewellery — social-first campaign cuts.', tier: PartnerTier.brand, division: 'Jewellery & Luxury', city: 'Chennai', bg: 4),
  LogoPartner(name: 'Decathlon India', tagline: 'National sportswear campaigns, outdoor and studio.', tier: PartnerTier.brand, division: 'Sportswear & Fitness', city: 'Bangalore', bg: 6),
  LogoPartner(name: 'Puma India', tagline: 'Athletic talent, multi-city print and digital.', tier: PartnerTier.brand, division: 'Sportswear & Fitness', city: 'Bangalore', bg: 1),
  LogoPartner(name: 'Producers Guild of India', tagline: 'Scene protocols and production-house verification.', tier: PartnerTier.brand, division: 'Media & Entertainment', city: 'Mumbai', bg: 4),
  LogoPartner(name: 'Independent music labels', tagline: 'Narrative music videos with rights hygiene built in.', tier: PartnerTier.brand, division: 'Media & Entertainment', city: 'Mumbai', bg: 6),
  LogoPartner(name: 'Taj Hotels', tagline: 'Unit stays, banquets and heritage shoot permissions.', tier: PartnerTier.brand, division: 'Hospitality & Travel', city: 'Mumbai', bg: 0),
  LogoPartner(name: 'National tourism boards', tagline: 'Destination films pairing local crews with travelling talent.', tier: PartnerTier.brand, division: 'Hospitality & Travel', city: 'All India', bg: 1),
];

/// ── Team ────────────────────────────────────────────────────────
class TeamMember {
  final String name;
  final String role;
  final String desk;
  final String bio;
  final String photoUrl;
  final String city;
  final int bg;
  const TeamMember({
    required this.name,
    required this.role,
    required this.desk,
    required this.bio,
    this.photoUrl = '',
    this.city = '',
    this.bg = 0,
  });

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
        name: j['name'] as String? ?? '',
        role: j['role'] as String? ?? '',
        desk: j['desk'] as String? ?? j['department'] as String? ?? 'Desk',
        bio: j['bio'] as String? ?? '',
        photoUrl: (j['photo_url'] as String?)?.trim() ?? (j['avatar_url'] as String?)?.trim() ?? '',
        city: j['city'] as String? ?? '',
        bg: (j['bg'] as num?)?.toInt() ?? 0,
      );
}

const List<String> teamDesks = ['Leadership', 'Casting Desk', 'Production Desk', 'Verification', 'Editorial', 'Partnerships'];

const List<TeamMember> seedTeam = [
  TeamMember(name: 'Rehan Mirza', role: 'Founder & Chief Executive', desk: 'Leadership', city: 'Mumbai', bg: 0, bio: 'Built AOneGo9 around one rule — a booking should carry the same paperwork a studio call sheet does.'),
  TeamMember(name: 'Ananya Iyer', role: 'Head of Casting', desk: 'Casting Desk', city: 'Mumbai', bg: 2, bio: 'Runs shortlists for weeks, campaigns and OTT. Fifteen years across fashion and film casting.'),
  TeamMember(name: 'Vikram Sethi', role: 'Head of Production Partnerships', desk: 'Production Desk', city: 'Delhi NCR', bg: 4, bio: 'Signs the crews, studios and venues. Ex-line producer on national campaign shoots.'),
  TeamMember(name: 'Meera Krishnan', role: 'Verification Lead', desk: 'Verification', city: 'Bangalore', bg: 6, bio: 'Owns KYC. No listing reaches the public floor without clearing this desk.'),
  TeamMember(name: 'Farhan Qureshi', role: 'Editor, The Digest', desk: 'Editorial', city: 'Mumbai', bg: 5, bio: 'Writes what is happening and what is trending. Credentials checked before anything runs.'),
  TeamMember(name: 'Divya Rao', role: 'Academy & Brand Partnerships', desk: 'Partnerships', city: 'Hyderabad', bg: 3, bio: 'Connects institutes and brands to the talent pipeline they actually need.'),
  TeamMember(name: 'Arjun Nair', role: 'Head of Post & Design', desk: 'Production Desk', city: 'Kochi', bg: 7, bio: 'Curates the VFX, edit, 3D and graphic-design bench that finishes the work.'),
  TeamMember(name: 'Sanya Kapoor', role: 'Talent Relations', desk: 'Casting Desk', city: 'Delhi NCR', bg: 1, bio: 'First call for talent — comp cards, scene rules, rates and travel.'),
];

/// ── Workshops & Webinars ────────────────────────────────────────
/// The brief treats these as their own programme with their own updates
/// feed, separate from platform events.
class Session {
  final String id;

  /// 'workshop' (in person) | 'webinar' (online)
  final String mode;
  final String title;
  final String host;
  final String division; // taxonomy division id this session serves
  final String city;
  final String state;
  final String date;
  final String time;
  final String duration;
  final String fee;
  final int seats;
  final int seatsLeft;
  final String blurb;
  final String emoji;
  final int bg;
  final String registerUrl;

  const Session({
    required this.id,
    required this.mode,
    required this.title,
    required this.host,
    required this.division,
    required this.city,
    required this.date,
    this.state = '',
    this.time = '',
    this.duration = '',
    this.fee = 'Free',
    this.seats = 0,
    this.seatsLeft = 0,
    this.blurb = '',
    this.emoji = '🎓',
    this.bg = 0,
    this.registerUrl = '',
  });

  bool get isWebinar => mode == 'webinar';

  /// "Mumbai · Maharashtra", "Online", or just the city.
  ///
  /// Some places are their own state — Delhi NCR, Goa — and joining those
  /// blindly renders "Delhi NCR · Delhi NCR". Mirrors [UpdateEntry.place].
  String get placeLabel {
    if (city.isEmpty) return '';
    if (city.toLowerCase() == 'online') return city;
    if (state.isEmpty || state.toLowerCase() == city.toLowerCase()) return city;
    return '$city · $state';
  }
  bool get isFree => fee.trim().toLowerCase() == 'free';
  bool get nearlyFull => seats > 0 && seatsLeft > 0 && seatsLeft <= seats * 0.2;
  bool get soldOut => seats > 0 && seatsLeft <= 0;

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        id: '${j['id'] ?? ''}',
        mode: (j['mode'] as String? ?? j['type'] as String? ?? 'workshop').toLowerCase().contains('webinar')
            ? 'webinar'
            : 'workshop',
        title: j['title'] as String? ?? '',
        host: j['host'] as String? ?? j['presenter'] as String? ?? 'AOneGo9',
        division: j['division'] as String? ?? 'talent',
        city: j['city'] as String? ?? '',
        state: j['state'] as String? ?? '',
        date: j['date'] as String? ?? j['starts_at'] as String? ?? '',
        time: j['time'] as String? ?? '',
        duration: j['duration'] as String? ?? '',
        fee: j['fee'] as String? ?? 'Free',
        seats: (j['seats'] as num?)?.toInt() ?? 0,
        seatsLeft: (j['seats_left'] as num?)?.toInt() ?? 0,
        blurb: j['blurb'] as String? ?? j['description'] as String? ?? '',
        emoji: j['emoji'] as String? ?? '🎓',
        bg: (j['bg'] as num?)?.toInt() ?? 0,
        registerUrl: j['register_url'] as String? ?? '',
      );
}

const List<Session> seedSessions = [
  Session(
    id: 'ws-compcard', mode: 'workshop', title: 'Comp card clinic — what casting actually reads',
    host: 'Ananya Iyer · Head of Casting', division: 'talent', city: 'Mumbai', state: 'Maharashtra',
    date: '2026-09-14', time: '11:00 IST', duration: '3 hrs', fee: '₹1,500', seats: 40, seatsLeft: 6,
    blurb: 'Bring your book. We rebuild your comp card, measurements and shoot labels live, then shortlist against a real brief.',
    emoji: '📇', bg: 2,
  ),
  Session(
    id: 'wb-scene-protocol', mode: 'webinar', title: 'Scene protocols: intimacy coordination on OTT sets',
    host: 'Producers Guild panel', division: 'talent', city: 'Online', state: '',
    date: '2026-09-18', time: '18:30 IST', duration: '90 min', fee: 'Free', seats: 500, seatsLeft: 212,
    blurb: 'Closed-set rules, script notes, admin pre-approval and what a verified client is required to bring.',
    emoji: '🎬', bg: 4,
  ),
  Session(
    id: 'ws-bridal-makeup', mode: 'workshop', title: 'Bridal HD & airbrush intensive',
    host: 'Lakmé Academy', division: 'beauty', city: 'Delhi NCR', state: 'Delhi NCR',
    date: '2026-09-21', time: '10:00 IST', duration: '2 days', fee: '₹8,000', seats: 24, seatsLeft: 24,
    blurb: 'Skin prep, HD vs airbrush, camera-safe colour and a full bridal look built on a live model.',
    emoji: '💄', bg: 3,
  ),
  Session(
    id: 'wb-vertical-delivery', mode: 'webinar', title: 'Pricing vertical delivery without losing the brief',
    host: 'Vikram Sethi · Production Desk', division: 'post', city: 'Online', state: '',
    date: '2026-09-25', time: '17:00 IST', duration: '60 min', fee: 'Free', seats: 300, seatsLeft: 88,
    blurb: 'Hero film, three vertical cuts, a bumper and a stills pack — how to line-item it so nobody is surprised.',
    emoji: '📱', bg: 5,
  ),
  Session(
    id: 'ws-studio-lighting', mode: 'workshop', title: 'One-light fashion: cyclorama to natural window',
    host: 'AOneGo9 Studio, Andheri', division: 'crew', city: 'Mumbai', state: 'Maharashtra',
    date: '2026-10-02', time: '14:00 IST', duration: '4 hrs', fee: '₹2,500', seats: 18, seatsLeft: 3,
    blurb: 'Hands-on with strobe, HMI and daylight. Bring a body, leave with a lit series.',
    emoji: '💡', bg: 1,
  ),
  Session(
    id: 'wb-vfx-pipeline', mode: 'webinar', title: 'Clean-up, roto and comp: a realistic OTT pipeline',
    host: 'Arjun Nair · Head of Post', division: 'post', city: 'Online', state: '',
    date: '2026-10-09', time: '19:00 IST', duration: '75 min', fee: 'Free', seats: 400, seatsLeft: 341,
    blurb: 'What a series actually sends to post, how long each pass takes, and where budgets break.',
    emoji: '🪄', bg: 6,
  ),
  Session(
    id: 'ws-designer-lookbook', mode: 'workshop', title: 'Building a lookbook that sells the collection',
    host: 'Pearl Academy faculty', division: 'fashion', city: 'Jaipur', state: 'Rajasthan',
    date: '2026-10-16', time: '11:00 IST', duration: '1 day', fee: '₹4,000', seats: 30, seatsLeft: 17,
    blurb: 'Sequencing, styling continuity and shot lists — with a photographer and two models on the floor.',
    emoji: '👗', bg: 7,
  ),
  Session(
    id: 'wb-academy-intake', mode: 'webinar', title: 'From academy to first booking',
    host: 'Divya Rao · Partnerships', division: 'education', city: 'Online', state: '',
    date: '2026-10-23', time: '18:00 IST', duration: '60 min', fee: 'Free', seats: 600, seatsLeft: 512,
    blurb: 'For final-year students: portfolio minimums, verification, and how the desk shortlists new profiles.',
    emoji: '🎓', bg: 0,
  ),
];

/// ── Ads ─────────────────────────────────────────────────────────
/// "Video ads & photo ads by display show artist and vendor profile and the
/// AOneGo9 website" — a creative that promotes either a profile on the
/// marketplace or the platform itself.
class AdCreative {
  final String id;

  /// 'video' | 'photo'
  final String media;
  final String headline;
  final String sub;

  /// Poster/still. For a video ad this is the frame shown before playback.
  final String imageUrl;
  final String videoUrl;

  /// Where the ad points. [profileId] opens that profile in-app; when empty,
  /// [websiteUrl] is used instead.
  final String profileId;
  final String profileName;
  final String profileCat;
  final String websiteUrl;
  final String label; // 'Featured Artist' | 'Featured Vendor' | 'AOneGo9'
  final String city;
  final String emoji;
  final int bg;

  const AdCreative({
    required this.id,
    required this.media,
    required this.headline,
    required this.label,
    this.sub = '',
    this.imageUrl = '',
    this.videoUrl = '',
    this.profileId = '',
    this.profileName = '',
    this.profileCat = '',
    this.websiteUrl = '',
    this.city = '',
    this.emoji = '✦',
    this.bg = 0,
  });

  bool get isVideo => media == 'video';
  bool get opensProfile => profileId.isNotEmpty;

  factory AdCreative.fromJson(Map<String, dynamic> j) => AdCreative(
        id: '${j['id'] ?? ''}',
        media: (j['media'] as String? ?? j['type'] as String? ?? 'photo').toLowerCase().contains('vid') ? 'video' : 'photo',
        headline: j['headline'] as String? ?? j['title'] as String? ?? '',
        sub: j['sub'] as String? ?? j['subtitle'] as String? ?? '',
        imageUrl: (j['image_url'] as String?)?.trim() ?? '',
        videoUrl: (j['video_url'] as String?)?.trim() ?? '',
        profileId: '${j['profile_id'] ?? j['vendor_id'] ?? ''}',
        profileName: j['profile_name'] as String? ?? j['vendor_name'] as String? ?? '',
        profileCat: j['profile_cat'] as String? ?? j['category'] as String? ?? '',
        websiteUrl: j['website_url'] as String? ?? '',
        label: j['label'] as String? ?? 'Featured',
        city: j['city'] as String? ?? '',
        emoji: j['emoji'] as String? ?? '✦',
        bg: (j['bg'] as num?)?.toInt() ?? 0,
      );
}

/// House ads. These promote the platform itself and never fabricate a
/// third-party advertiser or a profile that doesn't exist — a seeded ad
/// pointing at a fake vendor id would 404 the moment someone tapped it.
const List<AdCreative> seedAds = [
  AdCreative(
    id: 'ad-house-reel', media: 'video', label: 'AOneGo9',
    headline: 'Every book, every rate, before you call.',
    sub: 'Portfolios, packages and scene rules published up front. Watch how a booking runs.',
    websiteUrl: 'https://aonego9.com', emoji: '🎬', bg: 4,
  ),
  AdCreative(
    id: 'ad-house-verify', media: 'photo', label: 'AOneGo9',
    headline: 'Admin-verified listings only.',
    sub: 'KYC cleared before a profile reaches the public floor.',
    websiteUrl: 'https://aonego9.com', emoji: '✓', bg: 0,
  ),
  AdCreative(
    id: 'ad-house-vendor', media: 'photo', label: 'AOneGo9',
    headline: 'List your book on AOneGo9.',
    sub: 'Talent, crews, studios, designers and stays — one verified floor.',
    websiteUrl: 'https://aonego9.com', emoji: '🏪', bg: 2,
  ),
];

/// ── Industry news verticals ─────────────────────────────────────
/// The digest already splits happening/trend. The brief adds the industry
/// each story belongs to, so readers can filter to their own vertical.
class NewsVertical {
  final String id;
  final String name;
  final String icon;
  const NewsVertical(this.id, this.name, this.icon);
}

const List<NewsVertical> newsVerticals = [
  NewsVertical('all', 'All industries', '⚡'),
  NewsVertical('fashion', 'Fashion', '👗'),
  NewsVertical('film', 'Film & OTT', '🎬'),
  NewsVertical('music', 'Music', '🎵'),
  NewsVertical('agency', 'Modelling agencies', '✦'),
  NewsVertical('modelling', 'Modelling industry', '📸'),
  NewsVertical('production', 'Production houses', '🎥'),
  NewsVertical('events', 'Event & shows', '🎪'),
  NewsVertical('organisation', 'Industry bodies', '🏛️'),
];

/// Infer a vertical when the backend hasn't tagged the story yet, so the
/// filter is useful on day one instead of dumping everything into "all".
String inferVertical(String tag, String title, String body) {
  final s = '$tag $title $body'.toLowerCase();
  if (s.contains('music') || s.contains('label') || s.contains('single')) return 'music';
  if (s.contains('ott') || s.contains('film') || s.contains('web series') || s.contains('intimacy')) return 'film';
  if (s.contains('production house') || s.contains('crew') || s.contains('unit')) return 'production';
  if (s.contains('agency') || s.contains('desk') || s.contains('roster')) return 'agency';
  if (s.contains('casting') || s.contains('comp card') || s.contains('model')) return 'modelling';
  if (s.contains('event') || s.contains('show') || s.contains('week') || s.contains('venue')) return 'events';
  if (s.contains('council') || s.contains('guild') || s.contains('board') || s.contains('fdci')) return 'organisation';
  if (s.contains('fashion') || s.contains('couture') || s.contains('handloom') || s.contains('ramp')) return 'fashion';
  return 'all';
}

/// ── Update feed entry ───────────────────────────────────────────
/// One row in the notification bar. Platform events, workshops and webinars
/// all collapse to this shape so the bar is a single sorted stream rather
/// than three feeds the reader has to reconcile.
class UpdateEntry {
  final String id;

  /// 'event' | 'workshop' | 'webinar' | 'update'
  final String kind;

  /// Taxonomy division id this update serves, or '' for platform-wide.
  final String division;
  final String title;
  final String city;
  final String state;
  final String date;
  final String emoji;

  /// Renders with the LIVE treatment — on the poster, or nearly sold out.
  final bool live;

  const UpdateEntry({
    required this.id,
    required this.kind,
    required this.title,
    this.division = '',
    this.city = '',
    this.state = '',
    this.date = '',
    this.emoji = '📣',
    this.live = false,
  });

  String get kindLabel => switch (kind) {
        'workshop' => 'Workshop',
        'webinar' => 'Webinar',
        'event' => 'Event',
        _ => 'Update',
      };

  /// "Mumbai · Maharashtra", "Online", or '' — the brief asks updates to
  /// carry city and state, but repeating "Delhi NCR · Delhi NCR" is noise.
  String get place {
    if (city.isEmpty) return '';
    if (state.isEmpty || state.toLowerCase() == city.toLowerCase()) return city;
    return '$city · $state';
  }
}
