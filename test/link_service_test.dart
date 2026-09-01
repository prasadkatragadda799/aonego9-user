import 'package:flutter_test/flutter_test.dart';
import 'package:aonego9_user/services/link_service.dart';

void main() {
  group('LinkService.normalise', () {
    test('adds https to a bare domain', () {
      expect(LinkService.normalise('aonego9.com').toString(), 'https://aonego9.com');
    });

    test('keeps a valid scheme', () {
      expect(LinkService.normalise('http://x.com').toString(), 'http://x.com');
      expect(LinkService.normalise('mailto:a@b.com').toString(), 'mailto:a@b.com');
      expect(LinkService.normalise('tel:+919000000000').toString(), 'tel:+919000000000');
    });

    test('refuses script and other unsafe schemes', () {
      // Profile links are vendor-supplied, so this is the boundary that keeps
      // a hostile value from ever reaching the platform launcher.
      expect(LinkService.normalise('javascript:alert(1)'), isNull);
      expect(LinkService.normalise('data:text/html,<script>'), isNull);
      expect(LinkService.normalise('file:///etc/passwd'), isNull);
    });

    test('refuses a host that is not a domain', () {
      expect(LinkService.normalise('https://localhost'), isNull);
      expect(LinkService.normalise('notaurl'), isNull);
    });

    test('refuses empty input', () {
      expect(LinkService.normalise(''), isNull);
      expect(LinkService.normalise('   '), isNull);
    });
  });
}
