import 'dart:math';
import 'package:flutter/material.dart';
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
  late AnimationController _reelController;

  @override
  void initState() {
    super.initState();
    _reelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _applyTapeState(widget.tapeState);
  }

  @override
  void didUpdateWidget(CassetteCard old) {
    super.didUpdateWidget(old);
    if (old.tapeState != widget.tapeState) {
      _applyTapeState(widget.tapeState);
    }
  }

  void _applyTapeState(TapeState state) {
    switch (state) {
      case TapeState.playing:
        _reelController.duration = const Duration(seconds: 2);
        _reelController.repeat();
      case TapeState.ff:
        _reelController.duration = const Duration(milliseconds: 480);
        _reelController.repeat();
      case TapeState.rew:
        _reelController.duration = const Duration(milliseconds: 480);
        _reelController.repeat(reverse: true);
      case TapeState.stopped:
        _reelController.stop();
    }
  }

  @override
  void dispose() {
    _reelController.dispose();
    super.dispose();
  }

  Widget _buildWindowContent(double ww, double wh) {
    final maxR = wh * 0.42;
    final minR = wh * 0.24;
    final leftR = (maxR * (1 - widget.progress * 0.4)).clamp(minR, maxR);
    final rightR = (minR + (maxR - minR) * widget.progress).clamp(minR, maxR);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _reelController,
        builder: (context, _) {
          final angle = _reelController.value * 2 * pi;
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: TapeStripPainter(progress: widget.progress),
                ),
              ),
              Positioned(
                left: ww * 0.20 - leftR,
                top: wh * 0.50 - leftR,
                width: leftR * 2,
                height: leftR * 2,
                child: CustomPaint(
                  painter: ReelPainter(
                    rotationAngle: -angle,
                    radius: leftR,
                    isLeft: true,
                  ),
                ),
              ),
              Positioned(
                left: ww * 0.80 - rightR,
                top: wh * 0.50 - rightR,
                width: rightR * 2,
                height: rightR * 2,
                child: CustomPaint(
                  painter: ReelPainter(
                    rotationAngle: angle,
                    radius: rightR,
                    isLeft: false,
                  ),
                ),
              ),
            ],
          );
        },
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
