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
}
