import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';
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
                    SoundService.buttonPress();
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
    drawRetroIcon(canvas, icon, kInkLight, size.height * 0.35);
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

    // Socket the key sits in. Pale now — a black well on a white panel read
    // as seven holes punched through it.
    canvas.drawRRect(rrect, Paint()..color = kPanelWell);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, h),
          const [Color(0x22000000), Color(0x11000000), Color(0x66FFFFFF)],
          const [0.0, 0.5, 1.0],
        ),
    );

    // A frosted-glass cap instead of a moulded plastic key: translucent white
    // so the panel behind shows through, with a faint rose in the REC key.
    final tint = isRed ? const Color(0xFFE39A91) : Colors.white;

    final scale = 1 - p * 0.035;
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.scale(scale);
    canvas.translate(-w / 2, -h / 2);

    // Drop shadow that tightens as the key is pressed.
    final shadowRadius = (1 - p) * 12 + p * 1.5;
    final shadowY = (1 - p) * 8 + p * 0.5;
    final shadowAlpha = ((1 - p) * 42 + p * 95).round();
    canvas.drawRRect(
      rrect.shift(Offset(0, shadowY)),
      Paint()
        ..color = Color.fromARGB(shadowAlpha, 40, 30, 70)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowRadius * 0.5),
    );

    // Glass body: whiter at rest, dimmer as it sinks in.
    final faceTop = 0.82 - 0.24 * p;
    final faceBot = 0.50 - 0.16 * p;
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, h),
          [tint.withValues(alpha: faceTop), tint.withValues(alpha: faceBot)],
        ),
    );

    // Top glaze: a bright band where light catches the near edge, fading as the
    // key presses in.
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
              Colors.white.withValues(alpha: 0.55 * g),
              Colors.white.withValues(alpha: 0.0),
            ],
          ),
      );
      canvas.restore();
    }

    // Lit rim, brightest along the top edge.
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
