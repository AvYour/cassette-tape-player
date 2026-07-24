import 'dart:ui' show lerpDouble;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';

/// Center-focused scrolling lyric reel (reference `VintageReelsLyrics`):
/// the active line is larger and darker, neighbours shrink and fade, and the
/// whole column winds with the tape via [progress] (in line units).
class VintageLyrics extends StatelessWidget {
  final List<String> lyrics;
  final ValueListenable<double> progress;

  const VintageLyrics({super.key, required this.lyrics, required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0.0, 0.25, 0.75, 1.0],
        ).createShader(rect),
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, _) => CustomPaint(
            painter: _LyricsPainter(lyrics: lyrics, progress: progress.value),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _LyricsPainter extends CustomPainter {
  final List<String> lyrics;
  final double progress;

  const _LyricsPainter({required this.lyrics, required this.progress});

  static const double _lineHeight = 50;
  static const double _maxScale = 1.1;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    for (int i = 0; i < lyrics.length; i++) {
      final distance = (i - progress).abs();
      final scale = lerpDouble(_maxScale, 0.85, (distance / 2).clamp(0.0, 1.0))!;
      final alpha = lerpDouble(1.0, 0.1, (distance / 3).clamp(0.0, 1.0))!;
      if (alpha <= 0.05) continue;
      final color = Color.lerp(kActiveLyricLight, kFadedLyricLight,
          (distance * 1.5).clamp(0.0, 1.0))!;

      final tp = TextPainter(
        text: TextSpan(
          text: lyrics[i],
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            // Plain ink, no glyph shadow: the reel now runs over flat lavender
            // rather than a flowing album wash, so the legibility trick that
            // shadow existed for would only muddy it.
            color: color.withValues(alpha: alpha),
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: size.width / _maxScale);

      final y = centerY + (i - progress) * _lineHeight - tp.height / 2;
      final x = (size.width - tp.width) / 2;

      canvas.save();
      canvas.translate(x + tp.width / 2, y + tp.height / 2);
      canvas.scale(scale);
      canvas.translate(-tp.width / 2, -tp.height / 2);

      tp.paint(canvas, Offset.zero);
      canvas.restore();
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(_LyricsPainter old) =>
      old.progress != progress || old.lyrics != lyrics;
}
