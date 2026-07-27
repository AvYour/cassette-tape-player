import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/models/track_info.dart';

Map<String, dynamic> _track() => {
      'name': 'Golden Hour',
      'duration_ms': 209000,
      'explicit': true,
      'popularity': 87,
      'track_number': 3,
      'artists': [
        {'id': 'a1', 'name': 'JVKE'},
        {'id': 'a2', 'name': 'Ruel'},
      ],
      'album': {
        'id': 'alb9',
        'name': 'this is what ___ feels like',
        'release_date': '2022-09-23',
      },
    };

void main() {
  group('TrackInfo.fromJson', () {
    test('reads the full Spotify track shape', () {
      final info = TrackInfo.fromJson(_track());
      expect(info.title, 'Golden Hour');
      expect(info.artistsLine, 'JVKE, Ruel');
      expect(info.albumName, 'this is what ___ feels like');
      expect(info.releaseYear, '2022');
      expect(info.durationMs, 209000);
      expect(info.trackNumber, 3);
      expect(info.explicit, isTrue);
      expect(info.popularity, 87);
    });

    test('keeps the ids the liner notes need to walk into', () {
      final info = TrackInfo.fromJson(_track());
      // The primary artist, so tapping the name opens the right page.
      expect(info.artistId, 'a1');
      expect(info.albumId, 'alb9');
    });

    test('a track with no artist or album ids offers nothing to tap', () {
      final info = TrackInfo.fromJson({
        'name': 'X',
        'artists': [
          {'name': 'No Id'}
        ],
        'album': {'name': 'No Id Album'},
      });
      expect(info.artistId, isNull);
      expect(info.albumId, isNull);
    });

    test('survives a missing artist payload and sparse fields', () {
      final info = TrackInfo.fromJson({'name': 'X'});
      expect(info.title, 'X');
      expect(info.artistsLine, '');
      expect(info.releaseYear, '');
      expect(info.explicit, isFalse);
      expect(info.popularity, 0);
      expect(info.artistId, isNull);
      expect(info.albumId, isNull);
    });
  });

  group('TrackInfo popularity shapes', () {
    test('reads a popularity nested under stats (moved-field APIs)', () {
      final t = _track()
        ..remove('popularity')
        ..['stats'] = {'popularity': 64};
      expect(TrackInfo.fromJson(t).popularity, 64);
    });

    test('reads a string-typed popularity', () {
      final t = _track()..['popularity'] = '73';
      expect(TrackInfo.fromJson(t).popularity, 73);
    });

    test('reads a popularity_index fallback', () {
      final t = _track()
        ..remove('popularity')
        ..['popularity_index'] = 55;
      expect(TrackInfo.fromJson(t).popularity, 55);
    });

    test('a zero canonical popularity stays zero (no invention)', () {
      final t = _track()..['popularity'] = 0;
      expect(TrackInfo.fromJson(t).popularity, 0);
    });
  });

  group('TrackInfo.formatCount', () {
    test('groups thousands with separators', () {
      expect(TrackInfo.formatCount(0), '0');
      expect(TrackInfo.formatCount(999), '999');
      expect(TrackInfo.formatCount(1234), '1,234');
      expect(TrackInfo.formatCount(1234567), '1,234,567');
    });
  });
}
