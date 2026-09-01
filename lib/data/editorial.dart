/// Editorial content for the digest and the about story.
/// Live API payloads overlay this when the backend has published issues.
library;

import 'directory.dart';

class NewsletterIssue {
  final String id;
  final String kind; // happening | trend
  final String title;
  final String excerpt;
  final String body;
  final String city;
  final String date;
  final String tag;
  final String emoji;
  final int bg;
  final String? imageUrl;
  final String author;

  /// Industry vertical — fashion, film, music, agency, modelling, production,
  /// events, organisation. The brief asks the digest to be filterable by the
  /// industry a story belongs to, not only by happening/trend.
  final String vertical;

  const NewsletterIssue({
    required this.id,
    required this.kind,
    required this.title,
    required this.excerpt,
    required this.body,
    required this.city,
    required this.date,
    required this.tag,
    required this.emoji,
    required this.bg,
    this.imageUrl,
    this.author = 'AOneGo9 Desk',
    this.vertical = 'all',
  });

  factory NewsletterIssue.fromJson(Map<String, dynamic> j) {
    final tag = j['tag'] as String? ?? j['category'] as String? ?? 'Digest';
    final title = j['title'] as String? ?? '';
    final body = j['body'] as String? ?? j['content'] as String? ?? '';
    final declared = (j['vertical'] as String? ?? '').trim().toLowerCase();
    return NewsletterIssue(
        id: '${j['id'] ?? ''}',
        kind: (j['kind'] as String? ?? j['type'] as String? ?? 'happening').toLowerCase().contains('trend')
            ? 'trend'
            : 'happening',
        title: j['title'] as String? ?? '',
        excerpt: j['excerpt'] as String? ?? j['summary'] as String? ?? '',
        body: j['body'] as String? ?? j['content'] as String? ?? '',
        city: j['city'] as String? ?? 'India',
        date: j['date'] as String? ?? j['published_at'] as String? ?? '',
        tag: tag,
        emoji: j['emoji'] as String? ?? '✦',
        bg: (j['bg'] as num?)?.toInt() ?? 0,
        imageUrl: (j['image_url'] as String?)?.trim().isNotEmpty == true ? j['image_url'] as String : null,
        author: j['author'] as String? ?? j['author_name'] as String? ?? 'AOneGo9 Desk',
        // Trust the desk's own tagging; infer only when it hasn't tagged one,
        // so the filter is useful before the backend ships the field.
        vertical: newsVerticals.any((v) => v.id == declared) && declared != 'all'
            ? declared
            : inferVertical(tag, title, body),
      );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'title': title,
        'excerpt': excerpt,
        'body': body,
        'city': city,
        'date': date,
        'tag': tag,
        'emoji': emoji,
        'bg': bg,
        'image_url': imageUrl,
        'author': author,
        'vertical': vertical,
      };
}

const featuredIssueId = 'nl-lfw-aw26';

