import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/widgets/lyrics_view.dart';

void main() {
  // The reel draws line i at centerY + (i - progress) * lineHeight, so a tap
  // has to be read back through the same arithmetic.
  group('LyricsHit.lineAt', () {
    test('a tap on the middle of the reel picks the active line', () {
      expect(
        LyricsHit.lineAt(dy: 100, height: 200, progress: 7),
        7,
      );
    });

    test('a tap one line below picks the next line', () {
      expect(
        LyricsHit.lineAt(dy: 150, height: 200, progress: 7, lineHeight: 50),
        8,
      );
    });

    test('a tap above the middle picks an earlier line', () {
      expect(
        LyricsHit.lineAt(dy: 50, height: 200, progress: 7, lineHeight: 50),
        6,
      );
    });

    test('rounds to the nearest line rather than truncating', () {
      // 24px below centre is less than half a 50px line, so it stays put.
      expect(
        LyricsHit.lineAt(dy: 124, height: 200, progress: 3, lineHeight: 50),
        3,
      );
      // 26px below is past the halfway mark, so it rolls to the next.
      expect(
        LyricsHit.lineAt(dy: 126, height: 200, progress: 3, lineHeight: 50),
        4,
      );
    });

    test('a fractional progress still lands on a whole line', () {
      final line =
          LyricsHit.lineAt(dy: 100, height: 200, progress: 7.4, lineHeight: 50);
      expect(line, 7);
    });

    test('can return a line outside the lyric list, for the caller to reject',
        () {
      expect(
        LyricsHit.lineAt(dy: 0, height: 200, progress: 0, lineHeight: 50),
        -2,
      );
    });

    test('a degenerate line height does not divide by zero', () {
      expect(LyricsHit.lineAt(dy: 100, height: 200, progress: 5, lineHeight: 0),
          5);
    });
  });
}
