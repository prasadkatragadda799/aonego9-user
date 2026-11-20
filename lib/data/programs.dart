/// ─────────────────────────────────────────────────────────────────
/// PROGRAMMES — shoots, campaigns, offers, the Open School, onboarding
/// profile types, the event planner and planning notebooks.
///
/// Like [directory.dart], every list the desk publishes (campaigns, offers,
/// courses) starts empty and is filled only from the API — nothing here is
/// invented content. What IS defined here is product structure: the two shoot
/// categories, the shoot roadmap, the onboarding profile types and the
/// planner's rules, which are the same for every visitor.
library;

import 'dart:convert';

// ── Shoots ──────────────────────────────────────────────────────

/// One of the two primary shoot categories.
class ShootCategory {
  final String id; // portfolio | personal
  final String title;
  final String tagline;
  final String icon;
  final List<String> types;
  const ShootCategory({
    required this.id,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.types,
  });
}

const List<ShootCategory> shootCategories = [
  ShootCategory(
    id: 'portfolio',
    title: 'Artist Portfolio Shoots',
    tagline: 'Comp cards, portfolios and brand-promotion shoots for models, actors and artists.',
    icon: '📸',
    types: [
      'Model portfolio',
      'Actor portfolio',
      'Comp card',
      'Brand promotion shoot',
      'Campaign shoot',
      'Designer lookbook',
      'Showreel',
    ],
  ),
  ShootCategory(
    id: 'personal',
    title: 'Personal Shoots',
    tagline: 'Pre-wedding, birthdays, maternity, family and fashion-for-fun shoots for everyone.',
    icon: '💫',
    types: [
      'Pre-wedding',
      'Birthday',
      'Maternity',
      'Family',
      'Couple',
      'Kids',
      'Fashion for fun',
    ],
  ),
];

/// A crew role the shoot request can ask for, tied to the marketplace
/// category that supplies it so the visitor can browse that crew directly.
class CrewRole {
  final String label;
  final String catId;
  final String icon;
  const CrewRole(this.label, this.catId, this.icon);
}

const List<CrewRole> shootCrew = [
  CrewRole('Photographer', 'photo', '📷'),
  CrewRole('Videographer', 'video', '🎥'),
  CrewRole('Makeup artist', 'makeupArtist', '💄'),
  CrewRole('Fashion designer', 'designer', '✂️'),
  CrewRole('Showroom / brand collection', 'clothShop', '🏬'),
  CrewRole('Jewellery', 'jewellery', '💎'),
  CrewRole('Studio floor', 'studio', '🎞️'),
];

const List<String> dressCodes = [
  'Stylist decides',
  'Western formal',
  'Western casual',
  'Ethnic / traditional',
  'Indo-western',
  'Bridal',
  'Sportswear',
  'Theme / costume',
];

/// Common time zones for a shoot schedule. India first; the rest cover the
/// diaspora and international campaign clients the brief mentions.
const List<String> shootTimeZones = [
  'IST (UTC+5:30)',
  'GST — Dubai (UTC+4)',
  'GMT — London (UTC+0)',
  'CET — Paris (UTC+1)',
  'EST — New York (UTC−5)',
  'PST — Los Angeles (UTC−8)',
  'SGT — Singapore (UTC+8)',
  'AEST — Sydney (UTC+10)',
];

/// The portfolio-shoot roadmap — the order the desk works in.
class RoadmapStep {
  final String title;
  final String detail;
  final String icon;
  const RoadmapStep(this.title, this.detail, this.icon);
}

const List<RoadmapStep> shootRoadmap = [
  RoadmapStep('Brief', 'Pick the shoot category and type, the city and what the pictures are for.', '📝'),
  RoadmapStep('Crew & look', 'Photographer, videographer, makeup artist and stylist matched to the brief.', '🎬'),
  RoadmapStep('Wardrobe', 'Dress code, designer pieces, showroom and brand collections confirmed.', '👗'),
  RoadmapStep('Schedule', 'Date, call time and time zone locked; the crew gets one call sheet.', '🗓️'),
  RoadmapStep('Shoot day', 'On-set coordination by the management team; updates posted as you go.', '📸'),
  RoadmapStep('Edit & deliver', 'Selects, retouching and the final gallery delivered to your account.', '🖼️'),
  RoadmapStep('Promote', 'Portfolio published, campaign card shared and social posts scheduled.', '🚀'),
];

