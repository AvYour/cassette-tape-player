import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/utils/carousel_math.dart';

void main() {
  group('CarouselMath.scale', () {
    test('the focused row is full size', () {
      expect(CarouselMath.scale(0), 1.0);
    });

    test('rows shrink the further they sit from the focus', () {
      expect(CarouselMath.scale(1), lessThan(CarouselMath.scale(0)));
      expect(CarouselMath.scale(2), lessThan(CarouselMath.scale(1)));
    });

    test('is symmetric above and below the focus', () {
      expect(CarouselMath.scale(-2), CarouselMath.scale(2));
    });

    test('never collapses to nothing', () {
      expect(CarouselMath.scale(99), greaterThanOrEqualTo(0.5));
    });
  });

  group('CarouselMath.opacity', () {
    test('the focused row is fully opaque', () {
      expect(CarouselMath.opacity(0), 1.0);
    });

    test('fades out with distance and is symmetric', () {
      expect(CarouselMath.opacity(1), lessThan(1.0));
      expect(CarouselMath.opacity(-1), CarouselMath.opacity(1));
      expect(CarouselMath.opacity(2), lessThan(CarouselMath.opacity(1)));
    });

    test('stays a legal alpha far off screen', () {
      expect(CarouselMath.opacity(99), 0.0);
      expect(CarouselMath.opacity(-99), 0.0);
    });
  });

  group('CarouselMath.shiftX', () {
    test('the focused row sits at the left edge, unshifted', () {
      expect(CarouselMath.shiftX(0), 0.0);
    });

    test('distant rows drift further right, in both directions', () {
      expect(CarouselMath.shiftX(1), greaterThan(0));
      expect(CarouselMath.shiftX(2), greaterThan(CarouselMath.shiftX(1)));
      expect(CarouselMath.shiftX(-2), CarouselMath.shiftX(2));
    });

    test('the drift is capped at maxShift', () {
      expect(CarouselMath.shiftX(99, maxShift: 80), 80.0);
    });
  });

  group('CarouselMath.focusedIndex', () {
    test('snaps to the nearest row', () {
      expect(CarouselMath.focusedIndex(0, 100, 5), 0);
      expect(CarouselMath.focusedIndex(140, 100, 5), 1);
      expect(CarouselMath.focusedIndex(160, 100, 5), 2);
    });

    test('clamps to the ends of the list', () {
      expect(CarouselMath.focusedIndex(-500, 100, 5), 0);
      expect(CarouselMath.focusedIndex(9000, 100, 5), 4);
    });

    test('survives a degenerate extent or an empty list', () {
      expect(CarouselMath.focusedIndex(200, 0, 5), 0);
      expect(CarouselMath.focusedIndex(200, 100, 0), 0);
    });
  });
}
