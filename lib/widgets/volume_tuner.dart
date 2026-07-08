import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';

/// Horizontal slider styled as a vintage tuner fader
/// (reference `VintageVolumeTuner`).
class VintageVolumeTuner extends StatefulWidget {
  final double volume;
  final ValueChanged<double> onChanged;

  const VintageVolumeTuner({
    super.key,
    required this.volume,
    required this.onChanged,
  });

  @override
  State<VintageVolumeTuner> createState() => _VintageVolumeTunerState();
}

class _VintageVolumeTunerState extends State<VintageVolumeTuner>
    with SingleTickerProviderStateMixin {
  static final SpringDescription _spring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 800, ratio: 0.6);

  late final AnimationController _capScale =
      AnimationController.unbounded(vsync: this, value: 1);
  bool _dragging = false;

  void _setDragging(bool dragging) {
    _dragging = dragging;
    _capScale.animateWith(SpringSimulation(
        _spring, _capScale.value, dragging ? 0.95 : 1.0, _capScale.velocity));
  }

  @override
  void dispose() {
    _capScale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (_) => _setDragging(true),
      onHorizontalDragEnd: (_) => _setDragging(false),
      onHorizontalDragCancel: () => _setDragging(false),
      onHorizontalDragUpdate: (details) {
        final trackW = (context.size?.width ?? 0) - 48;
        if (trackW <= 0) return;
        final next =
            (widget.volume + details.delta.dx / trackW).clamp(0.0, 1.0);
        if ((widget.volume * 40).round() != (next * 40).round()) {
          HapticFeedback.selectionClick();
        }
        widget.onChanged(next);
      },
      child: CustomPaint(
        painter: _TunerPainter(
          volume: widget.volume,
          dragging: _dragging,
          capScale: _capScale,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _TunerPainter extends CustomPainter {
  final double volume;
  final bool dragging;
  final Animation<double> capScale;

  _TunerPainter({
    required this.volume,
    required this.dragging,
    required this.capScale,
  }) : super(repaint: capScale);

  static final Map<String, TextPainter> _labelCache = {};

  static TextPainter _label(String text, double fontSize, FontWeight weight) {
    return _labelCache.putIfAbsent('$text-$fontSize-$weight', () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: GoogleFonts.robotoMono(
            fontSize: fontSize,
            fontWeight: weight,
            color: kMark,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const trackX = 24.0;
    final trackY = h * 0.35;
    final trackW = w - trackX * 2;
    const trackH = 4.0;

    // Track groove.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(trackX, trackY, trackW, trackH),
          const Radius.circular(trackH / 2)),
      Paint()..color = const Color(0xFF050505),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(trackX, trackY + trackH, trackW, 1),
          const Radius.circular(trackH / 2)),
      Paint()..color = const Color(0x22FFFFFF),
    );

    // Scale marks and numerals.
    final marksY = h * 0.65;
    final markPaint = Paint()
      ..color = kMark.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (int i = 0; i <= 10; i++) {
      final x = trackX + i * (trackW / 10);
      canvas.drawLine(Offset(x, marksY), Offset(x, marksY + 6), markPaint);
      if (i % 2 == 0 && i != 0 && i != 10) {
        final tp = _label('$i', 11, FontWeight.bold);
        tp.paint(canvas, Offset(x - tp.width / 2, marksY + 8));
      }
    }
    final minTp = _label('MIN', 10, FontWeight.w500);
    final maxTp = _label('MAX', 10, FontWeight.w500);
    minTp.paint(canvas, Offset(trackX - minTp.width / 2, marksY + 8));
    maxTp.paint(canvas, Offset(trackX + trackW - maxTp.width / 2, marksY + 8));

    // Fader cap.
    const capW = 16.0;
    const capH = 26.0;
    final capY = trackY - capH / 2 + 2;
    final capX = trackX + volume * trackW;
    final capRect = Rect.fromLTWH(capX - capW / 2, capY, capW, capH);
    final capRRect =
        RRect.fromRectAndRadius(capRect, const Radius.circular(2));

    final scale = capScale.value.clamp(0.8, 1.2);
    canvas.save();
    canvas.translate(capX, capY + capH / 2);
    canvas.scale(scale);
    canvas.translate(-capX, -(capY + capH / 2));

    // Cap shadow.
    canvas.drawRRect(
      capRRect.shift(Offset(0, dragging ? 2 : 4)),
      Paint()
        ..color = Color.fromARGB(dragging ? 255 : 160, 0, 0, 0)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, (dragging ? 4 : 8) * 0.5),
    );

    // Cap body.
    canvas.drawRRect(
      capRRect,
      Paint()
        ..shader = ui.Gradient.linear(
          capRect.topLeft,
          capRect.bottomLeft,
          const [Color(0xFFF7F1E6), Color(0xFFDCD5C6)],
        ),
    );

    // Grip grooves.
    const grooveMargin = 4.0;
    final gLeft = capX - (capW - grooveMargin * 2) / 2;
    final gRight = capX + (capW - grooveMargin * 2) / 2;
    for (int i = 0; i < 8; i++) {
      final gY = capY + (capH / 8) * i;
      canvas.drawLine(Offset(gLeft, gY), Offset(gRight, gY),
          Paint()..color = const Color(0x33000000)..strokeWidth = 1);
      canvas.drawLine(Offset(gLeft, gY + 1), Offset(gRight, gY + 1),
          Paint()..color = const Color(0x88FFFFFF)..strokeWidth = 1);
    }

    // Bevel and indicator line.
    canvas.drawRRect(
      capRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = ui.Gradient.linear(
          capRect.topLeft,
          capRect.bottomRight,
          [
            Colors.white.withValues(alpha: 0.9),
            Colors.transparent,
            const Color(0xFFB5AFA1).withValues(alpha: 0.8),
          ],
          const [0.0, 0.5, 1.0],
        ),
    );
    canvas.drawLine(
      Offset(capX, capY),
      Offset(capX, capY + capH),
      Paint()
        ..color = const Color(0xFFC75549)
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TunerPainter old) =>
      old.volume != volume || old.dragging != dragging;
}
