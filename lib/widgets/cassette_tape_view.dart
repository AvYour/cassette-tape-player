import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/cassette_tape.dart';
import '../painters/cassette_tape_painter.dart';

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

  static const Color _neutralShell = Color(0xFF2A2622);
  static const Color _neutralStripe = Color(0xFF14100C);

  @override
  Widget build(BuildContext context) {
    final a = angles;
    final art = tape.albumArtUrl;
    final hasArt = art != null && art.isNotEmpty;
    return AspectRatio(
      aspectRatio: kCassetteAspect,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final radius = constraints.maxHeight * 0.06;
          return Stack(
            fit: StackFit.expand,
            children: [
              // The album art IS the cassette body when available.
              if (hasArt)
                ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Image.network(
                    art,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: _neutralShell),
                  ),
                ),
              CustomPaint(
                painter: CassetteBasePainter(
                  bodyColor: _neutralShell,
                  labelColor: const Color(0xFFF4EFE6),
                  stripeColor: hasArt ? _neutralStripe : tape.stripeColor,
                  useArt: hasArt,
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
            ],
          );
        },
      ),
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
