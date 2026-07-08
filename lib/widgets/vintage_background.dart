import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// Warm radial background with vignette (reference `vintageBackground`).
class VintageBackground extends StatelessWidget {
  final Widget child;

  const VintageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _VintageBackgroundPainter(),
      child: child,
    );
  }
}

class _VintageBackgroundPainter extends CustomPainter {
  const _VintageBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final maxDim = math.max(size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.5, size.height * 0.3),
          maxDim * 0.85,
          const [kBgCenter, kBgEdge],
        ),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          rect.center,
          maxDim * 0.8,
          const [Colors.transparent, kBgVignette],
        ),
    );
  }

  @override
  bool shouldRepaint(_VintageBackgroundPainter old) => false;
}
