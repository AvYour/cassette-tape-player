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
}