const List<NewsletterIssue> seedNewsletters = [
  NewsletterIssue(
    id: 'nl-lfw-aw26',
    vertical: 'modelling',
    kind: 'happening',
    title: 'Lakmé Fashion Week AW26 casting is open in Mumbai',
    excerpt: 'Walk, campaign and backstage roles for verified talent. AOneGo9 desks are coordinating fittings this fortnight.',
    body:
        'Casting for Lakmé Fashion Week Autumn/Winter 2026 is live. Designers are locking lookbooks this week — female and male talent with ramp, ethnic and commercial tags are being shortlisted first.\n\nIf you are booking a team, post an inquiry on the profile with dates and a moodboard. Verified production houses get priority routing through the AOneGo9 desk.\n\nFittings run in Bandra and Lower Parel. Travel for out-of-city talent is being discussed case by case.',
    city: 'Mumbai',
    date: '18 Aug 2026',
    tag: 'Casting',
    emoji: '👠',
    bg: 2,
    author: 'AOneGo9 Casting Desk',
  ),
  NewsletterIssue(
    id: 'nl-palace-winter',
    vertical: 'events',
    kind: 'happening',
    title: 'Winter palace season: heritage venues filling for Dec–Feb',
    excerpt: 'Jaipur and Udaipur properties are taking hold deposits now. Site visits this month still have weekday slots.',
    body:
        'Heritage palace and haveli venues across Rajasthan are opening winter books. Weekend dates in December and January are already tight for 200+ guest weddings.\n\nPhotographers and film crews who have shot these properties before are being requested alongside the venue inquiry — it shortens permissions.\n\nIf you need a site visit, use the venue profile and mark it urgent only when the date is inside 21 days.',
    city: 'Jaipur',
    date: '16 Aug 2026',
    tag: 'Venues',
    emoji: '🏛️',
    bg: 0,
  ),
  NewsletterIssue(
    id: 'nl-sportswear',
    vertical: 'modelling',
    kind: 'happening',
    title: 'National sportswear campaign: 8-city outdoor + studio',
    excerpt: 'Fitness and athletic talent, pan-India. Test shoots in Bangalore and Delhi next week.',
    body:
        'A national sportswear brand is locking talent for an eight-city outdoor and studio campaign. They want athletic builds, clean commercial energy, and people who can travel.\n\nTest shoots are scheduled in Bangalore and Delhi. Comp cards with recent fitness work are being pulled first.\n\nInquire on tagged fitness profiles with your city and travel window.',
    city: 'Bangalore',
    date: '14 Aug 2026',
    tag: 'Campaign',
    emoji: '💪',
    bg: 6,
  ),
  NewsletterIssue(
    id: 'nl-verified-photo',
    vertical: 'production',
    kind: 'happening',
    title: 'Forty new photographers passed verification this week',
    excerpt: 'Wedding, fashion and commercial books just landed on the marketplace. Portfolios are live to browse.',
    body:
        'The admin desk cleared a new wave of photography vendors. Each listing now carries KYC-verified status, packages and a public portfolio.\n\nIf you have been waiting on a city that felt thin — especially documentary wedding and brand stills — refresh Photography and filter by craft.\n\nVendors: incomplete galleries still delay approval. Six labeled images beats twenty unlabeled ones.',
    city: 'All India',
    date: '12 Aug 2026',
    tag: 'Marketplace',
    emoji: '📷',
    bg: 1,
  ),
  NewsletterIssue(
    id: 'nl-trend-intimacy',
    vertical: 'film',
    kind: 'trend',
    title: 'Intimacy coordinators are becoming a booking default on OTT sets',
    excerpt: 'Verified-client scene work now assumes a coordinator, a script note, and admin pre-approval.',
    body:
        'Production houses booking romance and intimate film scenes through AOneGo9 are arriving with coordinators already on the call sheet. Talent scene matrixes now surface this as a requirement, not a nice-to-have.\n\nThe pattern: script excerpt shared before the inquiry is forwarded, closed-set rules in writing, and the AOneGo9 desk on copy.\n\nIf you produce film, put the coordinator name in the inquiry message. It moves the conversation faster and keeps everyone inside the protocol.',
    city: 'Mumbai',
    date: '17 Aug 2026',
    tag: 'Sets',
    emoji: '🎬',
    bg: 4,
  ),
  NewsletterIssue(
    id: 'nl-trend-handloom',
    vertical: 'fashion',
    kind: 'trend',
    title: 'Handloom and regional silk are leading national lookbooks',
    excerpt: 'Banarasi, kanjivaram and kasavu are booking ethnic talent with temple and palace locations attached.',
    body:
        'Brand and tourism campaigns are leaning into craft — not as a festival extra, but as the hero look. Ethnic talent with temple, backwater and palace credits is being requested ahead of generic studio ethnic.\n\nStyling teams want movement in real locations. That means videographers who can hold ambient sound and photographers who can work with harsh noon light.\n\nIf your book has handloom work, label it. Unlabeled ethnic frames get skipped in shortlisting.',
    city: 'Chennai',
    date: '11 Aug 2026',
    tag: 'Craft',
    emoji: '🥻',
    bg: 3,
  ),
  NewsletterIssue(
    id: 'nl-trend-vertical',
    vertical: 'production',
    kind: 'trend',
    title: 'Vertical social is now a line item on most packages',
    excerpt: 'Clients ask for 9:16 cuts in the same brief as the hero film. Crews who price it clearly are winning.',
    body:
        'Brand films still need the 16:9 hero. They also need three vertical cuts, a bumper and a stills pack — in the same delivery window.\n\nVideographers who hide social as an afterthought are losing briefs to teams that list it as an add-on with a day rate.\n\nUpdate your packages. One honest line for vertical delivery is better than a surprise invoice.',
    city: 'Delhi NCR',
    date: '09 Aug 2026',
    tag: 'Social',
    emoji: '📱',
    bg: 5,
  ),
  NewsletterIssue(
    id: 'nl-trend-natural',
    vertical: 'fashion',
    kind: 'trend',
    title: 'Natural light editorials are outbooking heavy flash setups',
    excerpt: 'Skincare, fragrance and lifestyle briefs want window light and locations with a point of view.',
    body:
        'Luxury stills are moving outdoors and to rooms with a single hard window. Clients say flash-heavy beauty is reading dated against the feeds they actually buy from.\n\nThat does not kill studio work — it changes the default. Lead with a natural-light series, keep flash as a controlled option.\n\nTalent: bring a second look that works in daylight. Wardrobe that only photographs under strobe is getting left in the kit bag.',
    city: 'Goa',
    date: '07 Aug 2026',
    tag: 'Light',
    emoji: '🌿',
    bg: 7,
  ),
];

