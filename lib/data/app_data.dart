/// ─────────────────────────────────────────────
/// DATA — 1:1 port of the original JS data objects.
/// Profile records are kept as dynamic maps to mirror the source
/// heterogeneous shape exactly (fields differ per category).
/// Gradient backgrounds are stored as integer indices → T.gr(i).
/// ─────────────────────────────────────────────
library;

const List<Map<String, dynamic>> cats = [
  {'id': 'venue', 'name': 'Event Venues', 'icon': '🏛️', 'count': 12},
  {'id': 'photo', 'name': 'Photography', 'icon': '📷', 'count': 28},
  {'id': 'video', 'name': 'Videography', 'icon': '🎬', 'count': 19},
  {'id': 'modelF', 'name': 'Female Models', 'icon': '👗', 'count': 47},
  {'id': 'modelM', 'name': 'Male Models', 'icon': '🧔', 'count': 31},
  {'id': 'events', 'name': 'Event Services', 'icon': '🎪', 'count': 15},
];

const Map<String, List<String>> filters = {
  'venue': ['All', 'Indoor', 'Outdoor', 'Rooftop', 'Heritage'],
  'photo': ['All', 'Fashion', 'Wedding', 'Commercial', 'Portrait'],
  'video': ['All', 'Brand Films', 'Wedding', 'Social Media', 'Documentary'],
  'modelF': ['All', 'Fashion', 'Ethnic', 'Ramp', 'Film', 'Commercial', 'Fitness'],
  'modelM': ['All', 'Fashion', 'Ethnic', 'Ramp', 'Film', 'Commercial', 'Fitness'],
  'events': ['All', 'Fashion Shows', 'Corporate', 'Wedding Events', 'Concerts'],
};

const Map<String, Map<String, String>> heroCopy = {
  'venue': {'h1': 'Curated ', 'h2': 'Event Venues', 'sub': 'Handpicked spaces for every event. View capacity, pricing, and availability — post your inquiry directly.'},
  'photo': {'h1': 'Professional ', 'h2': 'Photographers', 'sub': 'Full portfolio access, packages, and equipment specs. Browse and inquire in seconds.'},
  'video': {'h1': 'Cinematic ', 'h2': 'Videographers', 'sub': 'Brand films, weddings, social content. Watch reels, compare packages, post your brief.'},
  'modelF': {'h1': 'Female ', 'h2': 'Models & Talent', 'sub': 'Instagram-style portfolio with labeled shoots, comp card, and professional scene availability — all before you reach out.'},
  'modelM': {'h1': 'Male ', 'h2': 'Models & Talent', 'sub': 'Full portfolio with labeled shoots, comp card, measurements, and professional film scene availability.'},
  'events': {'h1': 'Event ', 'h2': 'Production Services', 'sub': 'Full-service event management. Clear packages, inclusions, and add-ons — inquire in under 2 minutes.'},
};

/// Type definitions for portfolio items (label, color hex, icon).
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

const List<Map<String, String>> storyFilters = [
  {'id': 'all', 'icon': '⚡', 'label': 'All'},
  {'id': 'fashion', 'icon': '👗', 'label': 'Fashion'},
  {'id': 'ethnic', 'icon': '🥻', 'label': 'Ethnic'},
  {'id': 'ramp', 'icon': '👠', 'label': 'Ramp'},
  {'id': 'commercial', 'icon': '📢', 'label': 'Brand'},
  {'id': 'film', 'icon': '🎬', 'label': 'Film'},
  {'id': 'fitness', 'icon': '💪', 'label': 'Fitness'},
  {'id': 'lifestyle', 'icon': '🌿', 'label': 'Lifestyle'},
  {'id': 'editorial', 'icon': '📖', 'label': 'Editorial'},
  {'id': 'artistic', 'icon': '🎨', 'label': 'Art'},
];

/// ── Portfolio for Priya Sharma ──
const List<Map<String, dynamic>> priyaPort = [
  {'type': 'ethnic', 'headline': 'Banarasi Silk Campaign', 'desc': 'Handloom saree for Jaipur Fashion Week 2025 — styling by House of Kotwara', 'emoji': '🥻', 'bg': 0},
  {'type': 'ramp', 'headline': 'Lakme Fashion Week Opening', 'desc': 'AW25 collection — Designer Studio Mumbai · Opening walk', 'emoji': '👠', 'bg': 1},
  {'type': 'commercial', 'headline': 'Puma India National Campaign', 'desc': 'Pan India print + digital campaign — 3 city outdoor + studio shoot', 'emoji': '📢', 'bg': 2},
  {'type': 'ethnic', 'headline': 'South Silk Bridal Collection', 'desc': 'Kanjivaram saree · Tamil Nadu Tourism + bridal brand collab', 'emoji': '🌸', 'bg': 3},
  {'type': 'film', 'headline': "Short Film — 'Monsoon Letters'", 'desc': 'Romantic lead role · Director: Kavya S. · 2024 · Independent film release', 'emoji': '🎬', 'bg': 4},
  {'type': 'editorial', 'headline': 'Vogue India Cover Story', 'desc': 'March 2025 issue · Art direction by Studio Lumière · 8-page feature', 'emoji': '📖', 'bg': 5},
  {'type': 'fitness', 'headline': 'Decathlon Sportswear 2025', 'desc': 'National sportswear campaign · 4 looks · Outdoor Bandra + studio', 'emoji': '💪', 'bg': 6},
  {'type': 'fashion', 'headline': 'Western Ready-to-Wear', 'desc': 'Contemporary fashion lookbook · AW 2025 collection · Brand X', 'emoji': '✨', 'bg': 7},
  {'type': 'bridal', 'headline': 'Bridal Couture — Delhi FW', 'desc': 'FDCI India Fashion Week · Bridal collection showcase · Lead model', 'emoji': '💒', 'bg': 0},
  {'type': 'film', 'headline': "Music Video Lead — 'Tum Se'", 'desc': 'Romantic lead role · Arjun Rao · 12M+ views · 2025 release', 'emoji': '🎵', 'bg': 1},
  {'type': 'lifestyle', 'headline': 'Travel & Lifestyle Series', 'desc': 'Premium lifestyle brand · Goa outdoor 3-location series · 10 looks', 'emoji': '🌿', 'bg': 2},
  {'type': 'artistic', 'headline': 'Fine Art Portrait Study', 'desc': 'Conceptual fine art shoot · Private collection · Mumbai gallery 2025', 'emoji': '🎨', 'bg': 3},
];