// ── Campaigns ───────────────────────────────────────────────────

class Campaign {
  final String id;
  final String title;
  final String kind; // portfolio | personal | brand
  final String brand;
  final String blurb;
  final String city;
  final String date;
  final String deadline;
  final String emoji;
  final int bg;
  final String imageUrl;
  final String status; // open | voting | closed
  final int participants;
  final int votes;

  /// Voting choices (themes, looks, finalists). Empty = a simple upvote.
  final List<String> options;
  final Map<String, int> optionVotes;

  /// City → number of people who registered interest.
  final Map<String, int> cityInterest;

  const Campaign({
    required this.id,
    required this.title,
    this.kind = 'portfolio',
    this.brand = '',
    this.blurb = '',
    this.city = '',
    this.date = '',
    this.deadline = '',
    this.emoji = '📣',
    this.bg = 0,
    this.imageUrl = '',
    this.status = 'open',
    this.participants = 0,
    this.votes = 0,
    this.options = const [],
    this.optionVotes = const {},
    this.cityInterest = const {},
  });

  bool get isClosed => status == 'closed';

  static Map<String, int> _counts(dynamic raw) {
    if (raw is Map) {
      return {for (final e in raw.entries) '${e.key}': (e.value is num) ? (e.value as num).toInt() : 0};
    }
    if (raw is List) {
      final out = <String, int>{};
      for (final r in raw) {
        if (r is Map) {
          final k = '${r['city'] ?? r['option'] ?? r['label'] ?? ''}';
          if (k.isNotEmpty) out[k] = (r['count'] as num?)?.toInt() ?? 0;
        }
      }
      return out;
    }
    return const {};
  }

  factory Campaign.fromJson(Map<String, dynamic> j) {
    final k = (j['kind'] as String? ?? j['type'] as String? ?? 'portfolio').toLowerCase();
    return Campaign(
      id: '${j['id'] ?? ''}',
      title: j['title'] as String? ?? '',
      kind: k.contains('personal') ? 'personal' : (k.contains('brand') ? 'brand' : 'portfolio'),
      brand: j['brand'] as String? ?? j['sponsor'] as String? ?? '',
      blurb: j['blurb'] as String? ?? j['description'] as String? ?? '',
      city: j['city'] as String? ?? '',
      date: j['date'] as String? ?? j['starts_at'] as String? ?? '',
      deadline: j['deadline'] as String? ?? j['closes_at'] as String? ?? '',
      emoji: j['emoji'] as String? ?? '📣',
      bg: (j['bg'] as num?)?.toInt() ?? 0,
      imageUrl: (j['image_url'] as String? ?? '').trim(),
      status: (j['status'] as String? ?? 'open').toLowerCase(),
      participants: (j['participants'] as num?)?.toInt() ?? (j['participant_count'] as num?)?.toInt() ?? 0,
      votes: (j['votes'] as num?)?.toInt() ?? (j['vote_count'] as num?)?.toInt() ?? 0,
      options: ((j['options'] as List?) ?? const []).map((e) => e is Map ? '${e['label'] ?? ''}' : '$e').where((s) => s.isNotEmpty).toList(),
      optionVotes: _counts(j['option_votes'] ?? j['options_votes']),
      cityInterest: _counts(j['city_interest'] ?? j['interest_by_city']),
    );
  }
}

// ── Offers & coupons ────────────────────────────────────────────

