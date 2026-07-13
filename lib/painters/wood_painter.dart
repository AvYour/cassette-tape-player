import 'package:flutter/material.dart';
import '../utils/wood_grain_spec.dart';

/// Varnished timber, painted with the same care as the cassette painters:
/// a tonal base, seeded grain with occasional dark mineral streaks, a soft
/// varnish sheen across the top, and bevelled edges that catch the light.
/// Deterministic per [seed], so every drawer keeps its own grain forever.
class WoodPainter extends CustomPainter {
  /// Base timber tones. Leave both null to paint only the finish (grain,
  /// sheen, bevels) over a base the widget itself provides — used by the
  /// drawer face, whose base gradient is animated by an AnimatedContainer.
  final Color? light;
  final Color? dark;
  final int seed;

  /// Sheen and bevels suit a raised panel (drawer face). For large carcass
  /// surfaces a calmer finish (no bevel) reads better.
  final bool bevelled;

  const WoodPainter({
    this.light,
    this.dark,
    this.seed = 7,
    this.bevelled = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Tonal base: warm at the top, sinking into shadow at the bottom.
    if (light != null && dark != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [light!, dark!],
          ).createShader(rect),
      );
    }

    // Grain: long wobbling strokes; mineral streaks are darker and warmer.
    final grain = Paint()..style = PaintingStyle.stroke;
    for (final line
        in WoodGrainSpec.generate(seed: seed, height: size.height)) {
      grain
        ..strokeWidth = line.strokeWidth
        ..color = (line.isDark ? const Color(0xFF2A1708) : Colors.black)
            .withValues(alpha: line.alpha);
      final path = Path()
        ..moveTo(0, line.y)
        ..quadraticBezierTo(size.width * 0.28, line.y + line.amplitude,
            size.width * 0.55, line.y - line.amplitude * 0.3)
        ..quadraticBezierTo(size.width * 0.8, line.y - line.amplitude,
            size.width, line.y + line.amplitude * 0.4);
      canvas.drawPath(path, grain);
    }

    // Varnish sheen: a soft light wash falling from the upper left.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.02),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 0.7],
        ).createShader(rect),
    );

    // Grounding: the lowest part of the panel sits in shadow.
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.14)],
        ).createShader(Rect.fromLTWH(
            0, size.height * 0.72, size.width, size.height * 0.28)),
    );

    if (!bevelled) return;

    // Bevels: light catches the top and left arris; the bottom and right
    // edges fall away into shade.
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 1.6),
        Paint()..color = Colors.white.withValues(alpha: 0.20));
    canvas.drawRect(Rect.fromLTWH(0, 0, 1.4, size.height),
        Paint()..color = Colors.white.withValues(alpha: 0.10));
    canvas.drawRect(Rect.fromLTWH(0, size.height - 2.5, size.width, 2.5),
        Paint()..color = Colors.black.withValues(alpha: 0.28));
    canvas.drawRect(Rect.fromLTWH(size.width - 1.4, 0, 1.4, size.height),
        Paint()..color = Colors.black.withValues(alpha: 0.16));
  }

  @override
  bool shouldRepaint(WoodPainter old) =>
      old.light != light ||
      old.dark != dark ||
      old.seed != seed ||
      old.bevelled != bevelled;
}