const List<Map<String, String>> aboutModules = [
  {
    'id': 'user',
    'icon': '✦',
    'name': 'Marketplace',
    'line': 'The AOneGo9 you are in now.',
    'copy':
        'Browse verified models, photographers, videographers, venues and event teams. Read the book, the packages and the scene rules — then inquire with a real brief.',
  },
  {
    'id': 'vendor',
    'icon': '⌂',
    'name': 'Vendor console',
    'line': 'For the people who get booked.',
    'copy':
        'Portfolio, packages, calendar, KYC and earnings live in the dedicated vendor app. The marketplace never becomes an admin panel.',
  },
  {
    'id': 'admin',
    'icon': '▣',
    'name': 'Super admin',
    'line': 'The desk that keeps the floor honest.',
    'copy':
        'Approvals, events, the live poster, subscriptions and the digest you are reading. Nothing reaches the public feed without this module.',
  },
];

const List<Map<String, dynamic>> seedEvents = [
  {
    'id': 'ev-lfw',
    'title': 'Lakmé Fashion Week AW26 — casting week',
    'city': 'Mumbai',
    'date': '2026-09-04',
    'end_date': '2026-09-08',
    'status': 'upcoming',
    'on_poster': true,
    'venue': 'Jio World Garden',
    'blurb': 'Walk, campaign and backstage roles. Verified talent only.',
    'emoji': '👠',
    'bg': 2,
  },
  {
    'id': 'ev-fdci',
    'title': 'India Fashion Week — designer fittings',
    'city': 'Delhi NCR',
    'date': '2026-10-12',
    'end_date': '2026-10-16',
    'status': 'upcoming',
    'on_poster': true,
    'venue': 'NSIC Grounds',
    'blurb': 'Lookbook and finale-walk shortlists opening next month.',
    'emoji': '👗',
    'bg': 5,
  },
  {
    'id': 'ev-palace',
    'title': 'Heritage venue open house',
    'city': 'Jaipur',
    'date': '2026-08-29',
    'end_date': '2026-08-29',
    'status': 'upcoming',
    'on_poster': false,
    'venue': 'City Palace circuit',
    'blurb': 'Site visits for winter wedding dates. Photographers welcome.',
    'emoji': '🏛️',
    'bg': 0,
  },
  {
    'id': 'ev-ott',
    'title': 'OTT casting workshop — scene protocols',
    'city': 'Mumbai',
    'date': '2026-09-18',
    'end_date': '2026-09-18',
    'status': 'upcoming',
    'on_poster': false,
    'venue': 'AOneGo9 Studio, Andheri',
    'blurb': 'Intimacy coordination, closed-set rules, inquiry hygiene.',
    'emoji': '🎬',
    'bg': 4,
  },
  {
    'id': 'ev-wedding-week',
    'title': 'Destination wedding week — Goa',
    'city': 'Goa',
    'date': '2026-11-20',
    'end_date': '2026-11-24',
    'status': 'upcoming',
    'on_poster': true,
    'venue': 'North Goa coast',
    'blurb': 'Film crews, talent and venues holding a shared calendar.',
    'emoji': '🌿',
    'bg': 7,
  },
];