/// ── Portfolio for Aisha Nair ──
const List<Map<String, dynamic>> aishaPort = [
  {'type': 'ethnic', 'headline': 'Mysore Silk Collection', 'desc': 'Karnataka Tourism ethnic wear campaign · Temple location · 3 looks', 'emoji': '🥻', 'bg': 0},
  {'type': 'fitness', 'headline': 'Yoga & Wellness Campaign', 'desc': 'Lululemon India · Outdoor yoga series · 6 looks · Bangalore + Mysore', 'emoji': '💪', 'bg': 1},
  {'type': 'lifestyle', 'headline': 'Nykaa Skincare — Natural Light', 'desc': 'Skincare campaign · Natural light + outdoor · Bangalore studio', 'emoji': '🌸', 'bg': 2},
  {'type': 'commercial', 'headline': 'South India TV Commercial', 'desc': 'Regional bank TVC · 30-sec spot · 3 city media rotation', 'emoji': '📢', 'bg': 3},
  {'type': 'ethnic', 'headline': 'Kerala Bridal Collection', 'desc': 'Kasavu saree bridal shoot · Backwaters location · Wedding brand collab', 'emoji': '💒', 'bg': 4},
  {'type': 'film', 'headline': 'Web Series Supporting Role', 'desc': 'OTT platform drama · 3 episodes · Director: Suresh M. · 2025', 'emoji': '🎬', 'bg': 5},
  {'type': 'fashion', 'headline': 'Contemporary Casual Wear', 'desc': 'Denim + casual collection · Social media content + lookbook', 'emoji': '👗', 'bg': 6},
  {'type': 'lifestyle', 'headline': 'Kerala Tourism Campaign', 'desc': 'Kerala Tourism outdoor lifestyle campaign · 5 locations', 'emoji': '🌿', 'bg': 7},
];

/// ── Portfolio for Aryan Kapoor ──
const List<Map<String, dynamic>> aryanPort = [
  {'type': 'editorial', 'headline': 'GQ India Cover — August 2025', 'desc': 'Menswear editorial · Cover feature + 10-page spread · Styled by Rina Dev', 'emoji': '🧔', 'bg': 0},
  {'type': 'ethnic', 'headline': 'Sherwani Bridal Campaign', 'desc': "Men's ethnic wedding wear · Delhi + Jaipur shoot · Wedding brand", 'emoji': '🕌', 'bg': 1},
  {'type': 'ramp', 'headline': 'Wills India Fashion Week Finale', 'desc': 'National menswear designers showcase · Finale walk · 2025', 'emoji': '👔', 'bg': 2},
  {'type': 'grooming', 'headline': 'Beardo National Campaign', 'desc': 'Luxury grooming brand · Pan India print + digital + TVC', 'emoji': '✂️', 'bg': 3},
  {'type': 'film', 'headline': "Short Film — 'The Long Drive'", 'desc': 'Lead role · Road trip drama · Director: Meera S. · 2024 · Film festival screened', 'emoji': '🎬', 'bg': 4},
  {'type': 'fitness', 'headline': 'Decathlon Activewear 2025', 'desc': 'National sportswear + gym wear campaign · 5 looks · Outdoor + studio', 'emoji': '💪', 'bg': 5},
  {'type': 'ethnic', 'headline': 'Rajasthani Heritage Collection', 'desc': 'Jodhpuri coat collection · Rajasthan Tourism collab · Palace location', 'emoji': '🌅', 'bg': 6},
  {'type': 'film', 'headline': "Music Video Lead — 'Dil Se'", 'desc': 'Romantic lead · Priya Mathur · 20M+ views · 2025 · Chartbuster single', 'emoji': '🎵', 'bg': 7},
  {'type': 'fragrance', 'headline': 'Luxury Fragrance Campaign', 'desc': 'Premium fragrance · Pan India print editorial · Luxury styling', 'emoji': '✨', 'bg': 0},
  {'type': 'lifestyle', 'headline': 'Delhi Street Style Series', 'desc': 'Contemporary menswear street style · Delhi outdoor 5-location series', 'emoji': '🌿', 'bg': 1},
  {'type': 'commercial', 'headline': 'Bank of India TVC', 'desc': '30-sec national TV commercial · Brand ambassador · 2025 campaign', 'emoji': '📢', 'bg': 2},
  {'type': 'fashion', 'headline': 'Contemporary Casual Wear', 'desc': 'Denim & casual · Social media content series + lookbook', 'emoji': '👕', 'bg': 3},
];

