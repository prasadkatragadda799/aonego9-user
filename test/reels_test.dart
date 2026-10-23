import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aonego9_user/state/app_state.dart';
import 'package:aonego9_user/widgets/reels_viewer.dart';

/// The reels feed is built from what the app has loaded: artists' photos and
/// videos, with nothing invented when nothing is loaded.
void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Map<String, dynamic> artist(String id, List<String> media) => {
        'id': id,
        'cat': 'modelF',
        'name': 'Artist $id',
        'loc': 'Mumbai',
        'avatarUrl': media.isEmpty ? '' : media.first,
        'galleryUrls': media.skip(1).toList(),
      };

  test('no loaded content means no reels', () {
    expect(buildReels(AppState()), isEmpty);
  });

  test('each artist contributes up to three reels, videos detected by extension', () {
    final app = AppState()
      ..debugSetListings([
        artist('a', ['a1.jpg', 'a2.jpg', 'clip.mp4', 'a4.jpg']),
        artist('b', []),
      ]);
    final reels = buildReels(app);
    expect(reels.length, 3);
    expect(reels.every((r) => r.kind == 'artist' && r.profile?['id'] == 'a'), isTrue);
    expect(reels[2].isVideo, isTrue);
    expect(reels[2].videoUrl, 'clip.mp4');
    expect(reels.first.subtitle, 'Female Models  ·  Mumbai');
  });

  test('a repeated photo is shown once', () {
    final app = AppState()..debugSetListings([artist('c', ['same.jpg', 'same.jpg'])]);
    expect(buildReels(app).length, 1);
  });
}
