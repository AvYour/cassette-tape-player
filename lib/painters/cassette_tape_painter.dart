import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/tape_wind.dart';

/// Aspect ratio of the cassette shell (reference: 1.58).
const double kCassetteAspect = 1.58;

RRect _windowRRect(double w, double h) => RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.32, w * 0.56, h * 0.28),
      Radius.circular(h * 0.03),
    );

/// Bottom layer: plastic shell, paper label, stripe, side-A markings and the
/// recessed window content (tape spools, gauge).
///
/// All geometry is a direct port of the reference renderer's proportions.
/// The wound spools follow [progress]: the supply pack (left) drains into the
/// take-up pack (right) with real tape physics (see [TapeWind]), so you can
/// SEE how far into the song the tape is. At the default progress 0 the
/// classic full-left / empty-right pose is drawn.
class CassetteBasePainter extends CustomPainter {
  final Color bodyColor;
  final Color labelColor;
  final Color stripeColor;

  /// Track progress 0..1 that places the tape packs.
  final double progress;

  /// When true the shell body is left translucent so an album-art image behind
  /// the painter shows through as the cassette's body (only a plastic sheen is
  /// drawn on top).
  final bool useArt;

  const CassetteBasePainter({
    required this.bodyColor,
    required this.labelColor,
    required this.stripeColor,
    this.progress = 0,
    this.useArt = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shell =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(h * 0.06));

    // 1. Plastic shell — solid colour, or a sheen over the album art.
    if (useArt) {
      canvas.drawRRect(
        shell,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(w * 0.4, h),
            const [Color(0x33FFFFFF), Color(0x11000000), Color(0x55000000)],
            const [0.0, 0.4, 1.0],
          ),
      );
    } else {
      canvas.drawRRect(
        shell,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(w * 0.5, h * 0.3),
            w * 0.8,
            [bodyColor.withValues(alpha: 0.9), darken(bodyColor, 0.3)],
          ),
      );
    }
    canvas.drawRRect(
      shell,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, h),
          const [Color(0x33FFFFFF), Colors.transparent, Color(0x66000000)],
          const [0.0, 0.5, 1.0],
        ),
    );

    // 2. Paper label with drop shadow.
    final labelLeft = w * 0.08;
    final labelTop = h * 0.13;
    final labelW = w * 0.84;
    final labelH = h * 0.56;
    final labelRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelLeft, labelTop, labelW, labelH),
      Radius.circular(h * 0.02),
    );

    canvas.drawRRect(
      labelRRect.shift(Offset(0, h * 0.005)),
      Paint()..color = const Color(0x44000000),
    );
    canvas.drawRRect(
      labelRRect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.5, h * 0.4),
          w * 0.5,
          [labelColor, darken(labelColor, 0.15)],
        ),
    );

    // Colored stripe band across the label.
    final stripeTop = labelTop + h * 0.04;
    canvas.drawRect(
      Rect.fromLTWH(labelLeft, stripeTop, labelW, h * 0.09),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(labelLeft, 0),
          Offset(labelLeft + labelW, 0),
          [darken(stripeColor, 0.1), stripeColor, darken(stripeColor, 0.1)],
          const [0.0, 0.5, 1.0],
        ),
    );

    // Ruled writing lines.
    final rule = Paint()
      ..color = const Color(0x1A000000)
      ..strokeWidth = h * 0.003;
    for (int i = 0; i < 3; i++) {
      final y = labelTop + h * 0.17 + i * h * 0.06;
      canvas.drawLine(Offset(w * 0.12, y), Offset(w * 0.88, y), rule);
    }

    // Side "A" box with arrow glyph.
    final aSize = h * 0.08;
    final aLeft = labelLeft + w * 0.03;
    final aTop = labelTop + labelH - aSize - h * 0.02;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(aLeft, aTop, aSize, aSize), Radius.circular(h * 0.01)),
      Paint()
        ..color = const Color(0xFF1A1A1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.005,
    );
    final aPath = Path()
      ..moveTo(aLeft + aSize * 0.25, aTop + aSize * 0.75)
      ..lineTo(aLeft + aSize * 0.50, aTop + aSize * 0.20)
      ..lineTo(aLeft + aSize * 0.75, aTop + aSize * 0.75)
      ..moveTo(aLeft + aSize * 0.33, aTop + aSize * 0.60)
      ..lineTo(aLeft + aSize * 0.67, aTop + aSize * 0.60);
    canvas.drawPath(
      aPath,
      Paint()
        ..color = const Color(0xFF1A1A1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.008
        ..strokeCap = StrokeCap.round,
    );

    // "90" length marking on the right of the label.
    final n90Left = labelLeft + labelW - w * 0.1;
    final n90Top = aTop + h * 0.02;
    final ink90 = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.008
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(
        Rect.fromLTWH(n90Left, n90Top, w * 0.025, w * 0.025), ink90);
    canvas.drawLine(
      Offset(n90Left + w * 0.025, n90Top + w * 0.012),
      Offset(n90Left + w * 0.025, n90Top + h * 0.06),
      ink90,
    );
    canvas.drawOval(
        Rect.fromLTWH(n90Left + w * 0.035, n90Top, w * 0.025, h * 0.06), ink90);

    // 3. Recessed window: background, top shading, tape lines, spools, gauge.
    final win = _windowRRect(w, h);
    final winRect = win.outerRect;
    canvas.save();
    canvas.clipRRect(win);

    canvas.drawRect(winRect, Paint()..color = kWindowBg);
    canvas.drawRect(
      winRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, winRect.top),
          Offset(0, winRect.top + h * 0.1),
          const [Color(0x99000000), Colors.transparent],
        ),
    );

    final leftHub = Offset(w * 0.32, h * 0.46);
    final rightHub = Offset(w * 0.68, h * 0.46);
    final fullR = h * 0.23;
    // The packs wind with the song: supply drains, take-up swells.
    final leftR = fullR * TapeWind.leftRadiusFraction(progress);
    final rightR = fullR * TapeWind.rightRadiusFraction(progress);

    final tapeLine = Paint()
      ..color = kTapeDark
      ..strokeWidth = h * 0.015;
    canvas.drawLine(
      Offset(leftHub.dx - leftR, leftHub.dy),
      Offset(leftHub.dx - leftR, winRect.bottom),
      tapeLine,
    );
    canvas.drawLine(
      Offset(rightHub.dx + rightR, rightHub.dy),
      Offset(rightHub.dx + rightR, winRect.bottom),
      tapeLine,
    );

    _drawTapeSpool(canvas, leftHub, leftR, h);
    _drawTapeSpool(canvas, rightHub, rightR, h);

    // Tape position gauge between the spools.
    final gaugeW = w * 0.18;
    final gaugeH = h * 0.02;
    final gaugeLeft = (w - gaugeW) / 2;
    final gaugeTop = winRect.top + winRect.height * 0.45;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(gaugeLeft, gaugeTop, gaugeW, gaugeH),
          Radius.circular(h * 0.01)),
      Paint()..color = const Color(0x1AFFFFFF),
    );
    final tick = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = h * 0.003;
    for (int i = 0; i <= 4; i++) {
      final x = gaugeLeft + i * (gaugeW / 4);
      canvas.drawLine(Offset(x, gaugeTop + h * 0.005),
          Offset(x, gaugeTop + gaugeH - h * 0.005), tick);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(CassetteBasePainter old) =>
      old.bodyColor != bodyColor ||
      old.labelColor != labelColor ||
      old.stripeColor != stripeColor ||
      old.useArt != useArt ||
      // Repaint only when the packs have visibly moved (~1% steps), not on
      // every position tick.
      (old.progress * 100).round() != (progress * 100).round();
}

