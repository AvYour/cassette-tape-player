import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/models/playlist.dart';

void main() {
  Map<String, dynamic> base() => {
        'id': 'p1',
        'name': 'Road Trip',
        'owner': {'display_name': 'Rel', 'id': 'u1'},
      };

  group('Playlist.fromJson track totals', () {
    test('reads the classic tracks.total shape', () {
      final pl = Playlist.fromJson({
        ...base(),
        'tracks': {'total': 72},
      }, 0);
      expect(pl.trackCount, 72);
    });

    test('reads the renamed items.total shape (Feb 2026 API)', () {
      final pl = Playlist.fromJson({
        ...base(),
        'items': {'total': 72},
      }, 0);
      expect(pl.trackCount, 72);
    });

    test('reads a flat item_count if that is all there is', () {
      final pl = Playlist.fromJson({
        ...base(),
        'item_count': 72,
      }, 0);
      expect(pl.trackCount, 72);
    });

    test('missing totals default to zero without crashing', () {
      final pl = Playlist.fromJson(base(), 0);
      expect(pl.trackCount, 0);
    });
  });

  group('Playlist.fromJson cover art', () {
    test('picks a cover around thumbnail size for the explore list', () {
      final pl = Playlist.fromJson({
        ...base(),
        'images': [
          {'url': 'https://i.scdn.co/huge', 'width': 640, 'height': 640},
          {'url': 'https://i.scdn.co/mid', 'width': 300, 'height': 300},
          {'url': 'https://i.scdn.co/tiny', 'width': 60, 'height': 60},
        ],
      }, 0);
      expect(pl.imageUrl, 'https://i.scdn.co/mid');
    });

    test('a playlist with no images has no cover, not an empty string', () {
      expect(Playlist.fromJson(base(), 0).imageUrl, isNull);
      expect(Playlist.fromJson({...base(), 'images': []}, 0).imageUrl, isNull);
    });

    test('malformed image entries do not crash the parse', () {
      final pl = Playlist.fromJson({
        ...base(),
        'images': [
          'not-a-map',
          {'no_url': true},
          {'url': 'https://i.scdn.co/ok', 'width': 300},
        ],
      }, 0);
      expect(pl.imageUrl, 'https://i.scdn.co/ok');
    });
  });
}
