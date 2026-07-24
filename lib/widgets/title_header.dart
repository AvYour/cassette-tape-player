import 'package:flutter/material.dart';
import '../models/cassette_tape.dart';
import '../utils/colors.dart';
import 'glass.dart';

/// The now-playing title on a frosted-glass bar. The song scrolls past like a
/// marquee while it plays; stopped, it shows the transport state. The vintage
/// J-card it replaced — black side tab, coloured spine, cream card — is gone.
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
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: kInkLight,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 16,
      blur: 16,
      fill: 0.42,
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _MarqueePainter(
            text: _text,
            playing: widget.tapeState == TapeState.playing,
            t: _marquee,
          ),
        ),
      ),
    );
  }
}

class _MarqueePainter extends CustomPainter {
  final TextPainter text;
  final bool playing;
  final Animation<double> t;

  static const double _pad = 18;

  _MarqueePainter({
    required this.text,
    required this.playing,
    required this.t,
  }) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    final textY = (size.height - text.height) / 2;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(_pad, 0, size.width - _pad, size.height));
    if (playing) {
      final scroll = -t.value * text.width;
      text.paint(canvas, Offset(_pad + scroll, textY));
      text.paint(canvas, Offset(_pad + scroll + text.width, textY));
    } else {
      text.paint(canvas, Offset(_pad, textY));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarqueePainter old) =>
      old.text != text || old.playing != playing;
}
