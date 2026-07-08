import 'package:flutter/material.dart';

class CassetteBodyPainter extends CustomPainter {
  final Color bodyColor;
  final Color stripeColor;

  const CassetteBodyPainter({
    required this.bodyColor,
    required this.stripeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawShadow(canvas, w, h);
    _drawBody(canvas, w, h);
    _drawStripe(canvas, w, h);
    _drawWindow(canvas, w, h);
    _drawLabel(canvas, w, h);
    _drawScrew(canvas, Offset(w * 0.07, h * 0.09));
    _drawScrew(canvas, Offset(w * 0.93, h * 0.09));
    _drawScrew(canvas, Offset(w * 0.07, h * 0.91));
    _drawScrew(canvas, Offset(w * 0.93, h * 0.91));
  }

  void _drawShadow(Canvas canvas, double w, double h) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 5, w - 3, h - 3),
        const Radius.circular(12),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
  }

  void _drawBody(Canvas canvas, double w, double h) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(12),
    );
    canvas.drawRRect(rrect, Paint()..color = bodyColor);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawStripe(Canvas canvas, double w, double h) {
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.56, w, h * 0.17),
      Paint()..color = stripeColor,
    );
  }

  void _drawWindow(Canvas canvas, double w, double h) {
    final windowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.07, w * 0.64, h * 0.43),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      windowRect,
      Paint()..color = const Color(0xFF0D0D0D).withValues(alpha: 0.90),
    );
    canvas.drawRRect(
      windowRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _drawLabel(Canvas canvas, double w, double h) {
    final labelRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.55, w * 0.76, h * 0.35),
      const Radius.circular(5),
    );
    canvas.drawRRect(labelRRect, Paint()..color = const Color(0xFFF5EDD8));
    canvas.drawRRect(
      labelRRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
  }

  void _drawScrew(Canvas canvas, Offset center) {
    const r = 5.0;
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFF888888));
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    final slotPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center + const Offset(-2.5, 0), center + const Offset(2.5, 0), slotPaint);
    canvas.drawLine(center + const Offset(0, -2.5), center + const Offset(0, 2.5), slotPaint);
  }

  @override
  bool shouldRepaint(CassetteBodyPainter old) =>
      old.bodyColor != bodyColor || old.stripeColor != stripeColor;
}
