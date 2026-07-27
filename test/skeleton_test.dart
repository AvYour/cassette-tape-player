import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/widgets/skeleton.dart';

void main() {
  group('SkeletonShimmer.bandCenter', () {
    test('sweeps from off the left edge to off the right', () {
      // The highlight starts before the box and ends past it, so the box is
      // never left with a band parked inside it at rest.
      expect(SkeletonShimmer.bandCenter(0), lessThan(0));
      expect(SkeletonShimmer.bandCenter(1), greaterThan(1));
    });

    test('advances monotonically across the sweep', () {
      var previous = SkeletonShimmer.bandCenter(0);
      for (var i = 1; i <= 10; i++) {
        final next = SkeletonShimmer.bandCenter(i / 10);
        expect(next, greaterThan(previous));
        previous = next;
      }
    });

    test('crosses the middle of the box halfway through', () {
      expect(SkeletonShimmer.bandCenter(0.5), closeTo(0.5, 0.001));
    });

    test('clamps silly progress values instead of running off', () {
      expect(SkeletonShimmer.bandCenter(-5),
          equals(SkeletonShimmer.bandCenter(0)));
      expect(SkeletonShimmer.bandCenter(5),
          equals(SkeletonShimmer.bandCenter(1)));
    });
  });

  group('SkeletonShimmer.stops', () {
    test('gives three ordered stops around the band', () {
      final stops = SkeletonShimmer.stops(0.5);
      expect(stops.length, 3);
      expect(stops[0], lessThan(stops[1]));
      expect(stops[1], lessThan(stops[2]));
    });

    test('every stop stays a legal gradient position', () {
      for (var i = 0; i <= 10; i++) {
        for (final s in SkeletonShimmer.stops(i / 10)) {
          expect(s, inInclusiveRange(0.0, 1.0));
        }
      }
    });
  });
}
