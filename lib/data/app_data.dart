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