/// Middle layer: the two rotating metallic hubs, clipped to the window.
/// This is the only layer that repaints during playback.
class CassetteHubsPainter extends CustomPainter {
  final double leftDeg;
  final double rightDeg;

  const CassetteHubsPainter({required this.leftDeg, required this.rightDeg});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.save();
    canvas.clipRRect(_windowRRect(w, h));
    _drawHub(canvas, Offset(w * 0.32, h * 0.46), leftDeg, h);
    _drawHub(canvas, Offset(w * 0.68, h * 0.46), rightDeg, h);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CassetteHubsPainter old) =>
      old.leftDeg != leftDeg || old.rightDeg != rightDeg;
}

/// Static top layer: window glass, bottom mechanism, exposed tape, screws.
class CassetteFrontPainter extends CustomPainter {
  const CassetteFrontPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final win = _windowRRect(w, h);
    final winRect = win.outerRect;

    // 4. Window glass: rim stroke + diagonal reflection.
    canvas.drawRRect(
      win,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.008
        ..shader = ui.Gradient.linear(
          Offset(0, winRect.top),
          Offset(0, winRect.bottom),
          const [Color(0x99000000), Colors.transparent, Color(0x44FFFFFF)],
          const [0.0, 0.5, 1.0],
        ),
    );
    final reflection = Path()
      ..moveTo(winRect.left, winRect.top)
      ..lineTo(winRect.left + winRect.width * 0.8, winRect.top)
      ..lineTo(winRect.left + winRect.width * 0.3, winRect.bottom)
      ..lineTo(winRect.left, winRect.bottom)
      ..close();
    canvas.save();
    canvas.clipRRect(win);
    canvas.drawPath(
      reflection,
      Paint()
        ..shader = ui.Gradient.linear(
          winRect.topLeft,
          Offset(winRect.left + winRect.width * 0.5, winRect.bottom),
          const [Color(0x22FFFFFF), Colors.transparent],
        ),
    );
    canvas.restore();

