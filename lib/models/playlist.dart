import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/image_pick.dart';
import 'cassette_tape.dart';

/// Where a row on the Explore wheel gets its tracks from. Not every row is a
/// playlist: your saved songs and your listening history are shelves Spotify
/// keeps for you, reached through their own endpoints.
enum PlaylistKind {
  /// A real playlist — `/playlists/{id}/items`.
  spotify,

  /// Saved songs — `/me/tracks`.
  liked,

  /// Listening history — `/me/player/recently-played`.
  recent,

  /// The built-in starter mixtape; preloaded, never fetched.
  demo,
}

/// A row on the Explore wheel. Tracks are loaded lazily the first time it is
/// opened, from whichever endpoint its [kind] names.
class Playlist {
  final String id;
  final String name;
  final String owner;
  final String ownerId;
  final int trackCount;
  final Color accent;
  final PlaylistKind kind;

  /// Playlist cover, sized for the round thumbnail on Explore. Null when
  /// Spotify has no art for it (or for the offline starter mixtape), in which
  /// case the UI paints an accent-coloured disc instead.
  final String? imageUrl;

  List<CassetteTape>? tapes; // null until loaded
  bool loading = false;
  String? loadError; // set when a load returns no usable tapes

  /// The Spotify context URI for this playlist, or null when there is no
  /// playlist behind the row — saved songs, history and the starter mixtape
  /// are not playlists, and inventing `spotify:playlist:liked` for them would
  /// be a URI Spotify has never heard of.
  String? get contextUri =>
      kind == PlaylistKind.spotify ? 'spotify:playlist:$id' : null;

  Playlist({
    required this.id,
    required this.name,
    required this.owner,
    required this.ownerId,
    required this.trackCount,
    required this.accent,
    this.imageUrl,
    this.kind = PlaylistKind.spotify,
  });

  /// Your saved songs. Every account has them, and unlike a playlist they are
  /// always readable — the Feb 2026 restriction on other people's playlists
  /// does not apply to your own library.
  factory Playlist.liked({int total = 0}) => Playlist(
        id: 'liked',
        name: 'Liked Songs',
        owner: 'You',
        ownerId: '',
        trackCount: total,
        accent: kTapePalette[3].stripe,
        kind: PlaylistKind.liked,
      );

  /// The last songs you played, newest first. Spotify only keeps a short
  /// window of these, so the length is not known until it is fetched.
  factory Playlist.recentlyPlayed() => Playlist(
        id: 'recent',
        name: 'Recently Played',
        owner: 'You',
        ownerId: '',
        trackCount: 0,
        accent: kTapePalette[4].stripe,
        kind: PlaylistKind.recent,
      );

  /// The built-in starter mixtape: a drawer that works with no Spotify account
  /// so the cabinet is never empty. Its five tapes are preloaded (no fetch) and
  /// carry real track URIs, so they also play for real once connected.
  factory Playlist.demo() {
    final demo = Playlist(
      id: 'demo',
      name: 'Starter Mixtape',
      owner: 'Cassette',
      ownerId: '',
      trackCount: CassetteTape.demoTapes.length,
      accent: kTapePalette[0].stripe,
      kind: PlaylistKind.demo,
    );
    demo.tapes = CassetteTape.demoTapes;
    return demo;
  }

  /// The playlist's track total, wherever this API version put it: the
  /// classic `tracks.total`, the renamed `items.total` (Feb 2026), or a flat
  /// `item_count`. Missing entirely → 0.
  static int _totalOf(Map<String, dynamic> json) {
    for (final key in ['tracks', 'items']) {
      final nested = json[key];
      if (nested is Map && nested['total'] is int) {
        return nested['total'] as int;
      }
    }
    return (json['item_count'] as int?) ?? 0;
  }

  factory Playlist.fromJson(Map<String, dynamic> json, int index) {
    final owner = json['owner'] as Map<String, dynamic>? ?? {};
    return Playlist(
      id: json['id'] as String? ?? 'pl_$index',
      name: json['name'] as String? ?? 'Untitled',
      owner: owner['display_name'] as String? ?? 'Spotify',
      ownerId: owner['id'] as String? ?? '',
      trackCount: _totalOf(json),
      accent: kTapePalette[index % kTapePalette.length].stripe,
      imageUrl: ImagePick.bestUrl(
        (json['images'] as List?) ?? const [],
        targetWidth: 200,
      ),
    );
  }
}
