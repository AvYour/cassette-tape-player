import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/models/browse.dart';

void main() {
  group('AlbumBrief.fromJson', () {
    Map<String, dynamic> album() => {
          'id': 'alb1',
          'name': 'Testing',
          'artists': [
            {'name': 'A\$AP Rocky'}
          ],
          'images': [
            {'url': 'https://i.scdn.co/big', 'width': 640},
            {'url': 'https://i.scdn.co/mid', 'width': 300},
          ],
        };

    test('reads name, first artist, and a thumbnail-sized cover', () {
      final a = AlbumBrief.fromJson(album());
      expect(a.id, 'alb1');
      expect(a.name, 'Testing');
      expect(a.artistName, 'A\$AP Rocky');
      expect(a.imageUrl, 'https://i.scdn.co/mid');
      expect(a.contextUri, 'spotify:album:alb1');
    });

    test('survives missing artists and images', () {
      final a = AlbumBrief.fromJson({'id': 'x', 'name': 'Solo'});
      expect(a.artistName, '');
      expect(a.imageUrl, isNull);
    });
  });

  group('ArtistBrief.fromJson', () {
    test('reads name and image', () {
      final a = ArtistBrief.fromJson({
        'id': 'art1',
        'name': 'XG',
        'images': [
          {'url': 'https://i.scdn.co/a', 'width': 320}
        ],
      });
      expect(a.id, 'art1');
      expect(a.name, 'XG');
      expect(a.imageUrl, 'https://i.scdn.co/a');
    });
  });

  group('SearchResults.fromJson', () {
    test('pulls tracks, artists and albums out of one search payload', () {
      final results = SearchResults.fromJson({
        'tracks': {
          'items': [
            {
              'id': 't1',
              'name': 'Song',
              'uri': 'spotify:track:t1',
              'artists': [
                {'name': 'A'}
              ],
              'album': {'images': []},
            }
          ]
        },
        'artists': {
          'items': [
            {'id': 'a1', 'name': 'Artist', 'images': []}
          ]
        },
        'albums': {
          'items': [
            {
              'id': 'al1',
              'name': 'Album',
              'artists': [
                {'name': 'A'}
              ],
              'images': [],
            }
          ]
        },
      });
      expect(results.tracks.single.trackName, 'Song');
      expect(results.artists.single.name, 'Artist');
      expect(results.albums.single.name, 'Album');
      expect(results.isEmpty, isFalse);
    });

    test('an empty payload is empty, not a crash', () {
      final results = SearchResults.fromJson({});
      expect(results.tracks, isEmpty);
      expect(results.artists, isEmpty);
      expect(results.albums, isEmpty);
      expect(results.isEmpty, isTrue);
    });

    test('skips malformed artist and album entries', () {
      final results = SearchResults.fromJson({
        'artists': {
          'items': [
            'garbage',
            {'no_id': true},
            {'id': 'ok', 'name': 'Fine', 'images': []},
          ]
        },
      });
      expect(results.artists.map((a) => a.id), ['ok']);
    });
  });

  group('BrowseParsing.albumTapes', () {
    // GET /albums/{id} nests its tracks under tracks.items as *simplified*
    // tracks with no album of their own — the cover has to be borrowed from
    // the album envelope.
    Map<String, dynamic> albumPayload() => {
          'id': 'alb1',
          'name': 'Testing',
          'release_date': '2018-05-25',
          'images': [
            {'url': 'https://i.scdn.co/cover', 'width': 640}
          ],
          'artists': [
            {'name': 'A\$AP Rocky'}
          ],
          'tracks': {
            'items': [
              {
                'id': 'trk1',
                'name': 'Distorted Records',
                'uri': 'spotify:track:trk1',
                'duration_ms': 200000,
                'artists': [
                  {'name': 'A\$AP Rocky'}
                ],
              },
              {
                'id': 'trk2',
                'name': 'A\$AP Forever',
                'uri': 'spotify:track:trk2',
                'duration_ms': 300000,
                'artists': [
                  {'name': 'A\$AP Rocky'}
                ],
              },
            ]
          },
        };

    test('turns an album into cassettes that borrow the album cover', () {
      final tapes = BrowseParsing.albumTapes(albumPayload());
      expect(tapes.map((t) => t.trackName),
          ['Distorted Records', 'A\$AP Forever']);
      expect(tapes.first.albumName, 'Testing');
      expect(tapes.first.year, '2018');
      expect(tapes.first.thumbUrl, 'https://i.scdn.co/cover');
    });

    test('an album with no tracks yields nothing rather than throwing', () {
      expect(BrowseParsing.albumTapes({'id': 'x', 'name': 'Empty'}), isEmpty);
    });
  });
}