    // 5. Bottom mechanism trapezoid with exposed tape run.
    final trapBaseLeft = w * 0.15;
    final trapTopLeft = w * 0.24;
    final trapWidth = w * 0.52;
    final trapTop = h - h * 0.20;
    final mech = Path()
      ..moveTo(trapBaseLeft, h)
      ..lineTo(trapTopLeft, trapTop)
      ..lineTo(trapTopLeft + trapWidth, trapTop)
      ..lineTo(trapTopLeft + trapWidth, h)
      ..close();
    canvas.drawPath(
      mech,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, trapTop), Offset(0, h),
            const [Color(0xFF222222), Color(0xFF111111)]),
    );
    canvas.drawPath(
      mech,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.004
        ..color = const Color(0x22FFFFFF),
    );

    final tapeY = trapTop + h * 0.05;
    canvas.drawLine(
      Offset(w * 0.25, tapeY),
      Offset(w * 0.75, tapeY),
      Paint()
        ..color = kTapeDark
        ..strokeWidth = h * 0.018,
    );
    canvas.drawLine(
      Offset(w * 0.25, tapeY - h * 0.005),
      Offset(w * 0.75, tapeY - h * 0.005),
      Paint()
        ..color = const Color(0x22FFFFFF)
        ..strokeWidth = h * 0.002,
    );

    final holesY = trapTop + h * 0.10;
    _hole(canvas, w * 0.28, holesY, h * 0.035);
    _hole(canvas, w * 0.72, holesY, h * 0.035);
    _hole(canvas, w * 0.50, holesY, h * 0.045);
    _hole(canvas, w * 0.18, holesY, h * 0.025);
    _hole(canvas, w * 0.82, holesY, h * 0.025);

    // 6. Screws: four corners plus top centre.
    final sx = w * 0.035;
    final sy = h * 0.055;
    for (final p in [
      Offset(sx, sy),
      Offset(w - sx, sy),
      Offset(sx, h - sy),
      Offset(w - sx, h - sy),
      Offset(w * 0.5, sy),
    ]) {
      _screw(canvas, p, h);
    }
  }

  void _hole(Canvas canvas, double x, double y, double r) {
    canvas.drawCircle(
        Offset(x, y + 2), r + 2, Paint()..color = const Color(0x66000000));
    canvas.drawCircle(
        Offset(x, y), r, Paint()..color = const Color(0xFF050505));
  }

  void _screw(Canvas canvas, Offset c, double h) {
    canvas.drawCircle(c, h * 0.045, Paint()..color = const Color(0xFF111111));
    canvas.drawCircle(
      c,
      h * 0.035,
      Paint()
        ..shader = ui.Gradient.radial(c, h * 0.035,
            const [Color(0xFF888888), Color(0xFF333333)], const [0.7, 1.0]),
    );
    final o = h * 0.035 * 0.3;
    final slot = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.008
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(math.pi / 4);
    canvas.drawLine(Offset(-o, -o), Offset(o, o), slot);
    canvas.drawLine(Offset(o, -o), Offset(-o, o), slot);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CassetteFrontPainter old) => false;
}

void _drawTapeSpool(Canvas canvas, Offset center, double radius, double h) {
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..shader =
          ui.Gradient.radial(center, radius, const [kTapeBrown, kTapeDark]),
  );
  final ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = h * 0.002
    ..color = const Color(0x0AFFFFFF);
  final numRings = radius ~/ (h * 0.012);
  for (int i = 1; i <= numRings; i++) {
    canvas.drawCircle(center, radius * (i / numRings), ring);
  }
  canvas.drawCircle(
    center,
    radius * 0.98,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.003
      ..color = const Color(0x1AFFFFFF),
  );
}

void _drawHub(Canvas canvas, Offset center, double rotationDeg, double h) {
  final hubR = h * 0.09;
  final spindleR = h * 0.035;

  canvas.drawCircle(
    center,
    hubR,
    Paint()
      ..shader = ui.Gradient.linear(
        center - Offset(hubR, hubR),
        center + Offset(hubR, hubR),
        const [Color(0xFFF2F2F2), Color(0xFFCCCCCC)],
      ),
  );
  canvas.drawCircle(
    center,
    hubR,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.005
      ..color = const Color(0x66000000),
  );
  canvas.drawCircle(center, spindleR, Paint()..color = const Color(0xFF050505));

  final spoke = Paint()
    ..color = const Color(0xFF050505)
    ..strokeWidth = h * 0.018
    ..strokeCap = StrokeCap.round;
  final glint = Paint()
    ..color = const Color(0x88FFFFFF)
    ..strokeWidth = h * 0.003
    ..strokeCap = StrokeCap.round;

  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(rotationDeg * math.pi / 180);
  for (int i = 0; i < 6; i++) {
    canvas.save();
    canvas.rotate(i * math.pi / 3);
    canvas.drawLine(Offset(0, -spindleR), Offset(0, -hubR * 0.85), spoke);
    canvas.drawLine(
        Offset(h * 0.01, -spindleR), Offset(h * 0.01, -hubR * 0.8), glint);
    canvas.restore();
  }
  canvas.restore();
}