class Offer {
  final String id;
  final String title;
  final String code;
  final String discount;
  final String blurb;
  final String appliesTo;
  final String validTill;
  final String terms;
  final String emoji;
  final int bg;
  const Offer({
    required this.id,
    required this.title,
    this.code = '',
    this.discount = '',
    this.blurb = '',
    this.appliesTo = '',
    this.validTill = '',
    this.terms = '',
    this.emoji = '🎁',
    this.bg = 0,
  });

  factory Offer.fromJson(Map<String, dynamic> j) => Offer(
        id: '${j['id'] ?? ''}',
        title: j['title'] as String? ?? '',
        code: (j['code'] as String? ?? j['coupon'] as String? ?? '').trim().toUpperCase(),
        discount: j['discount'] as String? ?? j['value'] as String? ?? '',
        blurb: j['blurb'] as String? ?? j['description'] as String? ?? '',
        appliesTo: j['applies_to'] as String? ?? j['category'] as String? ?? '',
        validTill: j['valid_till'] as String? ?? j['expires_at'] as String? ?? '',
        terms: j['terms'] as String? ?? '',
        emoji: j['emoji'] as String? ?? '🎁',
        bg: (j['bg'] as num?)?.toInt() ?? 0,
      );
}

// ── Open School / Academy ───────────────────────────────────────

class Course {
  final String id;
  final String title;
  final String stream;
  final String duration;
  final String mode; // Classroom | Online | Hybrid
  final String fee;
  final String intake;
  final String city;
  final int seats;
  final String blurb;
  final String emoji;
  final int bg;
  const Course({
    required this.id,
    required this.title,
    this.stream = '',
    this.duration = '',
    this.mode = 'Classroom',
    this.fee = '',
    this.intake = '',
    this.city = '',
    this.seats = 0,
    this.blurb = '',
    this.emoji = '🎓',
    this.bg = 0,
  });

  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: '${j['id'] ?? ''}',
        title: j['title'] as String? ?? j['name'] as String? ?? '',
        stream: j['stream'] as String? ?? j['category'] as String? ?? '',
        duration: j['duration'] as String? ?? '',
        mode: j['mode'] as String? ?? 'Classroom',
        fee: j['fee'] as String? ?? '',
        intake: j['intake'] as String? ?? j['starts_at'] as String? ?? '',
        city: j['city'] as String? ?? '',
        seats: (j['seats'] as num?)?.toInt() ?? 0,
        blurb: j['blurb'] as String? ?? j['description'] as String? ?? '',
        emoji: j['emoji'] as String? ?? '🎓',
        bg: (j['bg'] as num?)?.toInt() ?? 0,
      );
}

/// Streams the Open School teaches — the admission form's choices. Kept in
/// line with the Academy filter chips in the taxonomy.
const List<String> openSchoolStreams = [
  'Modelling & grooming',
  'Acting for camera',
  'Makeup & hair',
  'Photography',
  'Film making & editing',
  'Fashion design',
  'Dance & choreography',
  'Event management',
  'Social media & content',
];

// ── Onboarding profile types ────────────────────────────────────

/// A kind of business or organisation that can list on AOneGo9, the panel
/// it gets, and the marketplace categories its listing appears under.
class ProfileType {
  final String id;
  final String title;
  final String icon;
  final String who;
  final List<String> panel;
  final List<String> catIds;
  final String group; // creators | business | organisations | education
  const ProfileType({
    required this.id,
    required this.title,
    required this.icon,
    required this.who,
    required this.panel,
    required this.catIds,
    required this.group,
  });
}

const Map<String, String> profileTypeGroups = {
  'creators': 'Artists & talent',
  'business': 'Businesses & brands',
  'organisations': 'Organisations & media',
  'education': 'Education',
};

