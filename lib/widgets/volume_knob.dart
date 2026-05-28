import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VolumeKnob extends StatefulWidget {
  final double initialVolume;
  final ValueChanged<double> onVolumeChanged;

  const VolumeKnob({
    super.key,
    required this.initialVolume,
    required this.onVolumeChanged,
  });

  @override
  State<VolumeKnob> createState() => _VolumeKnobState();
}

class _VolumeKnobState extends State<VolumeKnob> {
  late double _volume;
  double? _lastAngle;

  static const double _startAngle = -135 * pi / 180;
  static const double _sweepAngle = 270 * pi / 180;

  @override
  void initState() {
    super.initState();
    _volume = widget.initialVolume.clamp(0.0, 1.0);
  }

  double get _indicatorAngle => _startAngle + _sweepAngle * _volume;

  void _handlePanStart(DragStartDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    _lastAngle = atan2(
      details.localPosition.dy - center.dy,
      details.localPosition.dx - center.dx,
    );
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    if (_lastAngle == null) return;
    final center = Offset(size.width / 2, size.height / 2);
    final angle = atan2(
      details.localPosition.dy - center.dy,
      details.localPosition.dx - center.dx,
    );

    var delta = angle - _lastAngle!;
    if (delta > pi) delta -= 2 * pi;
    if (delta < -pi) delta += 2 * pi;

    final newVolume = (_volume + delta / _sweepAngle).clamp(0.0, 1.0);
    if ((newVolume * 10).round() != (_volume * 10).round()) {
      HapticFeedback.selectionClick();
    }
    setState(() => _volume = newVolume);
    widget.onVolumeChanged(_volume);
    _lastAngle = angle;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            onPanStart: (d) => _handlePanStart(d, size),
            onPanUpdate: (d) => _handlePanUpdate(d, size),
            onPanEnd: (_) => _lastAngle = null,
            child: CustomPaint(
              painter: _KnobPainter(indicatorAngle: _indicatorAngle),
            ),
          );
        },
      ),
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double indicatorAngle;

  const _KnobPainter({required this.indicatorAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2 - 4;

    canvas.drawCircle(
      center + const Offset(2, 3),
      r,
      Paint()..color = Colors.black.withOpacity(0.38),
    );

    final gradient = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      colors: [const Color(0xFF404040), const Color(0xFF0F0F0F)],
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: r),
        ),
    );

    const startAngle = -135 * pi / 180;
    const sweepAngle = 270 * pi / 180;

    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = 1.0;
    for (int i = 0; i <= 10; i++) {
      final a = startAngle + (sweepAngle * i / 10);
      final innerR = r * 0.76;
      final outerR = r * (i % 5 == 0 ? 0.96 : 0.87);
      canvas.drawLine(
        center + Offset(cos(a) * innerR, sin(a) * innerR),
        center + Offset(cos(a) * outerR, sin(a) * outerR),
        tickPaint,
      );
    }

    canvas.drawLine(
      center + Offset(cos(indicatorAngle) * r * 0.28, sin(indicatorAngle) * r * 0.28),
      center + Offset(cos(indicatorAngle) * r * 0.74, sin(indicatorAngle) * r * 0.74),
      Paint()
        ..color = const Color(0xFFD6A033)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(center, r * 0.17, Paint()..color = const Color(0xFF1A1A1A));
  }

  @override
  bool shouldRepaint(_KnobPainter old) => old.indicatorAngle != indicatorAngle;
}
