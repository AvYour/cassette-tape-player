import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/widgets/track_row.dart';

void main() {
  group('TrackRow.formatDuration', () {
    test('reads as a track length, minutes unpadded and seconds padded', () {
      expect(TrackRow.formatDuration(259000), '4:19');
      expect(TrackRow.formatDuration(135000), '2:15');
      expect(TrackRow.formatDuration(65000), '1:05');
    });

    test('rounds to the nearest second', () {
      expect(TrackRow.formatDuration(59600), '1:00');
      expect(TrackRow.formatDuration(59400), '0:59');
    });

    test('handles a zero or nonsense duration without crashing', () {
      expect(TrackRow.formatDuration(0), '0:00');
      expect(TrackRow.formatDuration(-5), '0:00');
    });

    test('carries past an hour into minutes rather than inventing hours', () {
      expect(TrackRow.formatDuration(3660000), '61:00');
    });
  });
}