/// Scene availability data. A map with a 'group' key starts a new group;
/// otherwise it is a scene item belonging to the current group.
const List<Map<String, dynamic>> priyaScenes = [
  {'group': 'General Content Work'},
  {'status': 'avail', 'icon': '✓', 'label': 'Fashion & Ramp', 'desc': 'Fashion weeks, brand lookbooks, runway — all formats'},
  {'status': 'avail', 'icon': '✓', 'label': 'Commercial / Brand', 'desc': 'TV commercials, print ads, OOH, digital campaigns'},
  {'status': 'avail', 'icon': '✓', 'label': 'Editorial / Magazine', 'desc': 'Print editorial, digital features, press coverage'},
  {'status': 'avail', 'icon': '✓', 'label': 'Fitness / Athletic', 'desc': 'Sportswear, wellness, bodycare brand work'},
  {'group': 'Film & On-Screen Work'},
  {'status': 'avail', 'icon': '✓', 'label': 'Film / Web Series Roles', 'desc': 'Non-intimate acting roles for feature films, OTT series, short films'},
  {'status': 'avail', 'icon': '✓', 'label': 'Music Video Lead Roles', 'desc': 'Romantic and narrative-led music video productions'},
  {
    'status': 'verified', 'icon': '⚠', 'label': 'On-Screen Romance & Kissing Scenes',
    'desc': 'Available for kissing and romantic scenes in legitimate film, web series, and short film productions.',
    'badge': 'VERIFIED CLIENT REQUIRED', 'badgeClass': 'v1',
    'reqs': ['Verified production company credentials required', 'Director + intimacy coordinator on set', 'Scene description/script shared before inquiry is forwarded', 'AOneGo9 admin pre-approval before discussion']
  },
  {
    'status': 'restricted', 'icon': '🔒', 'label': 'Intimate Film Scenes',
    'desc': 'Film-grade intimate scenes for legitimate productions only. Conducted strictly to industry standards.',
    'badge': 'ADMIN APPROVAL REQUIRED', 'badgeClass': 'v2',
    'reqs': ['Full production crew mandatory on set', 'Certified intimacy coordinator present throughout', 'Producer, director + AOneGo9 admin approval required', 'Legal documentation signed by all parties', 'Rate and scope negotiated privately after approval']
  },
  {'group': 'Fine Art & Other'},
  {'status': 'avail', 'icon': '✓', 'label': 'Artistic / Fine Art', 'desc': 'Creative fine art concepts, gallery shoots, art direction projects'},
  {'status': 'no', 'icon': '✗', 'label': 'Non-Film Adult Content', 'desc': 'Not available. All professional scene work is limited to legitimate film and media productions only.'},
];

const List<Map<String, dynamic>> aryanScenes = [
  {'group': 'General Content Work'},
  {'status': 'avail', 'icon': '✓', 'label': 'Fashion & Ramp', 'desc': 'Menswear runway, fashion weeks, brand lookbooks — all formats'},
  {'status': 'avail', 'icon': '✓', 'label': 'Commercial / Brand', 'desc': 'TV commercials, print ads, OOH, digital campaigns'},
  {'status': 'avail', 'icon': '✓', 'label': 'Editorial / Magazine', 'desc': 'Print editorial, digital features, press coverage'},
  {'status': 'avail', 'icon': '✓', 'label': 'Fitness / Athletic', 'desc': 'Sportswear, bodycare, gym wear brand campaigns'},
  {'status': 'avail', 'icon': '✓', 'label': 'Grooming & Fragrance', 'desc': 'All grooming, fragrance, and luxury menswear brand work'},
  {'group': 'Film & On-Screen Work'},
  {'status': 'avail', 'icon': '✓', 'label': 'Film / Web Series Roles', 'desc': 'Non-intimate acting roles for films, OTT series, short films'},
  {'status': 'avail', 'icon': '✓', 'label': 'Music Video Lead Roles', 'desc': 'Romantic and narrative-led music video productions'},
  {
    'status': 'verified', 'icon': '⚠', 'label': 'On-Screen Romance & Kissing Scenes',
    'desc': 'Available for kissing and romantic scenes in film, web series, and short film productions.',
    'badge': 'VERIFIED CLIENT REQUIRED', 'badgeClass': 'v1',
    'reqs': ['Verified production house credentials required', 'Director and intimacy coordinator on set', 'Scene description / script shared before inquiry forwarded', 'AOneGo9 admin pre-approval required']
  },
  {
    'status': 'restricted', 'icon': '🔒', 'label': 'Intimate Film Scenes',
    'desc': 'Film-grade intimate scenes for legitimate productions. All industry protocols strictly followed.',
    'badge': 'ADMIN APPROVAL REQUIRED', 'badgeClass': 'v2',
    'reqs': ['Full crew mandatory — no closed sets', 'Certified intimacy coordinator present throughout', 'Producer + director + AOneGo9 admin approval required', 'Legal documentation signed by all parties before discussion']
  },
  {'group': 'Fine Art & Other'},
  {'status': 'avail', 'icon': '✓', 'label': 'Artistic / Fine Art', 'desc': 'Creative fine art concepts, gallery shoots, art direction projects'},
  {'status': 'no', 'icon': '✗', 'label': 'Non-Film Adult Content', 'desc': 'Not available. All professional scene work limited to legitimate film and media productions only.'},
];

