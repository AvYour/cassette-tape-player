import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cassette_tape.dart';
import '../painters/cassette_body_painter.dart';
import '../painters/reel_painter.dart';
import '../painters/tape_strip_painter.dart';
import '../utils/colors.dart';

class CassetteCard extends StatefulWidget {
  final CassetteTape tape;
  final TapeState tapeState;
  final double progress;
  final bool isHero;

  const CassetteCard({
    super.key,
    required this.tape,
    required this.tapeState,
    required this.progress,
    this.isHero = false,
  });

  @override
  State<CassetteCard> createState() => _CassetteCardState();
}

class _CassetteCardState extends State<CassetteCard>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  // Accumulated hub angles (radians) for the two reels.
  final ValueNotifier<(double, double)> _angles =
      ValueNotifier<(double, double)>((0, 0));
  double _leftAngle = 0;
  double _rightAngle = 0;

  // Smoothly-ramped speed multiplier (see reference frame loop).
  double _speedMul = 0;
  double _lastT = 0;

  // Base angular velocities (rad/s). The take-up (right) reel spins faster than
  // the supply (left) reel by the wound-radius ratio, mirroring real physics.
  static const double _baseRight = 2.094; // ~120 deg/s
  static const double _baseLeft = _baseRight * (0.12 / 0.23); // ~62.6 deg/s

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _angles.dispose();
    super.dispose();
  }

  double get _targetSpeed {
    switch (widget.tapeState) {
      case TapeState.playing:
        return 1.0;
      case TapeState.ff:
        return 6.0;
      case TapeState.rew:
        return -6.0;
      case TapeState.stopped:
        return 0.0;
    }
  }

  void _onTick(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1e6;
    final dt = (now - _lastT).clamp(0.0, 0.05);
    _lastT = now;

    // Ease the speed multiplier toward the target for smooth start/stop.
    _speedMul += (_targetSpeed - _speedMul) * (dt * 4.0);

    // Subtle motor wobble (±3%, 4-second period) while playing.
    final wobble = widget.tapeState == TapeState.playing
        ? 1.0 + 0.03 * sin(now * (2 * pi / 4.0))
        : 1.0;

    _leftAngle += _baseLeft * _speedMul * wobble * dt;
    _rightAngle += _baseRight * _speedMul * wobble * dt;
    _angles.value = (_leftAngle, _rightAngle);
  }

  Widget _buildWindowContent(double ww, double wh) {
    // Fixed reel geometry: the spool radius varies with progress, the hub does
    // not. Boxes are sized to the maximum spool so the hub stays put.
    final maxR = min(wh * 0.44, ww * 0.19);
    final minR = maxR * 0.48;
    final hubR = maxR * 0.40;
    final span = maxR - minR;

    final leftSpool = maxR - span * widget.progress; // supply unwinds
    final rightSpool = minR + span * widget.progress; // take-up winds

    final leftCenter = Offset(ww * 0.29, wh * 0.5);
    final rightCenter = Offset(ww * 0.71, wh * 0.5);
    final box = maxR * 2;

    return RepaintBoundary(
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: TapeStripPainter(progress: widget.progress),
            ),
          ),
          ValueListenableBuilder<(double, double)>(
            valueListenable: _angles,
            builder: (context, angles, _) {
              return Stack(
                children: [
                  Positioned(
                    left: leftCenter.dx - maxR,
                    top: leftCenter.dy - maxR,
                    width: box,
                    height: box,
                    child: CustomPaint(
                      painter: ReelPainter(
                        rotation: angles.$1,
                        spoolRadius: leftSpool,
                        hubRadius: hubR,
                      ),
                    ),
                  ),
                  Positioned(
                    left: rightCenter.dx - maxR,
                    top: rightCenter.dy - maxR,
                    width: box,
                    height: box,
                    child: CustomPaint(
                      painter: ReelPainter(
                        rotation: angles.$2,
                        spoolRadius: rightSpool,
                        hubRadius: hubR,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = AspectRatio(
      aspectRatio: 1.6,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final windowLeft = w * 0.18;
          final windowTop = h * 0.07;
          final windowWidth = w * 0.64;
          final windowHeight = h * 0.43;

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: CassetteBodyPainter(
                    bodyColor: widget.tape.bodyColor,
                    stripeColor: widget.tape.stripeColor,
                  ),
                ),
              ),
              Positioned(
                left: windowLeft,
                top: windowTop,
                width: windowWidth,
                height: windowHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildWindowContent(windowWidth, windowHeight),
                ),
              ),
              Positioned(
                left: w * 0.14,
                right: w * 0.14,
                top: h * 0.57,
                child: Text(
                  widget.tape.artistName,
                  style: GoogleFonts.courierPrime(
                    fontSize: 9,
                    color: kTextDark.withValues(alpha: 0.65),
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              Positioned(
                left: w * 0.14,
                right: w * 0.14,
                top: h * 0.67,
                child: Text(
                  widget.tape.trackName,
                  style: GoogleFonts.specialElite(
                    fontSize: 11,
                    color: kTextDark,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              Positioned(
                left: w * 0.14,
                right: w * 0.14,
                top: h * 0.83,
                child: Text(
                  widget.tape.year,
                  style: GoogleFonts.vt323(
                    fontSize: 10,
                    color: kTextDark.withValues(alpha: 0.45),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    if (widget.isHero) {
      return Hero(tag: 'tape_${widget.tape.id}', child: content);
    }
    return content;
  }
}
