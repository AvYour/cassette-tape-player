import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/cassette_tape.dart';
import '../utils/colors.dart';
import 'tape_color_builder.dart';

/// A living backdrop for the player: the warm vintage base tinted with slowly
/// drifting blobs of the current track's colors — like a Spotify now-playing
/// glow that shifts from song to song without washing out the UI.
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
      AnimationController(vsync: this, duration: const Duration(seconds: 14))
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
        // Smoothly ease to the new song's colors when the tape changes.
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          key: ValueKey(widget.tape.id),
          builder: (context, fade, _) {
            return AnimatedBuilder(
              animation: _drift,
              builder: (context, __) {
                return CustomPaint(
                  painter: _AmbiancePainter(
                    body: colors.body,
                    stripe: colors.stripe,
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
}

class _AmbiancePainter extends CustomPainter {
  final Color body;
  final Color stripe;
  final double t; // 0..1 drift phase
  final double intensity; // 0..1 fade-in of the tint

  _AmbiancePainter({
    required this.body,
    required this.stripe,
    required this.t,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final maxDim = size.longestSide;

    // Warm vintage base.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.5, size.height * 0.3),
          maxDim * 0.85,
          const [kBgCenter, kBgEdge],
        ),
    );

    // Two drifting colour blobs from the album art.
    final a = 2 * math.pi * t;
    _blob(
      canvas,
      Offset(size.width * (0.3 + 0.12 * math.cos(a)),
          size.height * (0.28 + 0.08 * math.sin(a))),
      maxDim * 0.7,
      stripe.withValues(alpha: 0.28 * intensity),
    );
    _blob(
      canvas,
      Offset(size.width * (0.72 + 0.12 * math.cos(a + math.pi)),
          size.height * (0.7 + 0.08 * math.sin(a + math.pi))),
      maxDim * 0.8,
      body.withValues(alpha: 0.34 * intensity),
    );

    // Subtle vignette to settle the edges.
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

  void _blob(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [color, color.withValues(alpha: 0)],
        ),
    );
  }

  @override
  bool shouldRepaint(_AmbiancePainter old) =>
      old.t != t ||
      old.body != body ||
      old.stripe != stripe ||
      old.intensity != intensity;
}
