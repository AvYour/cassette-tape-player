import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/utils/image_pick.dart';

void main() {
  // Spotify returns album images largest-first, each with width/height.
  final spotify = [
    {'url': 'big', 'width': 640, 'height': 640},
    {'url': 'mid', 'width': 300, 'height': 300},
    {'url': 'small', 'width': 64, 'height': 64},
  ];

  group('ImagePick.bestUrl', () {
    test('picks the smallest image at least as wide as the target', () {
      expect(ImagePick.bestUrl(spotify, targetWidth: 128), 'mid');
      expect(ImagePick.bestUrl(spotify, targetWidth: 300), 'mid');
      expect(ImagePick.bestUrl(spotify, targetWidth: 50), 'small');
    });

    test('falls back to the largest when none is wide enough', () {
      expect(ImagePick.bestUrl(spotify, targetWidth: 700), 'big');
    });

    test('returns null for an empty or urlless list', () {
      expect(ImagePick.bestUrl(const [], targetWidth: 100), isNull);
      expect(
          ImagePick.bestUrl([
            {'width': 100}
          ], targetWidth: 50),
          isNull);
    });

    test('uses the first usable url when widths are missing', () {
      final noWidths = [
        {'url': 'a'},
        {'url': 'b'},
      ];
      expect(ImagePick.bestUrl(noWidths, targetWidth: 100), 'a');
    });

    test('ignores malformed entries but still finds a valid one', () {
      final messy = [
        'not-a-map',
        {'url': 'ok', 'width': 300},
      ];
      expect(ImagePick.bestUrl(messy, targetWidth: 128), 'ok');
    });
  });
}
