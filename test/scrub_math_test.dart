import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/utils/scrub_math.dart';

void main() {
  group('ScrubMath.positionAfterDrag', () {
    test('dragging across the full cassette width travels the whole tape', () {
      expect(
        ScrubMath.positionAfterDrag(
            startMs: 0, dragDx: 300, trackWidth: 300, durationMs: 200000),
        200000,
      );
      expect(
        ScrubMath.positionAfterDrag(
            startMs: 100000, dragDx: 150, trackWidth: 300, durationMs: 200000),
        200000,
      );
    });

    test('half a width is half the tape, in either direction', () {
      expect(
        ScrubMath.positionAfterDrag(
            startMs: 0, dragDx: 150, trackWidth: 300, durationMs: 200000),
        100000,
      );
      expect(
        ScrubMath.positionAfterDrag(
            startMs: 150000, dragDx: -75, trackWidth: 300, durationMs: 200000),
        100000,
      );
    });

    test('clamps at both ends of the tape', () {
      expect(
        ScrubMath.positionAfterDrag(
            startMs: 5000, dragDx: -500, trackWidth: 300, durationMs: 200000),
        0,
      );
      expect(
        ScrubMath.positionAfterDrag(
            startMs: 195000, dragDx: 500, trackWidth: 300, durationMs: 200000),
        200000,
      );
    });

    test('degenerate geometry or duration just clamps the start', () {
      expect(
        ScrubMath.positionAfterDrag(
            startMs: 5000, dragDx: 100, trackWidth: 0, durationMs: 200000),
        5000,
      );
      expect(
        ScrubMath.positionAfterDrag(
            startMs: 5000, dragDx: 100, trackWidth: 300, durationMs: 0),
        0,
      );
    });
  });
}
