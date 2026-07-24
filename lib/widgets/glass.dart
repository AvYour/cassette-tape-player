import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../utils/explore_theme.dart';

/// A frosted pane: blurs whatever sits behind it, tints it white, and catches
/// a highlight along its top edge.
///
/// Glass only reads as glass when there is something behind it to refract, so
/// pair these with [GlassBackdrop] rather than a flat fill — over a plain
/// colour a blur has nothing to do and the pane just looks like a white box.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;

  /// How milky the pane is. Lower lets more of the backdrop through.
  final double fill;

  final EdgeInsetsGeometry? padding;
  final bool shadow;

  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 28,
    this.blur = 18,
    this.fill = 0.55,
    this.padding,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: border,
        boxShadow: shadow ? Explore.lift : null,
      ),
      child: ClipRRect(
        borderRadius: border,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: border,
              // A touch brighter at the top, as light catches the near edge.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: fill + 0.16),
                  Colors.white.withValues(alpha: fill - 0.08),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The room behind the glass: the lavender gradient with a few wide, soft
/// colour blooms in it. They are what the panes blur and bend, and they are
/// deliberately pale — enough to give the glass something to hold, not enough
/// to compete with the type.
class GlassBackdrop extends StatelessWidget {
  final Widget child;

  /// Pulls the blooms toward a song's own colours. Null keeps the house tints.
  final Color? tint;

  const GlassBackdrop({super.key, required this.child, this.tint});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: Explore.backdrop),
      child: CustomPaint(
        painter: _BloomPainter(tint: tint),
        child: child,
      ),
    );
  }
}

class _BloomPainter extends CustomPainter {
  final Color? tint;

  const _BloomPainter({this.tint});

  static const List<Color> _house = [
    Color(0xFFB9A8F0), // lavender
    Color(0xFF9EC6F2), // cold blue
    Color(0xFFF2B6C8), // warm rose
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final blooms = [
      (Offset(size.width * 0.18, size.height * 0.16), size.width * 0.55),
      (Offset(size.width * 0.92, size.height * 0.38), size.width * 0.60),
      (Offset(size.width * 0.35, size.height * 0.86), size.width * 0.65),
    ];

    for (var i = 0; i < blooms.length; i++) {
      final (center, radius) = blooms[i];
      final base = tint == null
          ? _house[i]
          : Color.lerp(_house[i], tint, 0.55) ?? _house[i];
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(center, radius, [
            base.withValues(alpha: 0.38),
            base.withValues(alpha: 0.0),
          ]),
      );
    }
  }

  @override
  bool shouldRepaint(_BloomPainter old) => old.tint != tint;
}
