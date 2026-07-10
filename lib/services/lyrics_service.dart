import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/lru_cache.dart';

/// Lyrics for a track: plain lines, optionally with per-line timestamps for
/// synced (karaoke-style) scrolling.
class Lyrics {
  final List<String> lines;
  final List<int>? timesMs; // same length as lines when synced

  const Lyrics(this.lines, {this.timesMs});

  bool get isSynced => timesMs != null;
  bool get isEmpty => lines.isEmpty;
}

/// Fetches lyrics from lrclib.net — a free, key-less, open lyrics database.
class LyricsService {
  /// In-memory cache so reopening a tape is instant and misses aren't refetched
  /// (negative caching). Bounded so a long session can't grow without limit.
  static final LruCache<Lyrics?> _cache = LruCache<Lyrics?>(capacity: 200);

  /// Stable cache key for a track lookup.
  static String cacheKey({
    required String track,
    required String artist,
    String album = '',
    int durationMs = 0,
  }) =>
      '${track.trim().toLowerCase()}|${artist.trim().toLowerCase()}'
      '|${album.trim().toLowerCase()}|${durationMs ~/ 1000}';

  /// Looks up lyrics for a track. Prefers synced lyrics, falls back to plain.
  /// Returns null when nothing is found. Results (including misses) are cached.
  static Future<Lyrics?> fetch({
    required String track,
    required String artist,
    String album = '',
    int durationMs = 0,
  }) async {
    final key = cacheKey(
        track: track, artist: artist, album: album, durationMs: durationMs);
    if (_cache.containsKey(key)) return _cache.get(key);

    final result = await _fetchRemote(
        track: track, artist: artist, album: album, durationMs: durationMs);
    _cache.put(key, result);
    return result;
  }

  static Future<Lyrics?> _fetchRemote({
    required String track,
    required String artist,
    String album = '',
    int durationMs = 0,
  }) async {
    try {
      final uri = Uri.https('lrclib.net', '/api/get', {
        'track_name': track,
        'artist_name': artist,
        if (album.isNotEmpty) 'album_name': album,
        if (durationMs > 0) 'duration': (durationMs ~/ 1000).toString(),
      });
      var res = await http.get(uri, headers: {
        'User-Agent': 'CassetteTapePlayer (Flutter demo)',
      });

      // Exact-match get may 404; fall back to a fuzzy search.
      if (res.statusCode == 404) {
        final searchUri = Uri.https('lrclib.net', '/api/search', {
          'track_name': track,
          'artist_name': artist,
        });
        final sres = await http.get(searchUri, headers: {
          'User-Agent': 'CassetteTapePlayer (Flutter demo)',
        });
        if (sres.statusCode != 200) return null;
        final list = json.decode(sres.body) as List?;
        if (list == null || list.isEmpty) return null;
        return _parse(list.first as Map<String, dynamic>);
      }
      if (res.statusCode != 200) return null;
      return _parse(json.decode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Lyrics? _parse(Map<String, dynamic> json) {
    final synced = json['syncedLyrics'] as String?;
    if (synced != null && synced.trim().isNotEmpty) {
      final parsed = _parseLrc(synced);
      if (parsed != null) return parsed;
    }
    final plain = json['plainLyrics'] as String?;
    if (plain != null && plain.trim().isNotEmpty) {
      final lines =
          plain.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.isNotEmpty) return Lyrics(lines);
    }
    return null;
  }

  /// Parses an LRC string ("[mm:ss.xx] text") into timed lines.
  static Lyrics? _parseLrc(String lrc) {
    final re = RegExp(r'\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]');
    final lines = <String>[];
    final times = <int>[];
    for (final raw in lrc.split('\n')) {
      final match = re.firstMatch(raw);
      if (match == null) continue;
      final text = raw.substring(match.end).trim();
      final min = int.parse(match.group(1)!);
      final sec = int.parse(match.group(2)!);
      final freac = match.group(3);
      final ms = (min * 60 + sec) * 1000 +
          (freac != null ? int.parse(freac.padRight(3, '0')) : 0);
      lines.add(text.isEmpty ? '♪' : text);
      times.add(ms);
    }
    if (lines.isEmpty) return null;
    return Lyrics(lines, timesMs: times);
  }
}
