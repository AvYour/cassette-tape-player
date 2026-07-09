import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/cassette_tape.dart';
import '../services/palette_service.dart';

/// A living backdrop for the player: large soft blobs of the track's palette
/// that flow AND shift hue as the lyrics progress, so the colour visibly
/// transitions through the album's palette over the course of the song.
class DynamicMusicBackground extends StatefulWidget {
  final CassetteTape tape;

  /// Lyric line progress (0..lines-1); drives the colour transition.
  final ValueListenable<double> progress;
  final Widget child;

  const DynamicMusicBackground({
    super.key,
    required this.tape,
    required this.progress,
    required this.child,
  });

  @override
  State<DynamicMusicBackground> createState() => _DynamicMusicBackgroundState();
}

class _DynamicMusicBackgroundState extends State<DynamicMusicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: const Duration(seconds: 10))
        ..repeat();

  List<Color> _swatches = const [Color(0xFFD94532), Color(0xFF1E3A5F)];

  @override
  void initState() {
    super.initState();
    _resolveSwatches();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DynamicMusicBackground old) {
    super.didUpdateWidget(old);
    if (old.tape.id != widget.tape.id) _resolveSwatches();
  }

  void _resolveSwatches() {
    final url = widget.tape.albumArtUrl;
    final cached = PaletteService.cachedSwatches(url);
    if (cached != null) {
      _swatches = cached;
    } else {
      // Fallback until resolved.
      _swatches = [widget.tape.stripeColor, widget.tape.bodyColor];
      if (url != null && url.isNotEmpty) {
        PaletteService.resolveSwatches(url).then((s) {
          if (mounted && s != null) setState(() => _swatches = s);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_drift, widget.progress]),
      builder: (context, _) {
        return CustomPaint(
          painter: _FlowPainter(
            swatches: _swatches,
            colorPhase: widget.progress.value * 0.55,
            t: _drift.value,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _FlowPainter extends CustomPainter {
  final List<Color> swatches;
  final double colorPhase; // advances with lyric progress
  final double t; // 0..1 drift phase

  _FlowPainter({
    required this.swatches,
    required this.colorPhase,
    required this.t,
  });

  /// Samples the palette at a fractional index, wrapping and blending.
  Color _sample(double phase) {
    final n = swatches.length;
    final p = phase % n;
    final i = p.floor();
    final f = p - i;
    return Color.lerp(swatches[i % n], swatches[(i + 1) % n], f)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;
    final maxDim = size.longestSide;
    final n = swatches.length;

    // Light, neutral base — no brown wash behind the lyrics.
    canvas.drawRect(rect, Paint()..color = const Color(0xFFF3F1EE));

    // Blob colours sampled at spread-out phases so the whole palette shows,
    // and all of them advance together with the lyric progress.
    final c1 = _sample(colorPhase);
    final c2 = _sample(colorPhase + n / 3);
    final c3 = _sample(colorPhase + 2 * n / 3);

    final a = 2 * math.pi * t;
    _blob(canvas, Offset(w * (0.30 + 0.20 * math.cos(a)),
        h * (0.26 + 0.16 * math.sin(a * 1.1))), maxDim * 0.62, c1);
    _blob(canvas, Offset(w * (0.74 + 0.18 * math.cos(a * 0.8 + 2)),
        h * (0.42 + 0.20 * math.sin(a + 1))), maxDim * 0.7, c2);
    _blob(canvas, Offset(w * (0.5 + 0.24 * math.cos(a * 1.3 + 4)),
        h * (0.78 + 0.14 * math.sin(a * 0.9 + 3))), maxDim * 0.66, c3);

    // Gentle sheen to keep contrast for the UI.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, h),
          const [Color(0x22FFFFFF), Colors.transparent, Color(0x0F000000)],
          const [0.0, 0.5, 1.0],
        ),
    );
  }

  void _blob(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [color.withValues(alpha: 0.42), color.withValues(alpha: 0)],
        ),
    );
  }

  @override
  bool shouldRepaint(_FlowPainter old) =>
      old.t != t ||
      old.colorPhase != colorPhase ||
      !identical(old.swatches, swatches);
}
