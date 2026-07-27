import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/lru_cache.dart';

/// Artist biographies from Wikipedia's public REST summary endpoint.
///
/// Spotify's Web API exposes genres and followers but no biography at all, so
/// the "About" paragraph comes from here or not at all. No key, no account —
/// it is a plain public GET.
class WikiService {
  const WikiService._();

  // Bios per artist name, misses included, so reopening an artist doesn't
  // refetch a 404 every time.
  static final LruCache<String?> _cache = LruCache<String?>(capacity: 100);

  /// The Wikipedia title path for [name]: spaces become underscores (that is
  /// how titles are written) and the rest is percent-encoded. Blank in, blank
  /// out — the caller then knows not to ask.
  static String titleFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    return Uri.encodeComponent(trimmed.replaceAll(' ', '_'));
  }

  /// Pulls a usable biography out of a summary payload.
  ///
  /// Returns null for a disambiguation page — "XG may refer to…" is a list of
  /// options, not a biography — and for anything without real extract text.
  static String? bioFrom(Map<String, dynamic> json) {
    if (json['type'] == 'disambiguation') return null;
    final extract = json['extract'];
    if (extract is! String) return null;
    final text = extract.trim();
    return text.isEmpty ? null : text;
  }

  /// The opening paragraph of [name]'s Wikipedia article, or null when there
  /// is no usable one (no article, or a disambiguation page).
  static Future<String?> bio(String name) async {
    final title = titleFor(name);
    if (title.isEmpty) return null;
    if (_cache.containsKey(title)) return _cache.get(title);
    final result = await _summary(title);
    _cache.put(title, result);
    return result;
  }

  /// Strips the parts of a Spotify track name that no encyclopedia article
  /// carries: a version suffix after a dash ("- Remastered", "- 2011 Remaster")
  /// and a featured-artist parenthetical. A parenthetical that is part of the
  /// title, like "Exit Music (For A Film)", is left alone.
  static String cleanTrackTitle(String track) {
    var t = track.trim();
    final dash = t.indexOf(' - ');
    if (dash > 0) t = t.substring(0, dash);
    t = t.replaceAll(
        RegExp(r'\s*\((?:feat\.?|ft\.?|with)\s[^)]*\)', caseSensitive: false),
        '');
    return t.trim();
  }

  /// Wikipedia titles worth trying for a song, most trustworthy first.
  ///
  /// The artist-qualified title can only be this artist's song. The other two
  /// are guesses — a famous song often sits at its bare title ("Take Me Home,
  /// Country Roads"), but so does "Photograph", which is an article about
  /// photographs. [songBio] only accepts those when the text names the artist.
  static List<String> songTitleCandidates(String track, String artist) {
    final t = cleanTrackTitle(track);
    final a = artist.trim();
    if (t.isEmpty || a.isEmpty) return const [];
    return ['$t ($a song)', '$t (song)', t];
  }

  /// Whether [extract] actually names [artist] — the guard on the unqualified
  /// "(song)" article, which may belong to somebody else entirely.
  static bool mentionsArtist(String extract, String artist) {
    final a = artist.trim().toLowerCase();
    if (a.isEmpty) return false;
    return extract.toLowerCase().contains(a);
  }

  /// A paragraph about the song itself — what it is, when it came out, what it
  /// is known for. Null when Wikipedia has no article that is confidently
  /// about this song by this artist.
  static Future<String?> songBio(String track, String artist) async {
    final candidates = songTitleCandidates(track, artist);
    if (candidates.isEmpty) return null;
    final key = 'song::${candidates.first}';
    if (_cache.containsKey(key)) return _cache.get(key);

    String? result;
    for (var i = 0; i < candidates.length; i++) {
      final text = await _summary(titleFor(candidates[i]));
      if (text == null) continue;
      // The artist-qualified title can only be this artist's song; the looser
      // ones have to prove they name them before we believe it is the song.
      if (i == 0 || mentionsArtist(text, artist)) {
        result = text;
        break;
      }
    }
    _cache.put(key, result);
    return result;
  }

  /// One summary fetch, reduced to a usable paragraph or null.
  static Future<String?> _summary(String title) async {
    if (title.isEmpty) return null;
    try {
      final res = await http.get(
        Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/$title'),
        // Wikimedia asks clients to identify themselves.
        headers: const {'User-Agent': 'CassetteTapePlayer/1.0'},
      );
      if (res.statusCode != 200) return null;
      return bioFrom(
          json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
