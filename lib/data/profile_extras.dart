/// ─────────────────────────────────────────────────────────────────
/// PROFILE EXTRAS — the bio-data the brief adds to a talent/vendor profile
/// beyond what the app already renders.
///
/// Already present before this: measurements, comp card, experience,
/// training, languages, portfolio gallery, packages, reviews, share link.
///
/// Added here, because the brief asks for each by name:
///   · social media handles          (link-in-bio: Instagram + others)
///   · awards & achievements
///   · past work / projects with links
///   · brand work — the logo + what was made for whom
///   · video reels and a mixed photo/video gallery
///
/// Everything parses defensively: a backend that hasn't shipped these fields
/// yet returns nothing and each section simply doesn't render.
library;

/// ── Social handles / link in bio ────────────────────────────────
class SocialLink {
  final String platform; // instagram, youtube, linkedin, website, …
  final String handle;
  final String url;
  const SocialLink({required this.platform, required this.handle, required this.url});

  static const Map<String, ({String label, String icon})> _known = {
    'instagram': (label: 'Instagram', icon: '📸'),
    'youtube': (label: 'YouTube', icon: '▶️'),
    'facebook': (label: 'Facebook', icon: '👥'),
    'linkedin': (label: 'LinkedIn', icon: '💼'),
    'x': (label: 'X', icon: '𝕏'),
    'twitter': (label: 'X', icon: '𝕏'),
    'behance': (label: 'Behance', icon: '🎨'),
    'vimeo': (label: 'Vimeo', icon: '🎞️'),
    'imdb': (label: 'IMDb', icon: '🎬'),
    'pinterest': (label: 'Pinterest', icon: '📌'),
    'whatsapp': (label: 'WhatsApp', icon: '💬'),
    'website': (label: 'Website', icon: '🔗'),
  };

  String get label => _known[platform.toLowerCase()]?.label ?? _titleCase(platform);
  String get icon => _known[platform.toLowerCase()]?.icon ?? '🔗';

  static String _titleCase(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  /// Normalises whatever the vendor typed into something openable.
  /// Vendors enter "@nameo", "instagram.com/name" or a full URL more or less
  /// at random, so a bare handle is expanded against the platform's own base.
  static String _normaliseUrl(String platform, String raw) {
    var v = raw.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    if (v.startsWith('@')) v = v.substring(1);
    final base = switch (platform.toLowerCase()) {
      'instagram' => 'https://instagram.com/',
      'youtube' => 'https://youtube.com/@',
      'facebook' => 'https://facebook.com/',
      'linkedin' => 'https://linkedin.com/in/',
      'x' || 'twitter' => 'https://x.com/',
      'behance' => 'https://behance.net/',
      'vimeo' => 'https://vimeo.com/',
      'pinterest' => 'https://pinterest.com/',
      'imdb' => 'https://imdb.com/name/',
      'whatsapp' => 'https://wa.me/',
      _ => '',
    };
    if (base.isEmpty) return _looksLikeDomain(v) ? 'https://$v' : '';
    // A pasted domain shouldn't get the base glued in front of it — but a
    // bare handle must not be mistaken for one either. Instagram handles
    // legitimately contain dots ("priya.sharma"), so presence of a dot is not
    // enough; it has to end in something that is actually a TLD.
    if (_looksLikeDomain(v)) return 'https://${v.replaceFirst(RegExp(r'^//'), '')}';
    return '$base$v';
  }

  /// Deliberately a short, common-TLD list rather than the full IANA set:
  /// the only job here is telling "instagram.com/priya" apart from the handle
  /// "priya.sharma", and a broader list makes more handles look like domains.
  static final _domainish = RegExp(
    r'^(https?://)?(www\.)?[\w-]+(\.[\w-]+)*\.(com|net|org|in|co|io|me|tv|app|dev|xyz|info|biz|studio|agency)(/|$|\?)',
    caseSensitive: false,
  );

  static bool _looksLikeDomain(String v) => v.contains('/') || _domainish.hasMatch(v);

  static SocialLink? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final j = raw.cast<String, dynamic>();
    final platform = (j['platform'] as String? ?? j['name'] as String? ?? '').trim();
    final handle = (j['handle'] as String? ?? j['username'] as String? ?? '').trim();
    final url = _normaliseUrl(platform, (j['url'] as String? ?? handle));
    if (platform.isEmpty || url.isEmpty) return null;
    return SocialLink(
      platform: platform,
      handle: handle.isNotEmpty ? handle : platform,
      url: url,
    );
  }

