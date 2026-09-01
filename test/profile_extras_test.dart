import 'package:flutter_test/flutter_test.dart';
import 'package:aonego9_user/data/profile_extras.dart';

void main() {
  group('SocialLink', () {
    test('expands a bare handle against the platform base', () {
      final links = SocialLink.parse({'instagram': '@priya.sharma'});
      expect(links.single.url, 'https://instagram.com/priya.sharma');
    });

    test('leaves a full URL alone', () {
      final links = SocialLink.parse([
        {'platform': 'youtube', 'url': 'https://youtube.com/@studio'},
      ]);
      expect(links.single.url, 'https://youtube.com/@studio');
    });

    test('does not glue the base in front of a pasted domain', () {
      final links = SocialLink.parse({'instagram': 'instagram.com/priya'});
      expect(links.single.url, 'https://instagram.com/priya');
    });

    test('accepts both the list and the flat-map shapes', () {
      expect(SocialLink.parse({'instagram': '@a', 'linkedin': 'b'}).length, 2);
      expect(
        SocialLink.parse([
          {'platform': 'instagram', 'handle': '@a'},
          {'platform': 'linkedin', 'handle': 'b'},
        ]).length,
        2,
      );
    });

    test('drops entries with no usable target', () {
      expect(SocialLink.parse({'instagram': ''}), isEmpty);
      expect(SocialLink.parse([{'platform': '', 'url': ''}]), isEmpty);
      expect(SocialLink.parse(null), isEmpty);
    });

    test('an unknown platform needs a real domain to survive', () {
      expect(SocialLink.parse({'myspace': 'someone'}), isEmpty);
      expect(SocialLink.parse({'myspace': 'myspace.com/someone'}).length, 1);
    });
  });

  group('MediaItem', () {
    test('detects video by extension and by host', () {
      final m = MediaItem.parse([
        'https://cdn.test/a.jpg',
        'https://cdn.test/b.mp4',
        'https://youtu.be/xyz',
        'https://vimeo.com/123',
      ]);
      expect(m.map((e) => e.isVideo).toList(), [false, true, true, true]);
    });

    test('a declared is_video flag wins over the extension guess', () {
      final m = MediaItem.parse([
        {'url': 'https://cdn.test/stream', 'is_video': true},
      ]);
      expect(m.single.isVideo, isTrue);
    });

    test('a video with no thumbnail has no poster, so the caller draws a placeholder', () {
      // Putting a video URL into an <img> renders a broken box; poster must
      // stay empty so the gradient fallback is used instead.
      expect(MediaItem.parse(['https://cdn.test/b.mp4']).single.poster, '');
      expect(MediaItem.parse(['https://cdn.test/a.jpg']).single.poster, 'https://cdn.test/a.jpg');
    });

    test('ignores blank and malformed entries', () {
      expect(MediaItem.parse(['', '   ', {'url': ''}]), isEmpty);
      expect(MediaItem.parse('not a list'), isEmpty);
    });
  });

  group('ProfileExtras.from', () {
    test('reads snake_case and camelCase alike', () {
      final a = ProfileExtras.from({
        'social_links': {'instagram': '@x'},
        'brand_work': [{'brand': 'Nykaa'}],
        'past_work': [{'title': 'Campaign'}],
        'awards': [{'title': 'Best Newcomer'}],
      });
      expect(a.socials, hasLength(1));
      expect(a.brands, hasLength(1));
      expect(a.projects, hasLength(1));
      expect(a.awards, hasLength(1));

      final b = ProfileExtras.from({
        'socialLinks': {'instagram': '@x'},
        'brandWork': [{'brand': 'Nykaa'}],
        'pastWork': [{'title': 'Campaign'}],
      });
      expect(b.socials, hasLength(1));
      expect(b.brands, hasLength(1));
      expect(b.projects, hasLength(1));
    });

    test('an empty payload is empty, not an error', () {
      expect(ProfileExtras.from({}).isEmpty, isTrue);
    });

    test('drops records missing their identifying field', () {
      final e = ProfileExtras.from({
        'awards': [{'issuer': 'no title here'}],
        'brand_work': [{'work': 'no brand here'}],
        'past_work': [{'client': 'no title here'}],
      });
      expect(e.awards, isEmpty);
      expect(e.brands, isEmpty);
      expect(e.projects, isEmpty);
    });
  });
}