const List<ProfileType> profileTypes = [
  ProfileType(
    id: 'artist',
    title: 'Artists & models',
    icon: '✦',
    who: 'Models, actors, photographers, makeup artists, editors and designers.',
    panel: ['Portfolio by shoot type', 'Instagram & social links', 'Comp card & measurements', 'Inquiries & bookings'],
    catIds: ['modelF', 'modelM', 'photo', 'video', 'makeupArtist', 'designer'],
    group: 'creators',
  ),
  ProfileType(
    id: 'star',
    title: 'Celebrities & industry experts',
    icon: '🌟',
    who: 'Celebrities, directors, casting directors, influencers and mentors.',
    panel: ['Promotion area for photos & videos', 'Appearance & endorsement requests', 'Profile visibility campaigns', 'Managed by your desk'],
    catIds: ['celebrity', 'director', 'castingDirector', 'influencer', 'expert'],
    group: 'creators',
  ),
  ProfileType(
    id: 'vendor',
    title: 'Vendors & service providers',
    icon: '🧰',
    who: 'Studios, caterers, decorators, showrooms, jewellers and local services.',
    panel: ['Goods & services catalogue', 'Inventory — products and service slots', 'Packages & pricing', 'Leads and bookings'],
    catIds: ['studio', 'localVendor', 'clothShop', 'jewellery', 'makeupStudio', 'venue', 'hotel'],
    group: 'business',
  ),
  ProfileType(
    id: 'brand',
    title: 'Brands, sponsors & malls',
    icon: '🏷️',
    who: 'Brands, sponsors, showrooms, malls and companies promoting their offerings.',
    panel: ['Listings by city, state & country', 'Online & offline ad campaigns', 'Sponsorship of shows & campaigns', 'Promotional displays'],
    catIds: ['brand', 'mall', 'clothShop'],
    group: 'business',
  ),
  ProfileType(
    id: 'agencyBiz',
    title: 'Advertising & social media agencies',
    icon: '📣',
    who: 'Ad, PR, digital-marketing and social-media agencies.',
    panel: ['Client campaigns on AOneGo9', 'Audience targeting', 'Posts, graphics & video ads', 'Monthly plans'],
    catIds: ['adAgency'],
    group: 'business',
  ),
  ProfileType(
    id: 'organiser',
    title: 'Organisations & event organisers',
    icon: '🎪',
    who: 'Third-party organisations publishing events, shows and services.',
    panel: ['Publish events & shows', 'Ticket sales & registrations', 'Participant lists', 'Marketing & promotion'],
    catIds: ['events', 'organiser'],
    group: 'organisations',
  ),
  ProfileType(
    id: 'showOrganiser',
    title: 'Fashion, music, dance & talent shows',
    icon: '🎤',
    who: 'Organisers of fashion weeks, concerts, dance battles, pageants and talent hunts.',
    panel: ['Audition & participant registration', 'Ticketing', 'Judges & line-up', 'Voting & results'],
    catIds: ['organiser'],
    group: 'organisations',
  ),
  ProfileType(
    id: 'production',
    title: 'Production houses',
    icon: '🎥',
    who: 'Film, ad-film, music-video and digital production houses.',
    panel: ['Showreel & credits', 'Crew & equipment inventory', 'Project inquiries', 'Casting calls'],
    catIds: ['productionHouse'],
    group: 'organisations',
  ),
  ProfileType(
    id: 'modelAgency',
    title: 'Modelling agencies',
    icon: '🗂️',
    who: 'Agencies managing boards of models and talent.',
    panel: ['Boards & rosters', 'Package requests from clients', 'Casting submissions', 'Talent promotion'],
    catIds: ['agency'],
    group: 'organisations',
  ),
  ProfileType(
    id: 'media',
    title: 'News & media partners',
    icon: '📰',
    who: 'News agencies, magazines and media partners.',
    panel: ['Publish news by city, India & international', 'Categories & verticals', 'Notifications to artists, vendors & customers', 'Media partnerships'],
    catIds: [],
    group: 'organisations',
  ),
  ProfileType(
    id: 'school',
    title: 'Schools, academies & institutes',
    icon: '🎓',
    who: 'Schools, academies and training institutes.',
    panel: ['Student records', 'Fee management', 'Admissions & admission campaigns', 'Inventory & institution details'],
    catIds: ['academy'],
    group: 'education',
  ),
  ProfileType(
    id: 'college',
    title: 'Classes, colleges & universities',
    icon: '🏫',
    who: 'Colleges, universities, coaching classes, teachers and choreographers.',
    panel: ['Institution events & fests', 'Vendor connections', 'AI event planning & notebooks', 'Guest management & accounting'],
    catIds: ['college', 'coach'],
    group: 'education',
  ),
];

