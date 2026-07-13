import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/utils/vu_motion.dart';

void main() {
  group('VuMotion.deflection', () {
    test('always stays on the meter (0..1)', () {
      for (double t = 0; t < 30; t += 0.05) {
        final v = VuMotion.deflection(t);
        expect(v, inInclusiveRange(0.0, 1.0), reason: 't=$t');
      }
    });

    test('the needle actually dances — it is not a constant', () {
      final samples = [
        for (double t = 0; t < 5; t += 0.1) VuMotion.deflection(t)
      ];
      final min = samples.reduce((a, b) => a < b ? a : b);
      final max = samples.reduce((a, b) => a > b ? a : b);
      expect(max - min, greaterThan(0.2),
          reason: 'needle should swing noticeably');
    });

    test('a phase offset de-synchronizes the two channels', () {
      var differing = 0;
      for (double t = 0; t < 3; t += 0.1) {
        if ((VuMotion.deflection(t) - VuMotion.deflection(t, phase: 0.9))
                .abs() >
            0.02) {
          differing++;
        }
      }
      expect(differing, greaterThan(10),
          reason: 'left and right meters should not move in lockstep');
    });

    test('is deterministic — same instant, same reading', () {
      expect(VuMotion.deflection(1.234), VuMotion.deflection(1.234));
    });
  });
}
