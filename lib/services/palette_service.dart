import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../utils/colors.dart';

/// Derives a cassette's body/stripe colors from its album art so each tape's
/// shell echoes its cover. Results are cached per image URL.
class PaletteService {
  static final Map<String, TapeColors> _cache = {};
  static final Set<String> _inflight = {};

  static TapeColors? cached(String? url) =>
      (url == null || url.isEmpty) ? null : _cache[url];

  static Future<TapeColors?> resolve(String url) async {
    if (_cache.containsKey(url)) return _cache[url];
    if (_inflight.contains(url)) return null;
    _inflight.add(url);
    try {
      final gen = await PaletteGenerator.fromImageProvider(
        NetworkImage(url),
        size: const Size(100, 100),
        maximumColorCount: 12,
      );
      final body = gen.darkMutedColor?.color ??
          gen.dominantColor?.color ??
          gen.mutedColor?.color;
      if (body == null) return null;
      final stripe = gen.vibrantColor?.color ??
          gen.lightVibrantColor?.color ??
          gen.lightMutedColor?.color ??
          gen.dominantColor?.color ??
          const Color(0xFFD94532);
      final colors = TapeColors(
        _tuneBody(body),
        const Color(0xFFF4EFE6),
        _tuneStripe(stripe),
      );
      _cache[url] = colors;
      return colors;
    } catch (_) {
      return null;
    } finally {
      _inflight.remove(url);
    }
  }

  /// Keep the shell reading as coloured plastic: neither washed-out nor black.
  static Color _tuneBody(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness(hsl.lightness.clamp(0.26, 0.52))
        .withSaturation(hsl.saturation.clamp(0.2, 0.85))
        .toColor();
  }

  /// Keep the stripe punchy and legible against the cream label.
  static Color _tuneStripe(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness(hsl.lightness.clamp(0.4, 0.62))
        .withSaturation(hsl.saturation.clamp(0.45, 1.0))
        .toColor();
  }
}
