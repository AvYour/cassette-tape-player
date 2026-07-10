import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/services/lyrics_service.dart';

void main() {
  group('LyricsService.cacheKey', () {
    test('is case- and whitespace-insensitive', () {
      final a = LyricsService.cacheKey(
          track: 'Dreams', artist: 'Fleetwood Mac', durationMs: 257000);
      final b = LyricsService.cacheKey(
          track: '  dreams ', artist: 'FLEETWOOD MAC', durationMs: 257400);
      expect(a, b, reason: 'trim/lowercase + second-resolution duration match');
    });

    test('distinguishes different tracks and artists', () {
      final base = LyricsService.cacheKey(track: 'A', artist: 'X');
      expect(base == LyricsService.cacheKey(track: 'B', artist: 'X'), isFalse);
      expect(base == LyricsService.cacheKey(track: 'A', artist: 'Y'), isFalse);
    });

    test('duration difference under one second does not change the key', () {
      final a = LyricsService.cacheKey(
          track: 'A', artist: 'X', durationMs: 200100);
      final b = LyricsService.cacheKey(
          track: 'A', artist: 'X', durationMs: 200900);
      expect(a, b);
    });
  });
}
