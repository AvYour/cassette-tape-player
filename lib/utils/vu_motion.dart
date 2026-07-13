import 'dart:math' as math;

/// The dance of a VU meter needle: layered sines at unrelated frequencies so
/// it reads as music rather than a metronome. Pure — deflection is a function
/// of time, so it's deterministic and unit-testable.
class VuMotion {
  const VuMotion._();

  /// Needle deflection 0..1 at [seconds]; [phase] offsets a second channel so
  /// the left and right meters don't move in lockstep.
  static double deflection(double seconds, {double phase = 0}) {
    final t = seconds + phase;
    final v = 0.45 +
        0.18 * math.sin(t * 2.1) +
        0.12 * math.sin(t * 5.3 + 1.7) +
        0.08 * math.sin(t * 9.7 + 0.4) +
        0.06 * math.sin(t * 15.9 + 2.9);
    return v.clamp(0.0, 1.0);
  }
}