  /// Also accepts the flat shape `{"instagram": "@name", "youtube": "..."}`,
  /// which is how a simple vendor form is most likely to save them.
  static List<SocialLink> parse(dynamic raw) {
    if (raw is List) {
      return raw.map(SocialLink.fromJson).whereType<SocialLink>().toList();
    }
    if (raw is Map) {
      final out = <SocialLink>[];
      raw.forEach((k, v) {
        if (v == null) return;
        final handle = v.toString().trim();
        if (handle.isEmpty) return;
        final url = _normaliseUrl('$k', handle);
        if (url.isEmpty) return;
        out.add(SocialLink(platform: '$k', handle: handle, url: url));
      });
      return out;
    }
    return const [];
  }
}

/// ── Awards & achievements ───────────────────────────────────────
class Award {
  final String title;
  final String issuer;
  final String year;
  final String note;
  const Award({required this.title, this.issuer = '', this.year = '', this.note = ''});

  static List<Award> parse(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) {
      final j = m.cast<String, dynamic>();
      return Award(
        title: (j['title'] as String? ?? j['name'] as String? ?? '').trim(),
        issuer: (j['issuer'] as String? ?? j['by'] as String? ?? '').trim(),
        year: '${j['year'] ?? ''}'.trim(),
        note: (j['note'] as String? ?? j['description'] as String? ?? '').trim(),
      );
    }).where((a) => a.title.isNotEmpty).toList();
  }
}

/// ── Past work / projects ────────────────────────────────────────
/// "Add to work project links and photo & video & links" — a credit with an
/// optional still, an optional cut, and an optional link out.
class WorkProject {
  final String title;
  final String client;
  final String role;
  final String year;
  final String summary;
  final String imageUrl;
  final String videoUrl;
  final String link;
  final String type; // shoot type from the taxonomy, when tagged

  const WorkProject({
    required this.title,
    this.client = '',
    this.role = '',
    this.year = '',
    this.summary = '',
    this.imageUrl = '',
    this.videoUrl = '',
    this.link = '',
    this.type = '',
  });

  bool get hasMedia => imageUrl.isNotEmpty || videoUrl.isNotEmpty;

  static List<WorkProject> parse(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) {
      final j = m.cast<String, dynamic>();
      return WorkProject(
        title: (j['title'] as String? ?? j['name'] as String? ?? '').trim(),
        client: (j['client'] as String? ?? j['brand'] as String? ?? '').trim(),
        role: (j['role'] as String? ?? '').trim(),
        year: '${j['year'] ?? ''}'.trim(),
        summary: (j['summary'] as String? ?? j['description'] as String? ?? '').trim(),
        imageUrl: (j['image_url'] as String? ?? '').trim(),
        videoUrl: (j['video_url'] as String? ?? '').trim(),
        link: (j['link'] as String? ?? j['url'] as String? ?? '').trim(),
        type: (j['type'] as String? ?? '').trim(),
      );
    }).where((w) => w.title.isNotEmpty).toList();
  }
}

/// ── Brand work ──────────────────────────────────────────────────
/// "Artist profile brand work motion profile division — artist show logo and
/// details work about". A brand the profile has worked with: the mark, the
/// division it sits in, and what was actually made.
class BrandWork {
  final String brand;
  final String logoUrl;
  final String division;
  final String work;
  final String year;
  final String city;
  final String link;

  const BrandWork({
    required this.brand,
    this.logoUrl = '',
    this.division = '',
    this.work = '',
    this.year = '',
    this.city = '',
    this.link = '',
  });

