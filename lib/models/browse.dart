import 'cassette_tape.dart';
import '../utils/image_pick.dart';

/// A search-result album: enough to show a row and open it. Playing it uses
/// the album context URI.
class AlbumBrief {
  final String id;
  final String name;
  final String artistName;
  final String? imageUrl;

  const AlbumBrief({
    required this.id,
    required this.name,
    required this.artistName,
    this.imageUrl,
  });

  String get contextUri => 'spotify:album:$id';

  factory AlbumBrief.fromJson(Map<String, dynamic> json) {
    final artists =
        (json['artists'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return AlbumBrief(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled',
      artistName: artists.isNotEmpty
          ? artists.first['name'] as String? ?? ''
          : '',
      imageUrl: ImagePick.bestUrl(
        (json['images'] as List?) ?? const [],
        targetWidth: 200,
      ),
    );
  }
}

/// A search-result artist: name, picture, and the id needed to fetch their
/// albums.
class ArtistBrief {
  final String id;
  final String name;
  final String? imageUrl;

  const ArtistBrief({required this.id, required this.name, this.imageUrl});

  factory ArtistBrief.fromJson(Map<String, dynamic> json) => ArtistBrief(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Unknown',
        imageUrl: ImagePick.bestUrl(
          (json['images'] as List?) ?? const [],
          targetWidth: 200,
        ),
      );
}

/// One search's worth of results across the three types the app browses.
class SearchResults {
  final List<CassetteTape> tracks;
  final List<ArtistBrief> artists;
  final List<AlbumBrief> albums;

  const SearchResults({
    this.tracks = const [],
    this.artists = const [],
    this.albums = const [],
  });

  bool get isEmpty => tracks.isEmpty && artists.isEmpty && albums.isEmpty;

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> itemsOf(String key) =>
        ((json[key] as Map<String, dynamic>?)?['items'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .where((m) => m['id'] != null)
            .toList() ??
        const [];

    final tracks = <CassetteTape>[];
    for (final t in itemsOf('tracks')) {
      try {
        tracks.add(CassetteTape.fromSpotifyTrack(t, tracks.length));
      } catch (_) {}
    }
    return SearchResults(
      tracks: tracks,
      artists: [for (final a in itemsOf('artists')) ArtistBrief.fromJson(a)],
      albums: [for (final a in itemsOf('albums')) AlbumBrief.fromJson(a)],
    );
  }
}

/// Pure parsing for browse payloads whose track shape differs from search.
class BrowseParsing {
  const BrowseParsing._();

  /// Cassettes for one album from a `GET /albums/{id}` payload. The album's
  /// track list holds *simplified* tracks with no album of their own, so the
  /// cover, album name and year are lifted from the envelope and injected into
  /// each one before it becomes a tape.
  static List<CassetteTape> albumTapes(Map<String, dynamic> album) {
    final items = (album['tracks'] as Map<String, dynamic>?)?['items'] as List?;
    if (items == null) return const [];
    final images = (album['images'] as List?) ?? const [];
    final albumName = album['name'] as String? ?? '';
    final releaseDate = album['release_date'] as String? ?? '';
    final tapes = <CassetteTape>[];
    for (final raw in items) {
      if (raw is! Map<String, dynamic> || raw['id'] == null) continue;
      // Graft the album onto the simplified track so fromSpotifyTrack finds
      // the cover and album name where it expects them.
      final track = {
        ...raw,
        'album': {
          'name': albumName,
          'release_date': releaseDate,
          'images': images,
        },
      };
      try {
        tapes.add(CassetteTape.fromSpotifyTrack(track, tapes.length));
      } catch (_) {}
    }
    return tapes;
  }
}