ProfileType? profileTypeById(String id) {
  for (final p in profileTypes) {
    if (p.id == id) return p;
  }
  return null;
}

// ── Event sectors ───────────────────────────────────────────────

/// Education and entertainment are separate sectors (requirement 7).
/// An event's sector comes from the desk when tagged; otherwise it is
/// inferred from its type/title so the filter works on today's data.
String eventSectorOf(Map<String, dynamic> e) {
  final declared = '${e['sector'] ?? ''}'.toLowerCase();
  if (declared.contains('edu')) return 'education';
  if (declared.contains('ent')) return 'entertainment';
  final hay = '${e['type'] ?? ''} ${e['category'] ?? ''} ${e['title'] ?? ''}'.toLowerCase();
  const edu = ['workshop', 'webinar', 'class', 'course', 'admission', 'seminar', 'masterclass', 'academy', 'school', 'college', 'university', 'training', 'lecture'];
  return edu.any(hay.contains) ? 'education' : 'entertainment';
}

/// The event type chips. Matched loosely on type/title.
const List<String> eventTypes = [
  'All',
  'Live events',
  'Fashion shows',
  'Entertainment',
  'Workshops',
  'Webinars',
  'Castings',
  'Festivals',
];

bool eventMatchesType(Map<String, dynamic> e, String type) {
  if (type == 'All') return true;
  final hay = '${e['type'] ?? ''} ${e['category'] ?? ''} ${e['title'] ?? ''} ${e['blurb'] ?? ''}'.toLowerCase();
  return switch (type) {
    'Live events' => e['on_poster'] == true || '${e['status'] ?? ''}'.toLowerCase() == 'live' || hay.contains('live'),
    'Fashion shows' => hay.contains('fashion') || hay.contains('ramp') || hay.contains('runway'),
    'Entertainment' => const ['concert', 'music', 'dance', 'comedy', 'show', 'party', 'night', 'entertain'].any(hay.contains),
    'Workshops' => hay.contains('workshop') || hay.contains('masterclass') || hay.contains('class'),
    'Webinars' => hay.contains('webinar') || hay.contains('online'),
    'Castings' => hay.contains('casting') || hay.contains('audition'),
    'Festivals' => const ['festival', 'fest', 'celebration', 'new year', 'summer', 'anniversary', 'diwali', 'holi'].any(hay.contains),
    _ => true,
  };
}

// ── Event planner ───────────────────────────────────────────────

const List<String> plannerEventTypes = [
  'Celebrity event',
  'Fashion show',
  'Festival / fest',
  'Anniversary',
  'New Year celebration',
  'Summer celebration',
  'Annual day',
  'Workshop / seminar',
  'Wedding',
  'Product launch',
];

class BudgetLine {
  final String label;
  final String catId; // marketplace category that supplies it ('' = none)
  final double share;
  final double amount;
  const BudgetLine(this.label, this.catId, this.share, this.amount);
}

class PlanStep {
  final String when;
  final String task;
  const PlanStep(this.when, this.task);
}

class EventPlan {
  final String type;
  final int guests;
  final double budget;
  final String city;
  final List<BudgetLine> budgetLines;
  final List<PlanStep> timeline;
  final List<String> checklist;
  final List<String> tips;
  const EventPlan({
    required this.type,
    required this.guests,
    required this.budget,
    required this.city,
    required this.budgetLines,
    required this.timeline,
    required this.checklist,
    required this.tips,
  });

  double get perGuest => guests <= 0 ? 0 : budget / guests;
}