  static List<BrandWork> parse(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) {
      final j = m.cast<String, dynamic>();
      return BrandWork(
        brand: (j['brand'] as String? ?? j['name'] as String? ?? '').trim(),
        logoUrl: (j['logo_url'] as String? ?? '').trim(),
        division: (j['division'] as String? ?? j['category'] as String? ?? '').trim(),
        work: (j['work'] as String? ?? j['description'] as String? ?? '').trim(),
        year: '${j['year'] ?? ''}'.trim(),
        city: (j['city'] as String? ?? '').trim(),
        link: (j['link'] as String? ?? j['url'] as String? ?? '').trim(),
      );
    }).where((b) => b.brand.isNotEmpty).toList();
  }
}

/// ── Media (photos + videos in one gallery) ──────────────────────
class MediaItem {
  final String url;
  final String thumbUrl;
  final bool isVideo;
  final String caption;
  final String type; // shoot type tag

  const MediaItem({
    required this.url,
    this.thumbUrl = '',
    this.isVideo = false,
    this.caption = '',
    this.type = '',
  });

  /// Poster to paint. Videos rarely ship a thumbnail, and a video URL in an
  /// <img> renders as a broken box — so this stays empty and the caller
  /// draws the gradient/emoji placeholder instead.
  String get poster => thumbUrl.isNotEmpty ? thumbUrl : (isVideo ? '' : url);

  static bool _looksLikeVideo(String url) {
    final u = url.toLowerCase().split('?').first;
    return u.endsWith('.mp4') ||
        u.endsWith('.mov') ||
        u.endsWith('.webm') ||
        u.endsWith('.m3u8') ||
        u.contains('youtube.com') ||
        u.contains('youtu.be') ||
        u.contains('vimeo.com');
  }

  static List<MediaItem> parse(dynamic raw) {
    if (raw is! List) return const [];
    final out = <MediaItem>[];
    for (final e in raw) {
      if (e is String) {
        final url = e.trim();
        if (url.isEmpty) continue;
        out.add(MediaItem(url: url, isVideo: _looksLikeVideo(url)));
        continue;
      }
      if (e is Map) {
        final j = e.cast<String, dynamic>();
        final url = (j['url'] as String? ?? j['video_url'] as String? ?? j['image_url'] as String? ?? '').trim();
        if (url.isEmpty) continue;
        final declared = j['is_video'];
        out.add(MediaItem(
          url: url,
          thumbUrl: (j['thumb_url'] as String? ?? j['poster_url'] as String? ?? '').trim(),
          isVideo: declared is bool ? declared : _looksLikeVideo(url),
          caption: (j['caption'] as String? ?? j['title'] as String? ?? '').trim(),
          type: (j['type'] as String? ?? j['tag'] as String? ?? '').trim(),
        ));
      }
    }
    return out;
  }
}

/// Everything above, parsed once from a profile-details payload.
class ProfileExtras {
  final List<SocialLink> socials;
  final List<Award> awards;
  final List<WorkProject> projects;
  final List<BrandWork> brands;
  final List<MediaItem> media;

  const ProfileExtras({
    this.socials = const [],
    this.awards = const [],
    this.projects = const [],
    this.brands = const [],
    this.media = const [],
  });

  bool get isEmpty =>
      socials.isEmpty && awards.isEmpty && projects.isEmpty && brands.isEmpty && media.isEmpty;

  /// Reads from a profile-details map, accepting both snake_case (what the
  /// FastAPI backend emits) and the camelCase the UI layer uses internally.
  factory ProfileExtras.from(Map<String, dynamic> j) => ProfileExtras(
        socials: SocialLink.parse(j['socials'] ?? j['social_links'] ?? j['socialLinks']),
        awards: Award.parse(j['awards'] ?? j['achievements']),
        projects: WorkProject.parse(j['projects'] ?? j['past_work'] ?? j['pastWork']),
        brands: BrandWork.parse(j['brand_work'] ?? j['brandWork'] ?? j['brands']),
        media: MediaItem.parse(j['media'] ?? j['gallery'] ?? j['videos']),
      );
}