const List<Map<String, dynamic>> aishaScenes = [
  {'group': 'General Content Work'},
  {'status': 'avail', 'icon': '✓', 'label': 'Fashion & Ramp', 'desc': 'Fashion weeks, brand lookbooks, runway — all formats'},
  {'status': 'avail', 'icon': '✓', 'label': 'Commercial / Brand', 'desc': 'TV commercials, print ads, OOH, digital campaigns'},
  {'status': 'avail', 'icon': '✓', 'label': 'Editorial / Magazine', 'desc': 'Print editorial, digital features, press coverage'},
  {'status': 'avail', 'icon': '✓', 'label': 'Fitness / Athletic', 'desc': 'Sportswear, wellness, bodycare brand campaigns'},
  {'group': 'Film & On-Screen Work'},
  {'status': 'avail', 'icon': '✓', 'label': 'Film / Web Series Roles', 'desc': 'Non-intimate acting roles for OTT, films, short films'},
  {'status': 'avail', 'icon': '✓', 'label': 'Music Video Lead Roles', 'desc': 'Romantic and narrative-led music video productions'},
  {'status': 'no', 'icon': '✗', 'label': 'On-Screen Kissing Scenes', 'desc': 'Not currently available.'},
  {'status': 'no', 'icon': '✗', 'label': 'Intimate Film Scenes', 'desc': 'Not available.'},
  {'group': 'Other'},
  {'status': 'avail', 'icon': '✓', 'label': 'Artistic / Fine Art', 'desc': 'Creative fine art concepts and gallery projects'},
];

