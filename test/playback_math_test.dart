import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/utils/playback_math.dart';

void main() {
  group('lyricLineIndex (synced)', () {
    final times = [0, 1000, 2000, 5000];

    test('returns 0 before the first timestamp advances', () {
      expect(PlaybackMath.lyricLineIndex(times, 0), 0);
      expect(PlaybackMath.lyricLineIndex(times, 999), 0);
    });

    test('advances at each timestamp boundary', () {
      expect(PlaybackMath.lyricLineIndex(times, 1000), 1);
      expect(PlaybackMath.lyricLineIndex(times, 1999), 1);
      expect(PlaybackMath.lyricLineIndex(times, 2000), 2);
      expect(PlaybackMath.lyricLineIndex(times, 5000), 3);
      expect(PlaybackMath.lyricLineIndex(times, 999999), 3);
    });

    test('honours a valid hint without changing the result', () {
      // Scanning forward from a hint must give the same answer as from 0.
      for (final pos in [0, 500, 1000, 1500, 3000, 6000]) {
        final fromZero = PlaybackMath.lyricLineIndex(times, pos);
        final fromHint = PlaybackMath.lyricLineIndex(times, pos, hint: 2);
        expect(fromHint, fromZero, reason: 'pos=$pos');
      }
    });

    test('an out-of-range hint is clamped, not crashing', () {
      expect(PlaybackMath.lyricLineIndex(times, 3000, hint: 999), 2);
      expect(PlaybackMath.lyricLineIndex(times, 3000, hint: -5), 2);
    });
  });

  group('lyricProgress', () {
    test('synced: interpolates fractionally between two lines', () {
      final times = [0, 1000, 2000];
      // Halfway between line 0 (t=0) and line 1 (t=1000).
      expect(PlaybackMath.lyricProgress(500, times, 3, 3000), closeTo(0.5, 1e-9));
      // Exactly on line 1.
      expect(PlaybackMath.lyricProgress(1000, times, 3, 3000), closeTo(1.0, 1e-9));
    });

    test('synced: clamps to the last line', () {
      final times = [0, 1000, 2000];
      expect(PlaybackMath.lyricProgress(9000, times, 3, 3000), closeTo(2.0, 1e-9));
    });

    test('unsynced: proportional to duration', () {
      // No times → spread the lines evenly across the duration.
      expect(PlaybackMath.lyricProgress(0, null, 5, 4000), closeTo(0.0, 1e-9));
      expect(PlaybackMath.lyricProgress(2000, null, 5, 4000), closeTo(2.0, 1e-9));
      expect(PlaybackMath.lyricProgress(4000, null, 5, 4000), closeTo(4.0, 1e-9));
    });

    test('degenerate inputs never throw or exceed bounds', () {
      expect(PlaybackMath.lyricProgress(1000, null, 0, 3000), 0.0);
      expect(PlaybackMath.lyricProgress(1000, null, 1, 0), 0.0);
      // times length != lineCount is treated as unsynced (proportional).
      expect(PlaybackMath.lyricProgress(1000, [0, 1000], 3, 3000),
          closeTo(1000 / 3000 * 2, 1e-9));
    });
  });

  group('reachedEnd', () {
    test('true only within the tail of a track of real length', () {
      expect(PlaybackMath.reachedEnd(210000, 210000), isTrue);
      expect(PlaybackMath.reachedEnd(209800, 210000), isTrue); // within 250ms
      expect(PlaybackMath.reachedEnd(209000, 210000), isFalse);
      expect(PlaybackMath.reachedEnd(0, 210000), isFalse);
    });

    test('ignores zero/short durations to avoid false advances', () {
      expect(PlaybackMath.reachedEnd(0, 0), isFalse);
      expect(PlaybackMath.reachedEnd(500, 500), isFalse);
    });
  });

  group('shouldReanchorPoll', () {
    final t0 = DateTime(2026, 1, 1, 12, 0, 0);
    DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

    test('polls once the interval has elapsed and we are past the guard', () {
      // last poll at 0, guard ended at 0, now at 3500 → poll.
      expect(
          PlaybackMath.shouldReanchorPoll(
              now: at(3500), lastPoll: t0, ignoreUntil: t0),
          isTrue);
    });

    test('does not poll before the interval elapses', () {
      expect(
          PlaybackMath.shouldReanchorPoll(
              now: at(2000), lastPoll: t0, ignoreUntil: t0),
          isFalse);
    });

    test('does not poll while inside the just-switched guard window', () {
      // Interval satisfied, but the guard (a self-driven track change) is still
      // active — polling now would anchor to the OLD track's stale position.
      expect(
          PlaybackMath.shouldReanchorPoll(
              now: at(3500), lastPoll: t0, ignoreUntil: at(4000)),
          isFalse);
    });
  });

  group('interpolatePosition', () {
    test('adds wall-clock elapsed to the anchor, clamped to duration', () {
      expect(PlaybackMath.interpolatePosition(1000, 500, 200000), 1500);
      expect(PlaybackMath.interpolatePosition(199900, 500, 200000), 200000);
      expect(PlaybackMath.interpolatePosition(-100, -50, 200000), 0);
    });
  });
}
