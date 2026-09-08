/// ─────────────────────────────────────────────────────────────────
/// DIRECTORY — partners, team, workshops/webinars, ads, news verticals.
///
/// Models + filter labels live here. Content lists start empty and are
/// filled only from the admin desk APIs — never invented locally.
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

const List<LogoPartner> seedAcademicPartners = [];
const List<LogoPartner> seedBrandPartners = [];

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

const List<TeamMember> seedTeam = [];

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

const List<Session> seedSessions = [];

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

/// Ads come from the desk only — no local house creatives.
const List<AdCreative> seedAds = [];

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
