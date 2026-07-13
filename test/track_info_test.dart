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
        'name': 'this is what ___ feels like',
        'release_date': '2022-09-23',
      },
    };

Map<String, dynamic> _artist() => {
      'genres': ['pop', 'viral pop'],
      'followers': {'total': 1234567},
    };

void main() {
  group('TrackInfo.fromJson', () {
    test('reads the full Spotify track shape', () {
      final info = TrackInfo.fromJson(_track(), artistJson: _artist());
      expect(info.title, 'Golden Hour');
      expect(info.artistsLine, 'JVKE, Ruel');
      expect(info.albumName, 'this is what ___ feels like');
      expect(info.releaseYear, '2022');
      expect(info.durationMs, 209000);
      expect(info.trackNumber, 3);
      expect(info.explicit, isTrue);
      expect(info.popularity, 87);
      expect(info.genres, ['pop', 'viral pop']);
      expect(info.artistFollowers, 1234567);
    });

    test('survives a missing artist payload and sparse fields', () {
      final info = TrackInfo.fromJson({'name': 'X'});
      expect(info.title, 'X');
      expect(info.artistsLine, '');
      expect(info.releaseYear, '');
      expect(info.explicit, isFalse);
      expect(info.popularity, 0);
      expect(info.genres, isEmpty);
      expect(info.artistFollowers, isNull);
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
