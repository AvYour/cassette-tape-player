import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';

/// Physical eject button with spring-animated press depth
/// (reference `VintageEjectButton`).
class VintageEjectButton extends StatefulWidget {
  final VoidCallback onPressed;

  const VintageEjectButton({super.key, required this.onPressed});

  @override
  State<VintageEjectButton> createState() => _VintageEjectButtonState();
}

class _VintageEjectButtonState extends State<VintageEjectButton>
    with SingleTickerProviderStateMixin {
  static final SpringDescription _spring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 900, ratio: 0.55);

  late final AnimationController _depth =
      AnimationController.unbounded(vsync: this, value: 0);

  void _animateTo(double target) {
    _depth.animateWith(
        SpringSimulation(_spring, _depth.value, target, _depth.velocity));
  }

  @override
  void dispose() {
    _depth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _animateTo(1);
      },
      onTapUp: (_) {
        HapticFeedback.selectionClick();
        _animateTo(0);
        widget.onPressed();
      },
      onTapCancel: () => _animateTo(0),
      child: CustomPaint(
        painter: _EjectPainter(depth: _depth),
        child: AnimatedBuilder(
          animation: _depth,
          builder: (context, child) {
            final p = _depth.value.clamp(0.0, 1.0);
            return Transform.scale(scale: 1 - p * 0.035, child: child);
          },
          child: const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 6, bottom: 2),
                  child: Text(
                    '⏏',
                    style: TextStyle(fontSize: 18, color: kGold),
                  ),
                ),
                Text(
                  'EJECT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: kCream,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EjectPainter extends CustomPainter {
  final Animation<double> depth;

  _EjectPainter({required this.depth}) : super(repaint: depth);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const corner = 4.0;
    final p = depth.value.clamp(0.0, 1.0);
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(corner));

    final scale = 1 - p * 0.035;
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.scale(scale);
    canvas.translate(-w / 2, -h / 2);

    // Drop shadow.
    final shadowRadius = (1 - p) * 8 + p * 2;
    final shadowY = (1 - p) * 6 + p * 1;
    final shadowAlpha = (180 + p * 70).round();
    canvas.drawRRect(
      rrect.shift(Offset(0, shadowY)),
      Paint()
        ..color = Color.fromARGB(shadowAlpha, 0, 0, 0)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowRadius * 0.5),
    );

    // Body.
    final base0 = Color.lerp(const Color(0xFF383430), const Color(0xFF2A2724), p)!;
    final base1 = Color.lerp(const Color(0xFF24211E), const Color(0xFF1A1816), p)!;
    canvas.drawRRect(
      rrect,
      Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, h), [base0, base1]),
    );

    // Grip ribs along the right edge.
    const ribsCount = 5;
    const ribSpacing = 5.0;
    final startX = w - (ribsCount * ribSpacing) - 8;
    final ribTop = h * 0.2;
    final ribBottom = h * 0.8;
    final ribLight = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    final ribDark = Paint()
      ..color = const Color(0x66000000)
      ..strokeWidth = 1;
    for (int i = 0; i < ribsCount; i++) {
      final x = startX + i * ribSpacing;
      canvas.drawLine(Offset(x, ribTop), Offset(x, ribBottom), ribLight);
      canvas.drawLine(Offset(x + 1, ribTop), Offset(x + 1, ribBottom), ribDark);
    }

    // Bevel edge, dimming with press.
    if (p < 0.99) {
      final la = (1 - p * 2).clamp(0.0, 1.0);
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(0, h),
            [
              Colors.white.withValues(alpha: la * 0.3),
              Colors.transparent,
              Colors.black.withValues(alpha: la * 0.8),
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EjectPainter old) => false;
}