/// Main profile listing.
final List<Map<String, dynamic>> profiles = [
  {
    'id': 'v1', 'cat': 'venue', 'badge': 'Heritage Property', 'emoji': '🏛️', 'verified': true,
    'name': 'The Grand Atrium', 'tagline': '6 versatile event spaces · Up to 800 guests',
    'loc': 'Bandra, Mumbai', 'rating': 4.9, 'reviewCount': 203, 'tags': ['Indoor', 'Outdoor', 'Rooftop'],
    'overview': "Mumbai's most sought-after event destination — heritage architecture with contemporary production capabilities. 500+ events hosted across fashion, corporate, and social categories.",
    'stats': [{'n': '6', 'l': 'Event Spaces'}, {'n': '800', 'l': 'Max Capacity'}, {'n': '500+', 'l': 'Events'}, {'n': '2002', 'l': 'Est.'}],
    'spaces': [{'e': '🏛️', 'name': 'Grand Ballroom', 'cap': 'Up to 600 pax', 'price': '₹2.8L', 'bg': 0}, {'e': '🌿', 'name': 'Garden Lawn', 'cap': 'Up to 400 pax', 'price': '₹1.8L', 'bg': 1}, {'e': '🌅', 'name': 'Rooftop Deck', 'cap': 'Up to 150 pax', 'price': '₹1.2L', 'bg': 2}, {'e': '💼', 'name': 'Conference Suite', 'cap': 'Up to 80 pax', 'price': '₹70K', 'bg': 3}],
    'amenities': ['Valet Parking', 'In-house Catering', 'Full AV System', 'Bridal Suite', 'Generator Backup', 'High-Speed WiFi', 'CCTV', 'Dressing Rooms', 'Green Room', 'Loading Bay'],
    'avail': ['open', 'open', 'busy', 'open', 'today', 'busy', 'open', 'open', 'open', 'busy', 'open', 'open', 'open', 'busy'],
    'packages': [{'name': 'Half Day', 'price': '₹80,000', 'span': '/half-day', 'pop': false, 'feats': ['4 hrs access', 'Basic lighting', '1 coordinator', 'Seating 100', 'Parking 30']}, {'name': 'Full Day', 'price': '₹1,50,000', 'span': '/day', 'pop': true, 'feats': ['8 hrs', 'Premium lighting', '2 coordinators', 'Seating 200', 'Catering setup', 'Parking 80', 'Green room', 'AV system']}, {'name': 'Signature Event', 'price': '₹3,00,000', 'span': '/event', 'pop': false, 'feats': ['12 hrs', 'Full AV production', 'Dedicated manager', '400 guests', 'Full catering', 'Décor', 'Bridal suite', 'Livestream']}],
    'revList': [{'author': 'Priya Desai', 'role': 'Marketing Director, HUL', 'stars': '★★★★★', 'text': 'Team managed every detail flawlessly. The AV setup was world-class.', 'tag': 'Brand Launch'}, {'author': 'Arun Mehta', 'role': 'Founder, EventCraft', 'stars': '★★★★★', 'text': 'Exceptional rooftop event. Catering and coordination seamless from day one.', 'tag': 'Corporate Event'}, {'author': 'Meera Joshi', 'role': 'Wedding Planner', 'stars': '★★★★★', 'text': 'Grand Ballroom was stunning. Every single detail executed perfectly.', 'tag': 'Wedding'}],
    'url': '/venue/grand-atrium'
  },
  {
    'id': 'v2', 'cat': 'venue', 'badge': 'Boutique Rooftop', 'emoji': '🌆', 'verified': true,
    'name': 'Skyline Society', 'tagline': 'Intimate rooftop · Panoramic city views',
    'loc': 'Worli, Mumbai', 'rating': 4.7, 'reviewCount': 89, 'tags': ['Rooftop', 'Intimate', 'Views'],
    'overview': "Worli's premier rooftop event space for intimate, high-end gatherings — unobstructed 270° city views, curated lighting, exceptional hospitality.",
    'stats': [{'n': '2', 'l': 'Spaces'}, {'n': '120', 'l': 'Max Capacity'}, {'n': '200+', 'l': 'Events'}, {'n': '2016', 'l': 'Est.'}],
    'spaces': [{'e': '🌃', 'name': 'Skyline Terrace', 'cap': 'Up to 120 pax', 'price': '₹1.5L', 'bg': 4}, {'e': '🥂', 'name': 'Glass Lounge', 'cap': 'Up to 40 pax', 'price': '₹80K', 'bg': 5}],
    'amenities': ['Panoramic Views', 'Premium Bar', 'Event Lighting', 'AV System', 'Catering Kitchen', 'Valet Parking'],
    'avail': ['busy', 'open', 'open', 'open', 'today', 'open', 'open', 'open', 'busy', 'open', 'open', 'open'],
    'packages': [{'name': 'Cocktail Evening', 'price': '₹90,000', 'span': '/event', 'pop': false, 'feats': ['6 hrs', 'Bar setup', 'Lighting', '80 guests', '1 coordinator']}, {'name': 'Full Evening', 'price': '₹1,80,000', 'span': '/event', 'pop': true, 'feats': ['10 hrs', 'Premium bar', 'Full AV', '120 guests', 'Décor', 'Manager']}],
    'revList': [{'author': 'Nikhil Shah', 'role': 'Brand Head, Nykaa', 'stars': '★★★★★', 'text': 'Perfect for our intimate product launch. Views spectacular, team professional.', 'tag': 'Product Launch'}, {'author': 'Ananya K.', 'role': 'Event Planner', 'stars': '★★★★☆', 'text': 'Beautiful space — limited capacity but quality more than compensates.', 'tag': 'Corporate'}],
    'url': '/venue/skyline-society'
  },
  {
    'id': 'p1', 'cat': 'photo', 'badge': 'Premium Studio', 'emoji': '📷', 'verified': true,
    'name': 'Aarav Lens Studio', 'tagline': 'Editorial · Fashion · Commercial · Brand Campaigns',
    'loc': 'Andheri, Mumbai', 'rating': 4.9, 'reviewCount': 317, 'tags': ['Fashion', 'Editorial', 'Commercial'], 'exp': '9 yrs',
    'overview': 'Award-winning commercial and editorial photographer — a decade of work across fashion, product, and brand campaigns with India\'s top brands.',
    'stats': [{'n': '9 yrs', 'l': 'Experience'}, {'n': '500+', 'l': 'Shoots'}, {'n': '80+', 'l': 'Clients'}, {'n': '4.9★', 'l': 'Rating'}],
    'equipment': [{'e': '📷', 'name': 'Sony A1 + A7R V', 'note': 'Dual body · 50MP + 61MP'}, {'e': '🔭', 'name': 'Canon EF 70-200mm f/2.8L', 'note': 'Prime portrait telephoto'}, {'e': '💡', 'name': 'Profoto B10 Plus + D2', 'note': 'Studio & location lighting'}, {'e': '🚁', 'name': 'DJI Mavic 3 Pro', 'note': 'Aerial photography platform'}, {'e': '🖥️', 'name': 'Capture One Pro 23', 'note': 'Professional colour grading'}],
    'portfolio': [{'label': 'Fashion Editorial', 'sub': 'Vogue India', 'e': '📸', 'bg': 0, 'tall': true}, {'label': 'Brand Campaign', 'sub': 'Puma India', 'e': '🛍️', 'bg': 1}, {'label': 'E-Commerce', 'sub': 'Myntra', 'e': '📦', 'bg': 2}, {'label': 'Pre-Wedding', 'sub': 'Private', 'e': '💑', 'bg': 3, 'tall': true}, {'label': 'Aerial Work', 'sub': 'Real Estate', 'e': '🚁', 'bg': 4}, {'label': 'Corporate', 'sub': 'HDFC Bank', 'e': '🏢', 'bg': 5}],
    'packages': [{'name': 'Half-Day', 'price': '₹18,000', 'span': '', 'pop': false, 'feats': ['4 hrs', '80 edited images', '2-day delivery', 'Online gallery']}, {'name': 'Full Day', 'price': '₹32,000', 'span': '', 'pop': true, 'feats': ['8 hrs', '200+ images', 'Same-day previews', 'Commercial rights', 'BTS']}, {'name': 'Campaign', 'price': '₹85,000', 'span': '', 'pop': false, 'feats': ['2-day', 'Full crew', 'Unlimited images', 'Concept + storyboard', 'All-media rights']}],
    'revList': [{'author': 'Deepa Rajan', 'role': 'Creative Director, Myntra', 'stars': '★★★★★', 'text': 'Aarav transformed our entire campaign. Every shot was magazine-worthy.', 'tag': 'Fashion Campaign'}, {'author': 'Rohan Verma', 'role': 'Brand Manager, Puma', 'stars': '★★★★★', 'text': 'Understands the brief, executes flawlessly, delivers on time.', 'tag': 'Brand Campaign'}, {'author': 'Sneha Bhatt', 'role': 'Founder, StyleHouse', 'stars': '★★★★★', 'text': 'Our e-commerce shoot increased conversion by 34%.', 'tag': 'E-Commerce'}],
    'url': '/photographer/aarav-lens'
  },
  {
    'id': 'vid1', 'cat': 'video', 'badge': 'Cinema Grade', 'emoji': '🎬', 'verified': true,
    'name': 'Frame & Motion', 'tagline': 'Brand films · Wedding cinematic · Documentary',
    'loc': 'Juhu, Mumbai', 'rating': 4.9, 'reviewCount': 198, 'tags': ['Brand Films', 'Cinematic', 'Aerial'], 'exp': '10 yrs',
    'overview': "Mumbai's leading cinematic production house for brand films and wedding coverage. Cinema-grade quality for commercial, documentary, and event content since 2014.",
    'stats': [{'n': '10 yrs', 'l': 'Experience'}, {'n': '400+', 'l': 'Films'}, {'n': '80+', 'l': 'Clients'}, {'n': '4.9★', 'l': 'Rating'}],
    'equipment': [{'e': '🎥', 'name': 'RED Komodo 6K', 'note': 'Cinema-grade primary camera'}, {'e': '📹', 'name': 'Sony FX6 + FX3', 'note': 'B-camera · Low light specialist'}, {'e': '🚁', 'name': 'DJI Inspire 3', 'note': 'Professional aerial platform'}, {'e': '🎚️', 'name': 'Ronin 4D + Steadicam', 'note': 'Motion & stabilisation rig'}, {'e': '🎨', 'name': 'DaVinci Resolve Studio', 'note': 'Cinema colour grading suite'}],
    'reels': [{'name': 'Brand Film Showreel 2025', 'dur': '3:42', 'type': 'Brand / Commercial', 'e': '🎥'}, {'name': 'Cinematic Wedding Reel', 'dur': '4:18', 'type': 'Wedding / Events', 'e': '💒'}, {'name': 'Documentary Highlights', 'dur': '6:10', 'type': 'Documentary', 'e': '🎞️'}, {'name': 'Social Content Samples', 'dur': '2:05', 'type': 'Instagram / Reels', 'e': '📱'}],
    'portfolio': [{'label': 'Brand Film', 'sub': 'Nike India', 'e': '🎥', 'bg': 0, 'tall': true}, {'label': 'Wedding Cinematic', 'sub': 'Private', 'e': '💒', 'bg': 1}, {'label': 'Aerial Sequences', 'sub': 'Real Estate', 'e': '🚁', 'bg': 2}, {'label': 'Documentary', 'sub': 'NGO India', 'e': '🎞️', 'bg': 3, 'tall': true}, {'label': 'Music Video', 'sub': 'Artist', 'e': '🎵', 'bg': 4}, {'label': 'Social Content', 'sub': 'D2C Brand', 'e': '📱', 'bg': 5}],
    'packages': [{'name': 'Social Content Pack', 'price': '₹22,000', 'span': '', 'pop': false, 'feats': ['Half-day', '3–5 videos', 'Colour grade', 'Social formats']}, {'name': 'Brand Film', 'price': '₹75,000', 'span': '', 'pop': true, 'feats': ['2-day shoot', 'Full crew', '2–4 min film', 'Aerial footage', 'All-media rights']}, {'name': 'Premium Production', 'price': '₹2,00,000', 'span': '', 'pop': false, 'feats': ['3–5 day', 'Full crew', 'Multi-cam + aerial', 'Post + VFX', 'Music composition']}],
    'revList': [{'author': 'Akash Jain', 'role': 'CMO, UrbanClap', 'stars': '★★★★★', 'text': 'Produced our brand film at quality that rivalled agencies charging 5x the price.', 'tag': 'Brand Film'}, {'author': 'Vikram R.', 'role': 'Brand Director, Nike India', 'stars': '★★★★★', 'text': 'Professional, creative, on-time. Final cut exceeded every expectation.', 'tag': 'Campaign'}],
    'url': '/videographer/frame-and-motion'
  },
  {
    'id': 'mf1', 'cat': 'modelF', 'badge': 'Top Talent', 'emoji': '👗', 'verified': true,
    'name': 'Priya Sharma', 'tagline': 'Fashion · Ethnic · Commercial · Film Roles · Brand Campaigns',
    'loc': 'Mumbai', 'rating': 4.9, 'reviewCount': 68, 'tags': ['Fashion', 'Ethnic', 'Film'], 'exp': '5 yrs',
    'overview': "One of Mumbai's most in-demand models for fashion, ethnic wear, commercial, and on-screen roles. 5 years across digital, print, brand campaigns, and short film productions with top Indian brands.",
    'stats': [{'n': '5 yrs', 'l': 'Experience'}, {'n': '120+', 'l': 'Campaigns'}, {'n': '18', 'l': 'Film & TVC Roles'}, {'n': '4.9★', 'l': 'Rating'}],
    'height': "5'8\"", 'weight': '58 kg', 'bust': '34"', 'waist': '26"', 'hip': '36"',
    'shoe': 'UK 7', 'age': 25, 'hair': 'Black', 'eye': 'Brown', 'skin': 'Wheatish',
    'langs': 'Hindi, English, Marathi', 'training': 'AOneGo9 School of Modeling',
    'igPortfolio': priyaPort, 'sceneData': priyaScenes,
    'packages': [{'name': 'Half-Day', 'price': '₹15,000', 'span': '', 'pop': false, 'feats': ['4 hrs', '1–2 looks', 'Studio or location', 'Basic usage rights']}, {'name': 'Full Day', 'price': '₹28,000', 'span': '', 'pop': true, 'feats': ['8 hrs', 'Multiple looks', 'Travel within Mumbai', 'Commercial rights', 'Social mention']}, {'name': 'Campaign Rate', 'price': '₹65,000', 'span': '', 'pop': false, 'feats': ['2-day shoot', 'All-media rights', 'Brand exclusivity option', 'Pan India / international travel']}],
    'revList': [{'author': 'Deepa R.', 'role': 'Creative Director, Myntra', 'stars': '★★★★★', 'text': 'Priya elevated every frame. Her range across commercial and editorial work is genuinely exceptional.', 'tag': 'Fashion Campaign'}, {'author': 'Kavya S.', 'role': 'Film Director', 'stars': '★★★★★', 'text': "Brilliant on-screen presence in 'Monsoon Letters'. Priya's ability to hold emotion for camera was remarkable.", 'tag': 'Short Film'}, {'author': 'Rohit S.', 'role': 'Marketing Manager, Puma', 'stars': '★★★★★', 'text': "Priya's versatility gave us 3× the content variety from a single campaign shoot.", 'tag': 'Brand Campaign'}, {'author': 'Aarav L.', 'role': 'Photographer, LensCraft', 'stars': '★★★★★', 'text': 'Punctual, takes direction beautifully, brings genuine creative energy to every shoot.', 'tag': 'Editorial'}],
    'url': '/model/priya-sharma'
  },
  {
    'id': 'mf2', 'cat': 'modelF', 'badge': 'Rising Talent', 'emoji': '🌸', 'verified': true,
    'name': 'Aisha Nair', 'tagline': 'Lifestyle · Ethnic Wear · Fitness · Commercial',
    'loc': 'Bangalore', 'rating': 4.7, 'reviewCount': 34, 'tags': ['Lifestyle', 'Ethnic', 'Fitness'], 'exp': '3 yrs',
    'overview': "South India's emerging talent for lifestyle, ethnic wear, and fitness campaigns. Rapidly building a strong portfolio with regional and national brands.",
    'stats': [{'n': '3 yrs', 'l': 'Experience'}, {'n': '50+', 'l': 'Campaigns'}, {'n': '5', 'l': 'Film Roles'}, {'n': '4.7★', 'l': 'Rating'}],
    'height': "5'7\"", 'weight': '55 kg', 'bust': '33"', 'waist': '25"', 'hip': '35"',
    'shoe': 'UK 6', 'age': 23, 'hair': 'Brown', 'eye': 'Hazel', 'skin': 'Fair',
    'langs': 'Kannada, English, Hindi', 'training': 'AOneGo9 School of Modeling',
    'igPortfolio': aishaPort, 'sceneData': aishaScenes,
    'packages': [{'name': 'Half-Day', 'price': '₹10,000', 'span': '', 'pop': false, 'feats': ['4 hrs', '2 looks', 'Studio or location', 'Basic rights']}, {'name': 'Full Day', 'price': '₹18,000', 'span': '', 'pop': true, 'feats': ['8 hrs', 'Multiple looks', 'Bangalore / Mumbai', 'Commercial rights']}],
    'revList': [{'author': 'Nikhil V.', 'role': 'Creative Lead, Nykaa', 'stars': '★★★★★', 'text': 'Fresh, natural, and takes direction brilliantly. One of our best shoots of the year.', 'tag': 'Beauty Campaign'}, {'author': 'Suresh M.', 'role': 'Web Series Director', 'stars': '★★★★★', 'text': 'Natural on-screen presence. Professional beyond her years.', 'tag': 'Web Series'}],
    'url': '/model/aisha-nair'
  },
  {
    'id': 'mm1', 'cat': 'modelM', 'badge': 'Premium Talent', 'emoji': '🧔', 'verified': true,
    'name': 'Aryan Kapoor', 'tagline': 'Menswear · Ethnic · Grooming · Film Roles · Brand Campaigns',
    'loc': 'Delhi NCR', 'rating': 4.8, 'reviewCount': 52, 'tags': ['Fashion', 'Ethnic', 'Film'], 'exp': '6 yrs',
    'overview': "Delhi's premium male talent for menswear, ethnic wear, grooming, and film work. 6 years across fashion, lifestyle brands, and short film productions nationally.",
    'stats': [{'n': '6 yrs', 'l': 'Experience'}, {'n': '100+', 'l': 'Campaigns'}, {'n': '12', 'l': 'Film & TVC Roles'}, {'n': '4.8★', 'l': 'Rating'}],
    'height': "6'1\"", 'weight': '82 kg', 'chest': '42"', 'waist': '32"',
    'shoe': 'UK 10', 'age': 28, 'hair': 'Black', 'eye': 'Brown', 'skin': 'Wheatish',
    'langs': 'Hindi, English, Punjabi', 'training': 'AOneGo9 School of Modeling',
    'igPortfolio': aryanPort, 'sceneData': aryanScenes,
    'packages': [{'name': 'Half-Day', 'price': '₹16,000', 'span': '', 'pop': false, 'feats': ['4 hrs', '2 looks', 'Delhi / NCR', 'Basic rights']}, {'name': 'Full Day', 'price': '₹30,000', 'span': '', 'pop': true, 'feats': ['8 hrs', 'Multiple looks', 'Travel Delhi NCR', 'Commercial rights', 'Social mention']}, {'name': 'Campaign Rate', 'price': '₹70,000', 'span': '', 'pop': false, 'feats': ['2-day shoot', 'All-media rights', 'Brand exclusivity', 'Pan India travel']}],
    'revList': [{'author': 'Vikram A.', 'role': 'Brand Director, Beardo', 'stars': '★★★★★', 'text': 'Aryan has rare combination of physicality and camera awareness — exactly what our grooming campaign needed.', 'tag': 'Grooming Campaign'}, {'author': 'Simran K.', 'role': 'Fashion Editor, GQ India', 'stars': '★★★★★', 'text': 'Professional, punctual, brings real presence to every frame. Our editorial was a standout.', 'tag': 'Editorial'}, {'author': 'Meera S.', 'role': 'Film Director', 'stars': '★★★★★', 'text': 'Aryan held his own brilliantly in lead role against experienced cast. Genuine screen presence.', 'tag': 'Short Film'}, {'author': 'Rohan P.', 'role': 'Art Director, JWT', 'stars': '★★★★★', 'text': 'Outstanding talent. Client asked for him by name for the follow-up campaign.', 'tag': 'TVC'}],
    'url': '/model/aryan-kapoor'
  },
  {
    'id': 'ev1', 'cat': 'events', 'badge': 'Full Production', 'emoji': '🎪', 'verified': true,
    'name': 'AOneGo9 Event Services', 'tagline': 'Fashion shows · Corporate events · Award nights · Brand activations',
    'loc': 'Pan India', 'rating': 4.9, 'reviewCount': 412, 'tags': ['Fashion Shows', 'Corporate', 'Award Nights'],
    'overview': 'India\'s premier full-service event production house. Concept to execution — venues, talent, lighting, AV, catering, and on-ground coordination across India.',
    'stats': [{'n': '500+', 'l': 'Events Done'}, {'n': '120+', 'l': 'Brand Clients'}, {'n': '15+', 'l': 'Years Active'}, {'n': '20+', 'l': 'Cities'}],
    'services': ['Fashion Show Production', 'Award & Gala Nights', 'Corporate Events', 'Product Launches', 'Brand Activations', 'Concert Production', 'College Events', 'Wedding Event Production'],
    'portfolio': [{'label': 'Fashion Week', 'sub': 'National', 'e': '👗', 'bg': 0, 'tall': true}, {'label': 'Award Night', 'sub': '500 pax', 'e': '🏆', 'bg': 1}, {'label': 'Corporate Gala', 'sub': 'Fortune 500', 'e': '🏢', 'bg': 2}, {'label': 'Product Launch', 'sub': 'FMCG', 'e': '🚀', 'bg': 3, 'tall': true}, {'label': 'Concert', 'sub': 'Live Music', 'e': '🎤', 'bg': 4}, {'label': 'College Fest', 'sub': 'University', 'e': '🎓', 'bg': 5}],
    'eventPackages': [{'tier': 'Starter', 'name': 'Basic Event', 'price': '₹1,50,000', 'pop': false, 'feats': ['Venue coordination', 'Basic stage', 'Sound & AV', '2 coordinators', '100 guests', '4 hrs', 'Basic décor', 'Security']}, {'tier': 'Standard', 'name': 'Professional Event', 'price': '₹3,50,000', 'pop': true, 'feats': ['Premium venue', 'Custom stage + backdrop', 'Full AV + lighting', '4 coordinators + manager', '300 guests', '8 hrs', 'Full décor', 'Talent booking (1–3)', 'Catering', 'Photo & video', 'Social coverage']}, {'tier': 'Premium', 'name': 'Signature Experience', 'price': '₹8,00,000', 'pop': false, 'feats': ['Iconic venue', 'Bespoke stage design', 'Full production crew', 'Event director', '800 guests', '12 hrs', 'Luxury décor', '5+ talent', 'Full catering', 'Cinematic film', 'Live streaming', 'Press & media']}],
    'addons': [{'name': 'Celebrity / Artist Booking', 'price': '₹50,000+'}, {'name': 'Aerial Drone Coverage', 'price': '₹15,000'}, {'name': 'Live Band / DJ', 'price': '₹25,000+'}, {'name': 'Professional Emcee', 'price': '₹20,000+'}, {'name': 'Red Carpet Setup', 'price': '₹30,000'}, {'name': 'Social Media Live', 'price': '₹12,000'}],
    'revList': [{'author': 'Kavitha R.', 'role': 'Creative Director, Lakme Studio', 'stars': '★★★★★', 'text': 'AOneGo9 managed our fashion show from concept to curtain call. 400 attendees, not a single hiccup.', 'tag': 'Fashion Show'}, {'author': 'Suresh M.', 'role': 'CMO, Reliance Retail', 'stars': '★★★★★', 'text': 'Product launch was spectacular. AV, lighting, talent — all exceeded expectations.', 'tag': 'Product Launch'}, {'author': 'Priya N.', 'role': 'VP Events, HDFC Bank', 'stars': '★★★★★', 'text': 'Professional, creative, incredibly responsive. Our annual gala was the talk of the industry.', 'tag': 'Corporate Gala'}],
    'url': '/events/aonego9-event-services'
  },
];

