/// Full track details from the Spotify Web API (plus the primary artist's
/// profile), shown as the cassette's liner notes.
class TrackInfo {
  final String title;
  final List<String> artists;
  final String albumName;
  final String releaseYear;
  final int durationMs;
  final int trackNumber;
  final bool explicit;
  final int popularity; // 0..100
  final List<String> genres; // primary artist's genres
  final int? artistFollowers;

  const TrackInfo({
    required this.title,
    required this.artists,
    required this.albumName,
    required this.releaseYear,
    required this.durationMs,
    required this.trackNumber,
    required this.explicit,
    required this.popularity,
    required this.genres,
    required this.artistFollowers,
  });

  String get artistsLine => artists.join(', ');

  factory TrackInfo.fromJson(Map<String, dynamic> track,
      {Map<String, dynamic>? artistJson}) {
    final album = track['album'] as Map<String, dynamic>? ?? {};
    final artists = ((track['artists'] as List?) ?? [])
        .whereType<Map>()
        .map((a) => a['name'])
        .whereType<String>()
        .toList();
    final followers = artistJson?['followers'];
    return TrackInfo(
      title: track['name'] as String? ?? '',
      artists: artists,
      albumName: album['name'] as String? ?? '',
      releaseYear: ((album['release_date'] as String?) ?? '').split('-').first,
      durationMs: (track['duration_ms'] as int?) ?? 0,
      trackNumber: (track['track_number'] as int?) ?? 0,
      explicit: (track['explicit'] as bool?) ?? false,
      popularity: _popularityOf(track),
      genres:
          ((artistJson?['genres'] as List?) ?? []).whereType<String>().toList(),
      artistFollowers: followers is Map ? followers['total'] as int? : null,
    );
  }

  /// Popularity, wherever this API version put it: the classic top-level
  /// `popularity` (int or numeric string), nested under `stats`/`statistics`,
  /// or a flat `popularity_index`. Missing entirely → 0.
  static int _popularityOf(Map<String, dynamic> track) {
    int? asInt(Object? v) =>
        v is int ? v : (v is String ? int.tryParse(v) : null);

    final direct = asInt(track['popularity']);
    if (direct != null) return direct;
    for (final key in ['stats', 'statistics']) {
      final nested = track[key];
      if (nested is Map) {
        final p = asInt(nested['popularity']);
        if (p != null) return p;
      }
    }
    return asInt(track['popularity_index']) ?? 0;
  }

  /// 1234567 → '1,234,567'.
  static String formatCount(int n) {
    final s = n.toString();
    final out = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }
}
