import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/cassette_tape.dart';
import '../painters/cassette_tape_painter.dart';
import 'tape_color_builder.dart';

/// Rotation state for the two reel hubs, in degrees. Mutated by the player's
/// frame loop; the hub layer listens directly so only it repaints per frame.
class ReelAngles extends ChangeNotifier {
  double leftDeg = 0;
  double rightDeg = 0;

  void update(double left, double right) {
    leftDeg = left;
    rightDeg = right;
    notifyListeners();
  }
}

/// Full cassette drawing, split into three layers so per-frame hub rotation
/// repaints only the small middle layer (mirrors the reference's
/// drawWithCache + deferred-read pattern).
class CassetteTapeView extends StatelessWidget {
  final CassetteTape tape;
  final ReelAngles? angles;

  const CassetteTapeView({super.key, required this.tape, this.angles});

  @override
  Widget build(BuildContext context) {
    final a = angles;
    return AspectRatio(
      aspectRatio: kCassetteAspect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          TapeColorBuilder(
            tape: tape,
            builder: (context, colors) => CustomPaint(
              painter: CassetteBasePainter(
                bodyColor: colors.body,
                labelColor: colors.label,
                stripeColor: colors.stripe,
              ),
            ),
          ),
          RepaintBoundary(
            child: a == null
                ? const CustomPaint(
                    painter: CassetteHubsPainter(leftDeg: 0, rightDeg: 0),
                  )
                : AnimatedBuilder(
                    animation: a,
                    builder: (context, _) => CustomPaint(
                      painter: CassetteHubsPainter(
                        leftDeg: a.leftDeg,
                        rightDeg: a.rightDeg,
                      ),
                    ),
                  ),
          ),
          const CustomPaint(painter: CassetteFrontPainter()),
          if (tape.albumArtUrl != null && tape.albumArtUrl!.isNotEmpty)
            _albumArtOnLabel(),
        ],
      ),
    );
  }

  /// A small album-art sticker on the cassette label, so the tape is
  /// recognisable by its cover as well as its colour.
  Widget _albumArtOnLabel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final size = h * 0.15;
        return Positioned(
          left: w * 0.11,
          top: h * 0.145,
          width: size,
          height: size,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Image.network(
                tape.albumArtUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Hero flight that rotates the cassette between its upright pager pose
/// (-90 degrees) and the flat player pose, like the reference's shared
/// element transition.
HeroFlightShuttleBuilder cassetteFlightShuttle(CassetteTape tape) {
  return (flightContext, animation, direction, fromContext, toContext) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final angle = direction == HeroFlightDirection.push
            ? -math.pi / 2 * (1 - t)
            : -math.pi / 2 * t;
        return LayoutBuilder(
          builder: (context, constraints) {
            final cw = math.max(constraints.maxWidth, constraints.maxHeight);
            return OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Transform.rotate(
                angle: angle,
                child: SizedBox(
                  width: cw,
                  child: CassetteTapeView(tape: tape),
                ),
              ),
            );
          },
        );
      },
    );
  };
}
