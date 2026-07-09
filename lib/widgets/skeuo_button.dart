import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';

/// Transport control glyphs for the skeuomorphic button panel.
enum RetroIcon { rec, rew, play, ff, stop, prev, next }

/// Piano-key style transport button with spring-animated press depth and a
/// machined dimple, ported from the reference `AnimatedSkeuoButton`.
class SkeuoButton extends StatefulWidget {
  final RetroIcon icon;
  final bool isRed;
  final bool isToggled;
  final bool enabled;
  final VoidCallback onPressed;

  const SkeuoButton({
    super.key,
    required this.icon,
    this.isRed = false,
    this.isToggled = false,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  State<SkeuoButton> createState() => _SkeuoButtonState();
}

class _SkeuoButtonState extends State<SkeuoButton>
    with SingleTickerProviderStateMixin {
  static final SpringDescription _spring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 900, ratio: 0.55);

  late final AnimationController _depth = AnimationController.unbounded(
    vsync: this,
    value: widget.isToggled ? 1 : 0,
  );
  bool _pressed = false;

  bool get _visualPress => _pressed || widget.isToggled;

  void _settle() {
    final target = _visualPress ? 1.0 : 0.0;
    _depth.animateWith(
        SpringSimulation(_spring, _depth.value, target, _depth.velocity));
  }

  @override
  void didUpdateWidget(SkeuoButton old) {
    super.didUpdateWidget(old);
    if (old.isToggled != widget.isToggled) _settle();
  }

  @override
  void dispose() {
    _depth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1 : 0.4,
      child: Column(
        children: [
          SizedBox(
            height: 20,
            width: double.infinity,
            child: CustomPaint(painter: _IconPainter(widget.icon)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTapDown: widget.enabled
                ? (_) {
                    _pressed = true;
                    HapticFeedback.lightImpact();
                    _settle();
                  }
                : null,
            onTapUp: widget.enabled
                ? (_) {
                    _pressed = false;
                    HapticFeedback.selectionClick();
                    _settle();
                    widget.onPressed();
                  }
                : null,
            onTapCancel: widget.enabled
                ? () {
                    _pressed = false;
                    _settle();
                  }
                : null,
            child: SizedBox(
              height: 76,
              width: double.infinity,
              child: CustomPaint(
                painter: _KeyPainter(isRed: widget.isRed, depth: _depth),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  final RetroIcon icon;

  const _IconPainter(this.icon);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    drawRetroIcon(canvas, icon, kMark, size.height * 0.35);
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.icon != icon;
}

/// Renders transport icons as raw vector paths (reference `drawWalkmanIcon`).
void drawRetroIcon(Canvas canvas, RetroIcon icon, Color color, double s) {
  final paint = Paint()..color = color;
  switch (icon) {
    case RetroIcon.rec:
      canvas.drawCircle(Offset.zero, s * 0.9, paint);
    case RetroIcon.play:
      canvas.drawPath(
        Path()
          ..moveTo(-s * 0.7, -s)
          ..lineTo(s * 0.9, 0)
          ..lineTo(-s * 0.7, s)
          ..close(),
        paint,
      );
    case RetroIcon.stop:
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-s * 0.8, -s * 0.8, s * 1.6, s * 1.6),
            const Radius.circular(1)),
        paint,
      );
    case RetroIcon.rew:
      canvas.drawPath(
        Path()
          ..moveTo(s * 0.9, -s)
          ..lineTo(-s * 0.1, 0)
          ..lineTo(s * 0.9, s)
          ..close()
          ..moveTo(-s * 0.1, -s)
          ..lineTo(-s * 1.1, 0)
          ..lineTo(-s * 0.1, s)
          ..close(),
        paint,
      );
    case RetroIcon.ff:
      canvas.drawPath(
        Path()
          ..moveTo(-s * 0.9, -s)
          ..lineTo(s * 0.1, 0)
          ..lineTo(-s * 0.9, s)
          ..close()
          ..moveTo(s * 0.1, -s)
          ..lineTo(s * 1.1, 0)
          ..lineTo(s * 0.1, s)
          ..close(),
        paint,
      );
    case RetroIcon.prev:
      // Two left-facing triangles with a leading bar (skip-previous).
      canvas.drawRect(
        Rect.fromLTRB(-s * 1.25, -s, -s * 0.95, s),
        paint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(s * 0.15, -s)
          ..lineTo(-s * 0.85, 0)
          ..lineTo(s * 0.15, s)
          ..close()
          ..moveTo(s * 1.15, -s)
          ..lineTo(s * 0.15, 0)
          ..lineTo(s * 1.15, s)
          ..close(),
        paint,
      );
    case RetroIcon.next:
      // Two right-facing triangles with a trailing bar (skip-next).
      canvas.drawPath(
        Path()
          ..moveTo(-s * 1.15, -s)
          ..lineTo(-s * 0.15, 0)
          ..lineTo(-s * 1.15, s)
          ..close()
          ..moveTo(-s * 0.15, -s)
          ..lineTo(s * 0.85, 0)
          ..lineTo(-s * 0.15, s)
          ..close(),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTRB(s * 0.95, -s, s * 1.25, s),
        paint,
      );
  }
}

class _KeyPainter extends CustomPainter {
  final bool isRed;
  final Animation<double> depth;

  _KeyPainter({required this.isRed, required this.depth})
      : super(repaint: depth);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const corner = 6.0;
    final p = depth.value.clamp(0.0, 1.0);

    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(corner));

    // Dark socket base.
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF070707));
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, h),
          const [Colors.black, Color(0x88000000), Color(0x22FFFFFF)],
          const [0.0, 0.5, 1.0],
        ),
    );

    final base0 = Color.lerp(
      isRed ? const Color(0xFFE86658) : const Color(0xFFF7F1E6),
      isRed ? const Color(0xFFC75549) : const Color(0xFFDCD5C6),
      p,
    )!;
    final base1 = Color.lerp(
      isRed ? const Color(0xFFC75549) : const Color(0xFFE3DCCF),
      isRed ? const Color(0xFF9E3A30) : const Color(0xFFC4BCAB),
      p,
    )!;

    final scale = 1 - p * 0.035;
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.scale(scale);
    canvas.translate(-w / 2, -h / 2);

    // Drop shadow that tightens as the key is pressed.
    final shadowRadius = (1 - p) * 12 + p * 1.5;
    final shadowY = (1 - p) * 8 + p * 0.5;
    final shadowAlpha = ((1 - p) * 130 + p * 240).round();
    canvas.drawRRect(
      rrect.shift(Offset(0, shadowY)),
      Paint()
        ..color = Color.fromARGB(shadowAlpha, 0, 0, 0)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowRadius * 0.5),
    );

    // Key face.
    canvas.drawRRect(
      rrect,
      Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, h), [base0, base1]),
    );

    // Machined dimple.
    final dimpleR = w * 0.35;
    final center = Offset(w / 2, h / 2);
    final dimpleDark = Color.lerp(
      isRed ? const Color(0xFF9E382E) : const Color(0xFFCAC2AE),
      isRed ? const Color(0xFF7A2720) : const Color(0xFFA8A08E),
      p,
    )!;
    final dimpleLight = Color.lerp(
      isRed ? const Color(0xFFF0796C) : Colors.white,
      isRed ? const Color(0xFFD95D50) : const Color(0xFFDED6C4),
      p,
    )!;
    canvas.drawCircle(
      center,
      dimpleR,
      Paint()
        ..shader = ui.Gradient.linear(
          center - Offset(dimpleR, dimpleR),
          center + Offset(dimpleR, dimpleR),
          [dimpleDark, dimpleLight],
        ),
    );
    canvas.drawCircle(
      center,
      dimpleR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x15000000),
    );

    // Bevel highlight, fading out as the key sinks.
    if (p < 0.99) {
      final la = (1 - p * 2).clamp(0.0, 1.0);
      final lightBevel =
          (isRed ? const Color(0xFFF2897E) : Colors.white).withValues(alpha: la);
      final darkBevel = (isRed ? const Color(0xFFA63B30) : const Color(0xFFB5AFA1))
          .withValues(alpha: la);
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(w, h),
            [lightBevel, Colors.transparent, darkBevel],
            const [0.0, 0.5, 1.0],
          ),
      );
    }
    canvas.restore();

    // Pressed-in inner shadow.
    if (p > 0.01) {
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, 14),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            const Offset(0, 14),
            [
              Colors.black.withValues(alpha: p),
              Colors.black.withValues(alpha: 0.53 * p),
              Colors.transparent,
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * p
          ..color = Colors.black.withValues(alpha: p * 0.8),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_KeyPainter old) => old.isRed != isRed;
}
