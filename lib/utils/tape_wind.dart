import 'dart:math' as math;

/// The physics of tape winding between two reels, plus the deck's mechanical
/// counter/clock — pure maths, shared by the cassette painter and the player.
///
/// Tape length (pack AREA) is conserved: as the song progresses the supply
/// pack's area drains linearly into the take-up pack, so the RADII follow a
/// square root, exactly like a real cassette.
class TapeWind {
  const TapeWind._();

  /// Empty-hub pack radius as a fraction of a full pack (matches the
  /// painter's classic 0.12 / 0.23 proportions).
  static const double emptyFraction = 0.12 / 0.23;

  static double _clamp(double p) => p.clamp(0.0, 1.0);

  /// Supply (left) pack radius fraction at [progress] 0..1: full → empty.
  static double leftRadiusFraction(double progress) {
    const e2 = emptyFraction * emptyFraction;
    return math.sqrt(1 - (1 - e2) * _clamp(progress));
  }

  /// Take-up (right) pack radius fraction at [progress] 0..1: empty → full.
  static double rightRadiusFraction(double progress) {
    const e2 = emptyFraction * emptyFraction;
    return math.sqrt(e2 + (1 - e2) * _clamp(progress));
  }

  /// Angular-speed factor for a hub whose pack currently has
  /// [radiusFraction]: linear tape speed is constant, so a slim pack spins
  /// fast and a fat one slow. Normalized so a FULL pack turns at
  /// [emptyFraction] × base — matching the classic lead ratio.
  static double hubSpeed(double radiusFraction) =>
      emptyFraction / radiusFraction.clamp(emptyFraction, 1.0);

  /// The deck's mechanical counter: one count per ~0.75s of tape, rolling
  /// over after 9999 like a real four-digit odometer.
  static String counterDigits(int positionMs) {
    final count = (positionMs ~/ 750) % 10000;
    return count.toString().padLeft(4, '0');
  }

  /// mm:ss for LCD readouts.
  static String clock(int ms) {
    final s = ms ~/ 1000;
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
