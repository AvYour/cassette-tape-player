/// Pure playback maths, extracted from the player so it can be unit-tested and
/// kept cheap on the per-frame path.
///
/// The lyric-line lookup takes an optional [hint] (the last known line) so the
/// player can scan forward from there each frame instead of rescanning the
/// whole timestamp list from zero — O(1) amortised while playing forward,
/// instead of O(n) every frame.
class PlaybackMath {
  const PlaybackMath._();

  /// Index of the active lyric line for [positionMs] given ascending [times].
  /// Returns the greatest i where `times[i] <= positionMs` (0 if before all).
  ///
  /// [hint] is the previous result; scanning starts near it so ordinary
  /// forward playback doesn't re-walk the list from the start. The answer is
  /// identical regardless of the hint.
  static int lyricLineIndex(List<int> times, num positionMs, {int hint = 0}) {
    if (times.isEmpty) return 0;
    final last = times.length - 1;
    var i = hint.clamp(0, last);
    // If the hint sits ahead of the current position, walk back to a valid spot.
    while (i > 0 && times[i] > positionMs) {
      i--;
    }
    // Advance while the next line has already started.
    while (i < last && times[i + 1] <= positionMs) {
      i++;
    }
    return i;
  }

  /// Fractional lyric progress in `[0, lineCount-1]`.
  ///
  /// When [times] is non-null and its length equals [lineCount], the reel is
  /// placed by timestamp (interpolating between lines); otherwise it is spread
  /// proportionally across [durationMs]. [hint] speeds up the synced lookup.
  static double lyricProgress(
    num positionMs,
    List<int>? times,
    int lineCount,
    int durationMs, {
    int hint = 0,
  }) {
    if (lineCount <= 0) return 0.0;
    final maxProgress = (lineCount - 1).toDouble();
    if (maxProgress <= 0) return 0.0;

    if (times != null && times.length == lineCount) {
      final i = lyricLineIndex(times, positionMs, hint: hint);
      double frac = 0;
      if (i < times.length - 1) {
        final span = times[i + 1] - times[i];
        if (span > 0) {
          frac = ((positionMs - times[i]) / span).clamp(0.0, 1.0);
        }
      }
      return (i + frac).clamp(0.0, maxProgress);
    }

    if (durationMs <= 0) return 0.0;
    final ratio = positionMs / durationMs;
    return (ratio * maxProgress).clamp(0.0, maxProgress);
  }

  /// Whether it's time to re-sync our position to Spotify's real one. True only
  /// when the poll [intervalMs] has elapsed since [lastPoll] AND we're past
  /// [ignoreUntil] — the guard window after a self-driven track change, during
  /// which Spotify still reports the OLD track's (stale) position.
  static bool shouldReanchorPoll({
    required DateTime now,
    required DateTime lastPoll,
    required DateTime ignoreUntil,
    int intervalMs = 3000,
  }) {
    if (!now.isAfter(ignoreUntil)) return false;
    return now.difference(lastPoll).inMilliseconds > intervalMs;
  }

  /// Whether [positionMs] has reached the tail end of a track that has a real
  /// length — used to auto-advance to the next tape. Short/zero durations are
  /// ignored so we never advance spuriously before playback is anchored.
  static bool reachedEnd(num positionMs, num durationMs) {
    return durationMs > 1000 && positionMs >= durationMs - 250;
  }

  /// Wall-clock interpolated position: [anchorPosMs] plus [elapsedMs], clamped
  /// to `[0, durationMs]`.
  static double interpolatePosition(
      num anchorPosMs, num elapsedMs, num durationMs) {
    return (anchorPosMs + elapsedMs)
        .toDouble()
        .clamp(0.0, durationMs.toDouble());
  }
}
