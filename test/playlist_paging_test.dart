import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/utils/playlist_paging.dart';

// Minimal Spotify "/items" entries: each has an `item` holding the track.
Map<String, dynamic> _entry(String id, {String type = 'track'}) => {
      'item': {
        'id': id,
        'type': type,
        'uri': 'spotify:track:$id',
        'name': id,
        'artists': [
          {'name': 'A'}
        ],
        'album': {'images': []},
      }
    };

void main() {
  group('PlaylistPaging.tapesFromPage', () {
    test('assigns contextIndex by playlist position, not filtered position', () {
      // Position 1 (episode) is filtered out; JVKE at playlist position 2 must
      // keep contextIndex 2, not collapse to 1.
      final items = [
        _entry('song0'),
        _entry('pod', type: 'episode'),
        _entry('jvke'),
      ];
      final tapes = PlaylistPaging.tapesFromPage(items, pageOffset: 0);

      expect(tapes.map((t) => t.id), ['song0', 'jvke']);
      expect(tapes[0].contextIndex, 0);
      expect(tapes[1].contextIndex, 2,
          reason: 'JVKE is the 3rd playlist entry (index 2)');
    });

    test('applies the page offset to positions', () {
      final items = [_entry('a'), _entry('b')];
      final tapes = PlaylistPaging.tapesFromPage(items, pageOffset: 50);
      expect(tapes.map((t) => t.contextIndex), [50, 51]);
    });

    test('skips null-id and non-map entries without shifting positions', () {
      final items = [
        _entry('a'),
        {'item': null},
        'garbage',
        _entry('b'),
      ];
      final tapes = PlaylistPaging.tapesFromPage(items, pageOffset: 0);
      expect(tapes.map((t) => t.id), ['a', 'b']);
      expect(tapes.map((t) => t.contextIndex), [0, 3]);
    });

    test('drops tracks Spotify marks unplayable, keeping positions intact', () {
      final items = [
        _entry('a'),
        {
          'item': {
            'id': 'gone',
            'type': 'track',
            'is_playable': false,
            'uri': 'spotify:track:gone',
            'name': 'gone',
            'artists': [
              {'name': 'A'}
            ],
            'album': {'images': []},
          }
        },
        _entry('c'),
      ];
      final tapes = PlaylistPaging.tapesFromPage(items, pageOffset: 0);
      expect(tapes.map((t) => t.id), ['a', 'c']);
      // 'c' is still the 3rd playlist entry even though 'gone' was dropped.
      expect(tapes.last.contextIndex, 2);
    });

    test('parses a /me/tracks saved-tracks page (track nested under `track`)',
        () {
      final saved = [
        {
          'added_at': '2026-01-02T03:04:05Z',
          'track': {
            'id': 'liked1',
            'type': 'track',
            'uri': 'spotify:track:liked1',
            'name': 'Liked One',
            'artists': [
              {'name': 'A'}
            ],
            'album': {'images': []},
          }
        },
      ];
      final tapes = PlaylistPaging.tapesFromPage(saved, pageOffset: 0);
      expect(tapes.single.id, 'liked1');
      expect(tapes.single.trackName, 'Liked One');
    });

    test('reads the legacy `track` field when `item` is absent', () {
      final legacy = [
        {
          'track': {
            'id': 'x',
            'type': 'track',
            'uri': 'spotify:track:x',
            'name': 'x',
            'artists': [
              {'name': 'A'}
            ],
            'album': {'images': []},
          }
        }
      ];
      final tapes = PlaylistPaging.tapesFromPage(legacy, pageOffset: 0);
      expect(tapes.single.id, 'x');
      expect(tapes.single.contextIndex, 0);
    });
  });

  group('PlaylistPaging.dedupeById', () {
    // Recently-played is a play history, not a set: replay the same song three
    // times and it comes back three times.
    test('keeps the first occurrence of each track, in order', () {
      final tapes = PlaylistPaging.tapesFromPage([
        _entry('a'),
        _entry('b'),
        _entry('a'),
        _entry('c'),
        _entry('b'),
      ], pageOffset: 0);

      final deduped = PlaylistPaging.dedupeById(tapes);
      expect(deduped.map((t) => t.id), ['a', 'b', 'c']);
    });

    test('leaves an already-unique list untouched', () {
      final tapes =
          PlaylistPaging.tapesFromPage([_entry('a'), _entry('b')], pageOffset: 0);
      expect(PlaylistPaging.dedupeById(tapes).length, 2);
    });

    test('handles an empty list', () {
      expect(PlaylistPaging.dedupeById(const []), isEmpty);
    });
  });
}