/// The planner's rules. Deterministic, so the same brief always produces the
/// same plan and it works with no network. When the backend's AI endpoint
/// answers, its plan is used instead — see AppState.generatePlan.
class EventPlanner {
  static Map<String, double> _split(String type) => switch (type) {
        'Celebrity event' => {'Talent & appearance fee': .32, 'Venue': .18, 'Production, sound & light': .16, 'Security & guest management': .08, 'Hospitality & stay': .08, 'Photo & video coverage': .07, 'Marketing & promotion': .07, 'Contingency': .04},
        'Fashion show' => {'Venue & ramp': .20, 'Models & choreography': .20, 'Production, sound & light': .16, 'Designers & wardrobe': .12, 'Hair & makeup': .08, 'Photo & video coverage': .09, 'Marketing & promotion': .10, 'Contingency': .05},
        'Wedding' => {'Venue': .28, 'Catering': .26, 'Decor': .12, 'Photo & video coverage': .10, 'Hair & makeup': .05, 'Wardrobe & jewellery': .10, 'Hospitality & stay': .05, 'Contingency': .04},
        'Workshop / seminar' => {'Venue': .25, 'Speakers & trainers': .30, 'Catering': .15, 'Marketing & promotion': .15, 'Printing & kits': .08, 'Contingency': .07},
        'Product launch' => {'Venue': .22, 'Production, sound & light': .18, 'Celebrity / host': .18, 'Marketing & promotion': .18, 'Photo & video coverage': .10, 'Catering': .09, 'Contingency': .05},
        _ => {'Venue': .24, 'Catering': .22, 'Decor': .12, 'Production, sound & light': .14, 'Performers & host': .10, 'Photo & video coverage': .07, 'Marketing & promotion': .07, 'Contingency': .04},
      };

  static const Map<String, String> _catFor = {
    'Talent & appearance fee': 'celebrity',
    'Celebrity / host': 'celebrity',
    'Venue': 'venue',
    'Venue & ramp': 'venue',
    'Production, sound & light': 'events',
    'Hospitality & stay': 'hotel',
    'Photo & video coverage': 'photo',
    'Marketing & promotion': 'adAgency',
    'Models & choreography': 'agency',
    'Designers & wardrobe': 'designer',
    'Wardrobe & jewellery': 'jewellery',
    'Hair & makeup': 'makeupArtist',
    'Catering': 'localVendor',
    'Decor': 'localVendor',
    'Printing & kits': 'localVendor',
    'Performers & host': 'organiser',
    'Speakers & trainers': 'expert',
  };

