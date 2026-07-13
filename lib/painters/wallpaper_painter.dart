import 'package:flutter/material.dart';

/// The dusk-lit wall of the 1985 room: warm striped wallpaper, a soft lamp
/// glow high on the wall, and edges falling away into shadow.
class WallpaperPainter extends CustomPainter {
  const WallpaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Evening wall tone.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF463726), Color(0xFF2A2018)],
        ).createShader(rect),
    );

    // Wallpaper stripes.
    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.028);
    for (double x = 8; x < size.width; x += 26) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 9, size.height), stripe);
    }

    // Lamp glow, high on the left of the wall.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.8),
          radius: 0.95,
          colors: [
            const Color(0xFFFFDFA3).withValues(alpha: 0.07),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // The corners of the room sink into the evening.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.3,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.32),
          ],
          stops: const [0.55, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(WallpaperPainter old) => false;
}
