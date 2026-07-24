import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/models/playlist.dart';

void main() {
  group('Playlist kinds', () {
    test('a real Spotify playlist still carries its context URI', () {
      final pl = Playlist.fromJson({
        'id': 'p1',
        'name': 'Road Trip',
        'owner': {'display_name': 'Rel', 'id': 'u1'},
      }, 0);
      expect(pl.kind, PlaylistKind.spotify);
      expect(pl.contextUri, 'spotify:playlist:p1');
    });

    test('Liked Songs is its own kind, not a playlist id', () {
      final liked = Playlist.liked(total: 412);
      expect(liked.kind, PlaylistKind.liked);
      expect(liked.name, 'Liked Songs');
      expect(liked.trackCount, 412);
      // There is no playlist behind it, so there is no context to play.
      expect(liked.contextUri, isNull);
      expect(liked.imageUrl, isNull);
    });

    test('Recently Played is its own kind with no known length', () {
      final recent = Playlist.recentlyPlayed();
      expect(recent.kind, PlaylistKind.recent);
      expect(recent.name, 'Recently Played');
      expect(recent.contextUri, isNull);
    });

    test('the demo mixtape no longer claims a bogus playlist context', () {
      final demo = Playlist.demo();
      expect(demo.kind, PlaylistKind.demo);
      // It used to return 'spotify:playlist:demo', which is not a real URI.
      expect(demo.contextUri, isNull);
      expect(demo.tapes, isNotEmpty);
    });
  });
}