  static EventPlan plan({
    required String type,
    required int guests,
    required double budget,
    required String city,
  }) {
    final split = _split(type);
    final lines = [
      for (final e in split.entries) BudgetLine(e.key, _catFor[e.key] ?? '', e.value, (budget * e.value).roundToDouble()),
    ];
    final big = guests >= 500;
    final timeline = <PlanStep>[
      PlanStep(big ? '12 weeks before' : '8 weeks before', 'Fix the date, budget and guest count; shortlist venues in $city.'),
      PlanStep(big ? '10 weeks before' : '6 weeks before', 'Book the venue and the headline ${type == 'Celebrity event' ? 'celebrity' : 'act'}; sign the production partner.'),
      PlanStep(big ? '8 weeks before' : '5 weeks before', 'Confirm caterer, decor and coverage crew; open registrations or ticket sales.'),
      const PlanStep('4 weeks before', 'Launch online & offline marketing — social posts, posters, video ads and invitations.'),
      const PlanStep('2 weeks before', 'Close the guest list, assign seating and passes, brief security and volunteers.'),
      const PlanStep('3 days before', 'Run-through with every vendor; share the call sheet and contact list.'),
      const PlanStep('Event day', 'Guest check-in, stage management and live updates on AOneGo9.'),
      const PlanStep('After', 'Settle vendor payments, post photos & highlights, send thank-you notes.'),
    ];
    final checklist = <String>[
      'Permissions & venue NOC',
      'Guest list and RSVP tracking',
      'Tickets / passes or registration form',
      'Run-of-show and stage cue sheet',
      'Vendor contracts and advance payments',
      'Sound, light and power backup',
      if (guests >= 200) 'Security, medical desk and crowd plan',
      if (type == 'Celebrity event' || type == 'Product launch') 'Green room, hospitality rider and press area',
      if (type == 'Fashion show') 'Model fittings, line-up and backstage plan',
      if (type == 'Workshop / seminar') 'Speaker kits, certificates and feedback form',
      'Photo & video coverage brief',
      'Social media posts and graphic design',
    ];
    final perGuest = guests <= 0 ? 0 : budget / guests;
    final tips = <String>[
      if (perGuest > 0 && perGuest < 800) 'At about ₹${perGuest.round()} a guest the budget is tight — favour a sponsor tie-up or a ticketed entry to cover production.',
      if (perGuest >= 3000) 'At about ₹${perGuest.round()} a guest there is room for a premium venue or a headline act.',
      if (big) 'Above 500 guests, book the venue and security first — they set every other date.',
      'Keep ${(split['Contingency'] ?? .05) * 100 ~/ 1}% aside for contingency and do not spend it before the week of the event.',
      'Post updates on AOneGo9 so artists, vendors and guests get notified automatically.',
    ];
    return EventPlan(
      type: type,
      guests: guests,
      budget: budget,
      city: city,
      budgetLines: lines,
      timeline: timeline,
      checklist: checklist,
      tips: tips,
    );
  }
}

// ── Planning notebooks ──────────────────────────────────────────

class NbGuest {
  String name;
  String phone;
  String rsvp; // Invited | Confirmed | Declined
  int party;
  NbGuest({required this.name, this.phone = '', this.rsvp = 'Invited', this.party = 1});
  Map<String, dynamic> toJson() => {'name': name, 'phone': phone, 'rsvp': rsvp, 'party': party};
  factory NbGuest.fromJson(Map<String, dynamic> j) => NbGuest(
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        rsvp: j['rsvp'] as String? ?? 'Invited',
        party: (j['party'] as num?)?.toInt() ?? 1,
      );
}

class NbExpense {
  String label;
  String category;
  double amount;
  bool paid;
  NbExpense({required this.label, this.category = '', this.amount = 0, this.paid = false});
  Map<String, dynamic> toJson() => {'label': label, 'category': category, 'amount': amount, 'paid': paid};
  factory NbExpense.fromJson(Map<String, dynamic> j) => NbExpense(
        label: j['label'] as String? ?? '',
        category: j['category'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        paid: j['paid'] == true,
      );
}

class NbTask {
  String label;
  String when;
  bool done;
  NbTask({required this.label, this.when = '', this.done = false});
  Map<String, dynamic> toJson() => {'label': label, 'when': when, 'done': done};
  factory NbTask.fromJson(Map<String, dynamic> j) =>
      NbTask(label: j['label'] as String? ?? '', when: j['when'] as String? ?? '', done: j['done'] == true);
}

class NbLog {
  final DateTime at;
  final String text;
  NbLog(this.at, this.text);
  Map<String, dynamic> toJson() => {'at': at.toIso8601String(), 'text': text};
  factory NbLog.fromJson(Map<String, dynamic> j) =>
      NbLog(DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(), j['text'] as String? ?? '');
}

/// An event-planning notebook: guests, budget ledger, tasks, notes and an
/// activity history. Stored on the device so it works signed out.
class Notebook {
  final String id;
  String title;
  String type;
  String city;
  String date;
  double budget;
  String notes;
  final List<NbGuest> guests;
  final List<NbExpense> expenses;
  final List<NbTask> tasks;
  final List<NbLog> history;

  Notebook({
    required this.id,
    required this.title,
    this.type = '',
    this.city = '',
    this.date = '',
    this.budget = 0,
    this.notes = '',
    List<NbGuest>? guests,
    List<NbExpense>? expenses,
    List<NbTask>? tasks,
    List<NbLog>? history,
  })  : guests = guests ?? [],
        expenses = expenses ?? [],
        tasks = tasks ?? [],
        history = history ?? [];