const List<String> tickerItems = [
  '🏛️ Grand Atrium — Venue Available This Weekend · Mumbai',
  '📷 Aarav Lens Studio — New Campaign Portfolio Live',
  '🎬 Frame & Motion — Brand Film Packages Open',
  '👗 Priya Sharma — Fashion + Film Roles · Mumbai',
  '🧔 Aryan Kapoor — Menswear + Film Roles · Delhi NCR',
  '🌸 Aisha Nair — Ethnic + Lifestyle · Bangalore',
  '🎪 AOneGo9 Event Services — Summer 2026 Bookings Open',
];

const Map<String, List<String>> inqTypes = {
  'venue': ['Venue Booking', 'Site Visit Request', 'Package Query', 'Availability Check'],
  'photo': ['Photography Booking', 'Package Inquiry', 'Commercial Project', 'Test Shoot'],
  'video': ['Videography Booking', 'Brand Film Project', 'Package Inquiry', 'Social Content'],
  'modelF': ['Model Booking', 'Campaign Collaboration', 'Film / TVC Role', 'Test Shoot', 'Brand Tie-up'],
  'modelM': ['Model Booking', 'Campaign Collaboration', 'Film / TVC Role', 'Test Shoot', 'Brand Tie-up'],
  'events': ['Event Booking', 'Package Inquiry', 'Add-on Services', 'Custom Event Quote'],
};

const List<String> budgetRanges = [
  '₹10K – ₹50K', '₹50K – ₹1 Lakh', '₹1L – ₹5L', '₹5L – ₹20L', '₹20L+', 'Discuss on call',
];

const List<String> sceneOpts = [
  'Fashion & Ramp', 'Commercial / Brand', 'Editorial / Magazine',
  'Fitness / Athletic', 'Film / Web Series Roles',
  'On-Screen Romance / Kissing Scenes (Film)', 'Intimate Film Scenes (Admin Approval Required)',
];
