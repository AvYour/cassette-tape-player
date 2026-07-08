import 'dart:math';
import 'package:flutter/material.dart';

/// Draws a single cassette reel: a wound-tape spool (whose radius reflects how
/// much tape is on this side) with a fixed metallic 6-spoke hub on top.
///
/// Modelled after the Jetpack Compose reference: brown radial-gradient spool
/// with concentric "wound tape" rings, a silver hub with bevelled spokes, and
/// a black spindle hole.
class ReelPainter extends CustomPainter {
  /// Hub rotation in radians.
  final double rotation;

  /// Current wound-tape radius (varies with playback progress).
  final double spoolRadius;

  /// Fixed hub radius (never changes as the spool winds/unwinds).
  final double hubRadius;

  const ReelPainter({
    required this.rotation,
    required this.spoolRadius,
    required this.hubRadius,
  });

  static const Color _spoolLight = Color(0xFF523321);
  static const Color _spoolDark = Color(0xFF22140D);
  static const Color _hubLight = Color(0xFFF2F2F2);
  static const Color _hubDark = Color(0xFFCCCCCC);
  static const Color _black = Color(0xFF050505);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    _drawSpool(canvas, center);
    _drawHub(canvas, center);
  }

  void _drawSpool(Canvas canvas, Offset c) {
    final r = spoolRadius;
    if (r <= hubRadius) return;
    final rect = Rect.fromCircle(center: c, radius: r);

    // Wound tape body — warm-to-dark brown radial gradient.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [_spoolLight, _spoolDark],
          stops: [0.0, 1.0],
        ).createShader(rect),
    );

    // Concentric rings for individual wound layers.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(0.5, r * 0.008)
      ..color = Colors.white.withValues(alpha: 0.05);
    final step = r * 0.06;
    for (double rr = hubRadius + step; rr < r * 0.97; rr += step) {
      canvas.drawCircle(c, rr, ringPaint);
    }

    // Bright outer edge (specular) + dark rim for depth.
    canvas.drawCircle(
      c,
      r * 0.98,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(0.6, r * 0.018)
        ..color = Colors.white.withValues(alpha: 0.10),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(0.6, r * 0.02)
        ..color = Colors.black.withValues(alpha: 0.45),
    );
  }

  void _drawHub(Canvas canvas, Offset c) {
    final hr = hubRadius;
    final rect = Rect.fromCircle(center: c, radius: hr);

    // Metallic hub disc.
    canvas.drawCircle(
      c,
      hr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_hubLight, _hubDark],
        ).createShader(rect),
    );
    canvas.drawCircle(
      c,
      hr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(0.5, hr * 0.05)
        ..color = Colors.black.withValues(alpha: 0.35),
    );

    // Six bevelled spokes.
    final spindle = hr * 0.30;
    final outer = hr * 0.86;
    final darkSpoke = Paint()
      ..color = _black
      ..strokeWidth = hr * 0.16
      ..strokeCap = StrokeCap.round;
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = hr * 0.04
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotation);
    final bevel = hr * 0.04;
    for (int i = 0; i < 6; i++) {
      final a = i * pi / 3;
      final dx = cos(a);
      final dy = sin(a);
      canvas.drawLine(
        Offset(dx * spindle, dy * spindle),
        Offset(dx * outer, dy * outer),
        darkSpoke,
      );
      canvas.drawLine(
        Offset(dx * spindle + bevel, dy * spindle - bevel),
        Offset(dx * outer + bevel, dy * outer - bevel),
        highlight,
      );
    }
    canvas.restore();

    // Black spindle hole.
    canvas.drawCircle(c, hr * 0.30, Paint()..color = _black);
  }

  @override
  bool shouldRepaint(ReelPainter old) =>
      old.rotation != rotation ||
      old.spoolRadius != spoolRadius ||
      old.hubRadius != hubRadius;
}
