import '../models/cassette_tape.dart';

/// Turns one page of a Spotify playlist `/items` response into cassettes,
/// tagging each with its TRUE playlist position (`contextIndex`). Filtered
/// entries (episodes, null/garbage) are skipped WITHOUT shifting the positions
/// of the tracks that remain — so context playback via `skipToIndex` lands on
/// the right track.
class PlaylistPaging {
  const PlaylistPaging._();

  static List<CassetteTape> tapesFromPage(
    List<dynamic> items, {
    required int pageOffset,
  }) {
    final tapes = <CassetteTape>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Map) continue;
      // Feb 2026: the track lives under 'item' ('track' is deprecated/legacy).
      final raw = item['item'] ?? item['track'];
      if (raw is Map<String, dynamic> &&
          raw['id'] != null &&
          raw['type'] != 'episode' &&
          // Drop tracks Spotify has since made unplayable (removed/region-
          // locked) — they're "ghosts" that can't play. `is_playable` is only
          // present when a market is applied; absent means assume playable.
          raw['is_playable'] != false) {
        final pos = pageOffset + i;
        try {
          tapes.add(
              CassetteTape.fromSpotifyTrack(raw, pos, contextIndex: pos));
        } catch (_) {}
      }
    }
    return tapes;
  }

  /// Collapses repeats, keeping the first of each track id. Recently-played is
  /// a play *history*: put a song on four times and it comes back four times,
  /// which reads as a stutter rather than a shelf.
  static List<CassetteTape> dedupeById(List<CassetteTape> tapes) {
    final seen = <String>{};
    return [
      for (final tape in tapes)
        if (seen.add(tape.id)) tape,
    ];
  }
}
