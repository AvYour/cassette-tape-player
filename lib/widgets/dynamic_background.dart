import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/cassette_tape.dart';
import 'tape_color_builder.dart';

/// A living backdrop for the player: large soft blobs of the current track's
/// colors that flow and morph (like a YouTube Music now-playing background),
/// over a light neutral base so the lyrics stay clean and readable.
class DynamicMusicBackground extends StatefulWidget {
  final CassetteTape tape;
  final Widget child;

  const DynamicMusicBackground({
    super.key,
    required this.tape,
    required this.child,
  });

  @override
  State<DynamicMusicBackground> createState() => _DynamicMusicBackgroundState();
}

class _DynamicMusicBackgroundState extends State<DynamicMusicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: const Duration(seconds: 9))
        ..repeat();

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TapeColorBuilder(
      tape: widget.tape,
      builder: (context, colors) {
        // Vivid, well-lit hues so the flow is colourful, not muddy/brown.
        final c1 = _vivid(colors.stripe, 0.58, 0.72);
        final c2 = _vivid(colors.body, 0.60, 0.60);
        final c3 = _vivid(_shiftHue(colors.stripe, 45), 0.62, 0.68);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          key: ValueKey(widget.tape.id),
          builder: (context, fade, _) {
            return AnimatedBuilder(
              animation: _drift,
              builder: (context, __) {
                return CustomPaint(
                  painter: _FlowPainter(
                    c1: c1,
                    c2: c2,
                    c3: c3,
                    t: _drift.value,
                    intensity: fade,
                  ),
                  child: widget.child,
                );
              },
            );
          },
        );
      },
    );
  }

  static Color _vivid(Color c, double lightness, double sat) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withSaturation(hsl.saturation.clamp(sat, 1.0))
        .withLightness(lightness)
        .toColor();
  }

  static Color _shiftHue(Color c, double degrees) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withHue((hsl.hue + degrees) % 360).toColor();
  }
}

class _FlowPainter extends CustomPainter {
  final Color c1;
  final Color c2;
  final Color c3;
  final double t; // 0..1 drift phase
  final double intensity; // 0..1 fade-in on song change

  _FlowPainter({
    required this.c1,
    required this.c2,
    required this.c3,
    required this.t,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;
    final maxDim = size.longestSide;

    // Light, neutral base — no brown wash behind the lyrics.
    canvas.drawRect(rect, Paint()..color = const Color(0xFFF3F1EE));

    final a = 2 * math.pi * t;
    // Each blob drifts on its own slow orbit for an organic, flowing motion.
    _blob(canvas, Offset(w * (0.30 + 0.20 * math.cos(a)),
        h * (0.26 + 0.16 * math.sin(a * 1.1))), maxDim * 0.62, c1);
    _blob(canvas, Offset(w * (0.74 + 0.18 * math.cos(a * 0.8 + 2)),
        h * (0.42 + 0.20 * math.sin(a + 1))), maxDim * 0.7, c2);
    _blob(canvas, Offset(w * (0.5 + 0.24 * math.cos(a * 1.3 + 4)),
        h * (0.78 + 0.14 * math.sin(a * 0.9 + 3))), maxDim * 0.66, c3);

    // Gentle top-to-bottom light sheen to keep contrast for the UI.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, h),
          const [Color(0x22FFFFFF), Colors.transparent, Color(0x0F000000)],
          const [0.0, 0.5, 1.0],
        ),
    );
  }

  void _blob(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [color.withValues(alpha: 0.42 * intensity), color.withValues(alpha: 0)],
        ),
    );
  }

  @override
  bool shouldRepaint(_FlowPainter old) =>
      old.t != t ||
      old.c1 != c1 ||
      old.c2 != c2 ||
      old.c3 != c3 ||
      old.intensity != intensity;
}
