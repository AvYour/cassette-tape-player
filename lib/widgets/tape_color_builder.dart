import 'package:flutter/material.dart';
import '../models/cassette_tape.dart';
import '../services/palette_service.dart';
import '../utils/colors.dart';

/// Resolves a tape's colors from its album art (once, cached) and rebuilds when
/// ready. Until then it hands the builder the tape's default palette colors.
class TapeColorBuilder extends StatefulWidget {
  final CassetteTape tape;
  final Widget Function(BuildContext context, TapeColors colors) builder;

  const TapeColorBuilder({
    super.key,
    required this.tape,
    required this.builder,
  });

  @override
  State<TapeColorBuilder> createState() => _TapeColorBuilderState();
}

class _TapeColorBuilderState extends State<TapeColorBuilder> {
  late TapeColors _colors;

  TapeColors get _fallback => TapeColors(
        widget.tape.bodyColor,
        widget.tape.labelColor,
        widget.tape.stripeColor,
      );

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(TapeColorBuilder old) {
    super.didUpdateWidget(old);
    if (old.tape.id != widget.tape.id) _resolve();
  }

  void _resolve() {
    // Use the small thumbnail for palette extraction — decoding the full-res
    // cover for every spine makes the drawer stutter while scrolling.
    final url = widget.tape.thumbUrl;
    final cached = PaletteService.cached(url);
    _colors = cached ?? _fallback;
    if (cached == null && url != null && url.isNotEmpty) {
      PaletteService.resolve(url).then((c) {
        if (mounted && c != null) setState(() => _colors = c);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _colors);
}
