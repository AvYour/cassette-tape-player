import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/utils/tape_wind.dart';

void main() {
  const e = TapeWind.emptyFraction;

  group('TapeWind pack radii', () {
    test('starts full on the left, empty on the right', () {
      expect(TapeWind.leftRadiusFraction(0), closeTo(1.0, 1e-9));
      expect(TapeWind.rightRadiusFraction(0), closeTo(e, 1e-9));
    });

    test('ends empty on the left, full on the right', () {
      expect(TapeWind.leftRadiusFraction(1), closeTo(e, 1e-9));
      expect(TapeWind.rightRadiusFraction(1), closeTo(1.0, 1e-9));
    });

    test('conserves tape: the pack areas always sum to the same total', () {
      const total = 1 + e * e;
      for (double p = 0; p <= 1; p += 0.1) {
        final l = TapeWind.leftRadiusFraction(p);
        final r = TapeWind.rightRadiusFraction(p);
        expect(l * l + r * r, closeTo(total, 1e-9), reason: 'p=$p');
      }
    });

    test('winds monotonically and clamps silly progress values', () {
      double prevL = 2, prevR = 0;
      for (double p = 0; p <= 1; p += 0.05) {
        final l = TapeWind.leftRadiusFraction(p);
        final r = TapeWind.rightRadiusFraction(p);
        expect(l, lessThan(prevL));
        expect(r, greaterThan(prevR));
        prevL = l;
        prevR = r;
      }
      expect(TapeWind.leftRadiusFraction(-3), closeTo(1.0, 1e-9));
      expect(TapeWind.leftRadiusFraction(9), closeTo(e, 1e-9));
    });
  });

  group('TapeWind.hubSpeed', () {
    test('an emptying pack spins up; a filling pack slows down', () {
      // Take-up hub: fast when empty (start), slower once full.
      final startRight = TapeWind.hubSpeed(TapeWind.rightRadiusFraction(0));
      final endRight = TapeWind.hubSpeed(TapeWind.rightRadiusFraction(1));
      expect(startRight, greaterThan(endRight));
      // At a full pack the speed factor is the base linear speed.
      expect(TapeWind.hubSpeed(1.0), closeTo(e, 1e-9));
    });
  });

  group('TapeWind counter & clock', () {
    test('the mechanical counter rolls forward and wraps at 9999', () {
      expect(TapeWind.counterDigits(0), '0000');
      expect(TapeWind.counterDigits(750), '0001');
      expect(TapeWind.counterDigits(7500), '0010');
      expect(TapeWind.counterDigits(750 * 10000), '0000');
    });

    test('the clock formats minutes and seconds', () {
      expect(TapeWind.clock(0), '00:00');
      expect(TapeWind.clock(61000), '01:01');
      expect(TapeWind.clock(754000), '12:34');
    });
  });
}
