import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'cassette_tape.dart';

/// A Spotify playlist shown as a drawer in the cabinet. Tracks are loaded
/// lazily the first time the drawer is opened.
class Playlist {
  final String id;
  final String name;
  final String owner;
  final String ownerId;
  final int trackCount;
  final Color accent;

  List<CassetteTape>? tapes; // null until loaded
  bool loading = false;
  String? loadError; // set when a load returns no usable tapes

  /// The Spotify context URI for this playlist. Playing this (via
  /// `skipToIndex`) makes Spotify's own queue BE the playlist — like Spotify —
  /// instead of us injecting individual tracks into the user's queue.
  String get contextUri => 'spotify:playlist:$id';

  Playlist({
    required this.id,
    required this.name,
    required this.owner,
    required this.ownerId,
    required this.trackCount,
    required this.accent,
  });

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
    );
    demo.tapes = CassetteTape.demoTapes;
    return demo;
  }

  factory Playlist.fromJson(Map<String, dynamic> json, int index) {
    final owner = json['owner'] as Map<String, dynamic>? ?? {};
    final tracks = json['tracks'] as Map<String, dynamic>? ?? {};
    return Playlist(
      id: json['id'] as String? ?? 'pl_$index',
      name: json['name'] as String? ?? 'Untitled',
      owner: owner['display_name'] as String? ?? 'Spotify',
      ownerId: owner['id'] as String? ?? '',
      trackCount: (tracks['total'] as int?) ?? 0,
      accent: kTapePalette[index % kTapePalette.length].stripe,
    );
  }
}
