import 'dart:math' as math;

/// One horizontal grain line across a wooden panel.
class GrainLine {
  final double y;
  final double amplitude; // vertical wobble of the stroke
  final double alpha; // 0..1 ink strength
  final double strokeWidth;
  final bool isDark; // occasional darker mineral streak

  const GrainLine({
    required this.y,
    required this.amplitude,
    required this.alpha,
    required this.strokeWidth,
    required this.isDark,
  });
}

/// Deterministic wood-grain layout, separated from the painter so the grain's
/// character (spacing, wobble, ink) is unit-testable and stable per seed —
/// every rebuild of a drawer paints the exact same timber.
class WoodGrainSpec {
  const WoodGrainSpec._();

  static List<GrainLine> generate({required int seed, required double height}) {
    final rnd = math.Random(seed);
    final lines = <GrainLine>[];
    double y = 2 + rnd.nextDouble() * 3;
    while (y < height) {
      final isDark = rnd.nextDouble() < 0.12;
      lines.add(GrainLine(
        y: y,
        amplitude: 0.4 + rnd.nextDouble() * 3.1,
        alpha: isDark
            ? 0.10 + rnd.nextDouble() * 0.08
            : 0.02 + rnd.nextDouble() * 0.06,
        strokeWidth: 0.5 + rnd.nextDouble() * 1.1,
        isDark: isDark,
      ));
      y += 3 + rnd.nextDouble() * 4.5;
    }
    return lines;
  }
}
