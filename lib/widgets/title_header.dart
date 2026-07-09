import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/cassette_tape.dart';
import '../services/palette_service.dart';
import '../utils/colors.dart';

/// Marquee-scrolling title bar styled as a cassette J-card spine
/// (reference `VintageTitleHeader`).
class VintageTitleHeader extends StatefulWidget {
  final CassetteTape tape;
  final TapeState tapeState;

  const VintageTitleHeader({
    super.key,
    required this.tape,
    required this.tapeState,
  });

  @override
  State<VintageTitleHeader> createState() => _VintageTitleHeaderState();
}

class _VintageTitleHeaderState extends State<VintageTitleHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _marquee =
      AnimationController(vsync: this, duration: const Duration(seconds: 15));

  String? _lastText;
  late TextPainter _text;
  late Color _stripe = widget.tape.stripeColor;
  late final TextPainter _sideA = TextPainter(
    text: const TextSpan(
      text: 'A',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  String get _displayText => switch (widget.tapeState) {
        TapeState.stopped => 'STOPPED',
        TapeState.ff => 'FAST FORWARD >>',
        TapeState.rew => '<< REWINDING',
        TapeState.playing =>
          '${widget.tape.artistName} - ${widget.tape.trackName} (${widget.tape.year})        '
              .toUpperCase(),
      };

  void _syncText() {
    final text = _displayText;
    if (text == _lastText) return;
    _lastText = text;
    _text = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: kTextDark,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
  }

  void _syncMarquee() {
    if (widget.tapeState == TapeState.playing) {
      if (!_marquee.isAnimating) _marquee.repeat();
    } else {
      _marquee.stop();
    }
  }

  @override
  void initState() {
    super.initState();
    _syncText();
    _syncMarquee();
    _resolveStripe();
  }

  void _resolveStripe() {
    final url = widget.tape.albumArtUrl;
    final cached = PaletteService.cached(url);
    if (cached != null) {
      _stripe = cached.stripe;
    } else if (url != null && url.isNotEmpty) {
      PaletteService.resolve(url).then((c) {
        if (mounted && c != null) setState(() => _stripe = c.stripe);
      });
    }
  }

  @override
  void didUpdateWidget(VintageTitleHeader old) {
    super.didUpdateWidget(old);
    _syncText();
    _syncMarquee();
  }

  @override
  void dispose() {
    _marquee.dispose();
    _text.dispose();
    _sideA.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: CustomPaint(
          painter: _HeaderPainter(
            stripeColor: _stripe,
            text: _text,
            sideA: _sideA,
            playing: widget.tapeState == TapeState.playing,
            t: _marquee,
          ),
        ),
      ),
    );
  }
}

class _HeaderPainter extends CustomPainter {
  final Color stripeColor;
  final TextPainter text;
  final TextPainter sideA;
  final bool playing;
  final Animation<double> t;

  _HeaderPainter({
    required this.stripeColor,
    required this.text,
    required this.sideA,
    required this.playing,
    required this.t,
  }) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cream card with side shading.
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF4EFE6));
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(w, 0),
          const [
            Color(0x1A000000),
            Colors.transparent,
            Colors.transparent,
            Color(0x1A000000),
          ],
          const [0.0, 1 / 3, 2 / 3, 1.0],
        ),
    );

    // Colored spine stripe on the left edge.
    const stripeWidth = 8.0;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, stripeWidth, h), Paint()..color = stripeColor);

    // Side "A" box.
    final boxSize = h * 0.55;
    const boxX = stripeWidth + 8;
    final boxY = (h - boxSize) / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(boxX, boxY, boxSize, boxSize), const Radius.circular(2)),
      Paint()..color = kTextDark,
    );
    sideA.paint(
      canvas,
      Offset(
        boxX + (boxSize - sideA.width) / 2,
        boxY + (boxSize - sideA.height) / 2,
      ),
    );

    // Title text, marquee-scrolled while playing.
    final textStartX = boxX + boxSize + 12;
    final textY = (h - text.height) / 2;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(textStartX, 0, w, h));
    if (playing) {
      final scroll = -t.value * text.width;
      text.paint(canvas, Offset(textStartX + scroll, textY));
      text.paint(canvas, Offset(textStartX + scroll + text.width, textY));
    } else {
      text.paint(canvas, Offset(textStartX, textY));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeaderPainter old) =>
      old.stripeColor != stripeColor ||
      old.text != text ||
      old.playing != playing;
}
