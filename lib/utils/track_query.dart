import '../models/cassette_tape.dart';

/// How a track list is ordered.
enum TrackSort {
  /// However the source handed them over — playlist order, or top-songs rank.
  original('In order'),
  title('Title'),
  artist('Artist'),
  length('Length');

  const TrackSort(this.label);
  final String label;
}

/// Narrowing and reordering a track list, in memory. A long playlist is only
/// searchable this way — Spotify has no endpoint for "the songs in this
/// playlist matching X".
class TrackQuery {
  const TrackQuery._();

  /// Tracks whose title or artist contains [query], case-insensitively. An
  /// empty query keeps the list as it was.
  static List<CassetteTape> filter(List<CassetteTape> tapes, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return tapes;
    return [
      for (final t in tapes)
        if (t.trackName.toLowerCase().contains(q) ||
            t.artistName.toLowerCase().contains(q))
          t,
    ];
  }

  /// A copy of [tapes] in [sort] order; the original is left alone.
  static List<CassetteTape> sort(List<CassetteTape> tapes, TrackSort sort) {
    if (sort == TrackSort.original) return tapes;
    final copy = List<CassetteTape>.from(tapes);
    switch (sort) {
      case TrackSort.title:
        copy.sort((a, b) =>
            a.trackName.toLowerCase().compareTo(b.trackName.toLowerCase()));
      case TrackSort.artist:
        copy.sort((a, b) =>
            a.artistName.toLowerCase().compareTo(b.artistName.toLowerCase()));
      case TrackSort.length:
        copy.sort((a, b) => a.durationMs.compareTo(b.durationMs));
      case TrackSort.original:
        break;
    }
    return copy;
  }
}
