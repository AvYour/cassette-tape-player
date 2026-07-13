/// Scrubbing by dragging the cassette itself: one full cassette-width of drag
/// winds the whole tape. Pure mapping, kept out of the widget for testing.
class ScrubMath {
  const ScrubMath._();

  /// New position after dragging [dragDx] pixels across a cassette
  /// [trackWidth] pixels wide, starting from [startMs]. Clamped to the tape.
  static double positionAfterDrag({
    required double startMs,
    required double dragDx,
    required double trackWidth,
    required int durationMs,
  }) {
    final dur = durationMs.toDouble();
    if (dur <= 0) return 0;
    if (trackWidth <= 0) return startMs.clamp(0.0, dur);
    return (startMs + (dragDx / trackWidth) * dur).clamp(0.0, dur);
  }
}
