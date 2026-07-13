import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/models/playlist.dart';

void main() {
  group('Playlist.demo', () {
    test('is a ready-to-open drawer with the five built-in tapes', () {
      final demo = Playlist.demo();
      expect(demo.tapes, isNotNull);
      expect(demo.tapes!.length, 5);
      expect(demo.loading, isFalse);
      expect(demo.loadError, isNull);
      expect(demo.trackCount, 5);
    });

    test('its tapes carry real Spotify URIs so they play when connected', () {
      final demo = Playlist.demo();
      for (final tape in demo.tapes!) {
        expect(tape.spotifyUri, startsWith('spotify:track:'),
            reason: tape.trackName);
      }
    });

    test('has a stable identity distinct from Spotify playlists', () {
      expect(Playlist.demo().id, 'demo');
      expect(Playlist.demo().name.toLowerCase(), contains('mixtape'));
    });
  });
}