  double get spent => expenses.fold(0, (a, e) => a + e.amount);
  double get paid => expenses.where((e) => e.paid).fold(0, (a, e) => a + e.amount);
  double get remaining => budget - spent;
  int get headcount => guests.where((g) => g.rsvp != 'Declined').fold(0, (a, g) => a + g.party);
  int get confirmed => guests.where((g) => g.rsvp == 'Confirmed').fold(0, (a, g) => a + g.party);
  int get tasksDone => tasks.where((t) => t.done).length;

  void log(String text) => history.insert(0, NbLog(DateTime.now(), text));

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'city': city,
        'date': date,
        'budget': budget,
        'notes': notes,
        'guests': guests.map((g) => g.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'history': history.take(200).map((h) => h.toJson()).toList(),
      };

  factory Notebook.fromJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> list(String k) =>
        ((j[k] as List?) ?? const []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    return Notebook(
      id: j['id'] as String? ?? '',
      title: j['title'] as String? ?? 'Untitled event',
      type: j['type'] as String? ?? '',
      city: j['city'] as String? ?? '',
      date: j['date'] as String? ?? '',
      budget: (j['budget'] as num?)?.toDouble() ?? 0,
      notes: j['notes'] as String? ?? '',
      guests: list('guests').map(NbGuest.fromJson).toList(),
      expenses: list('expenses').map(NbExpense.fromJson).toList(),
      tasks: list('tasks').map(NbTask.fromJson).toList(),
      history: list('history').map(NbLog.fromJson).toList(),
    );
  }

  /// A notebook pre-filled from a generated plan: tasks from the timeline and
  /// the planned budget split in the notes. The ledger starts empty — it is
  /// for real quotes and payments, so "Remaining" means what it says.
  factory Notebook.fromPlan(EventPlan p, {required String id, String title = '', String date = ''}) {
    final split = [
      'Planned budget split (${inr(p.budget)} for ${p.guests} guests):',
      for (final b in p.budgetLines) '• ${b.label} — ${inr(b.amount)} (${(b.share * 100).round()}%)',
      '',
      'Checklist:',
      for (final c in p.checklist) '☐ $c',
    ].join('\n');
    final nb = Notebook(
      id: id,
      title: title.isEmpty ? '${p.type} · ${p.city}' : title,
      type: p.type,
      city: p.city,
      date: date,
      budget: p.budget,
      notes: split,
      tasks: [for (final s in p.timeline) NbTask(label: s.task, when: s.when)],
    );
    nb.log('Notebook created from the event planner');
    return nb;
  }

  static List<Notebook> decodeAll(String raw) {
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list.whereType<Map>().map((m) => Notebook.fromJson(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  static String encodeAll(List<Notebook> books) => jsonEncode(books.map((b) => b.toJson()).toList());
}

// ── Notification preferences ────────────────────────────────────

/// Profile-specific notification streams (requirements 6–8).
const Map<String, String> notificationStreams = {
  'artist': 'Artist updates — new portfolios, castings and talent news',
  'vendor': 'Vendor updates — new businesses, offers and services',
  'portfolio': 'My portfolio — shoot progress, deliveries and campaign results',
  'events': 'Events & shows — live events, fashion shows, entertainment',
  'education': 'Education — workshops, webinars, admissions and Open School',
  'offers': 'Offers & coupons — campaign deals and promotions',
  'news': 'News — city, India and international media updates',
  'ads': 'Sponsored — relevant brand promotions and advertisements',
};

/// Formats rupees with Indian digit grouping: 1234567 → ₹12,34,567.
String inr(num v) {
  final neg = v < 0;
  final s = v.abs().round().toString();
  if (s.length <= 3) return '${neg ? '−' : ''}₹$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${neg ? '−' : ''}₹${parts.join(',')},$last3';
}
