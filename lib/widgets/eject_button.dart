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
                // A vector eject mark, not the '⏏' character: the system
                // renders that codepoint as a colour emoji, so it ignored the
                // text colour and sat on the panel as an orange badge.
                Padding(
                  padding: EdgeInsets.only(right: 6, bottom: 2),
                  child: Icon(Icons.eject_rounded, size: 18, color: kInkLight),
                ),
                Text(
                  'EJECT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: kInkLight,
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

    // Drop shadow — soft lavender-black, matching the frosted keys.
    final shadowRadius = (1 - p) * 8 + p * 2;
    final shadowY = (1 - p) * 6 + p * 1;
    final shadowAlpha = (48 + p * 45).round();
    canvas.drawRRect(
      rrect.shift(Offset(0, shadowY)),
      Paint()
        ..color = Color.fromARGB(shadowAlpha, 40, 30, 70)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowRadius * 0.5),
    );

    // Frosted-glass cap, the same material as the transport keys.
    final faceTop = 0.82 - 0.24 * p;
    final faceBot = 0.50 - 0.16 * p;
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, h),
          [
            Colors.white.withValues(alpha: faceTop),
            Colors.white.withValues(alpha: faceBot),
          ],
        ),
    );

    // Grip ribs along the right edge, drawn as faint glass etchings.
    const ribsCount = 5;
    const ribSpacing = 5.0;
    final startX = w - (ribsCount * ribSpacing) - 8;
    final ribTop = h * 0.2;
    final ribBottom = h * 0.8;
    final ribLight = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1;
    final ribDark = Paint()
      ..color = const Color(0x1A2A1E46)
      ..strokeWidth = 1;
    for (int i = 0; i < ribsCount; i++) {
      final x = startX + i * ribSpacing;
      canvas.drawLine(Offset(x, ribTop), Offset(x, ribBottom), ribLight);
      canvas.drawLine(Offset(x + 1, ribTop), Offset(x + 1, ribBottom), ribDark);
    }

    // Top glaze band.
    if (p < 0.99) {
      final g = 1 - p;
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h * 0.5),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(0, h * 0.5),
            [
              Colors.white.withValues(alpha: 0.5 * g),
              Colors.white.withValues(alpha: 0.0),
            ],
          ),
      );
      canvas.restore();
    }

    // Lit rim, brightest along the top.
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, h),
          [
            Colors.white.withValues(alpha: 0.85),
            Colors.white.withValues(alpha: 0.15),
          ],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EjectPainter old) => false;
}
