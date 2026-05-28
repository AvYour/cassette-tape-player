import 'package:flutter/material.dart';
import '../utils/colors.dart';

enum TapeState { stopped, playing, ff, rew }

class CassetteTape {
  final String id;
  final String trackName;
  final String artistName;
  final String albumName;
  final String year;
  final String? albumArtUrl;
  final String spotifyUri;
  final Color bodyColor;
  final Color stripeColor;

  const CassetteTape({
    required this.id,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    required this.year,
    this.albumArtUrl,
    required this.spotifyUri,
    required this.bodyColor,
    required this.stripeColor,
  });

  factory CassetteTape.fromSpotifyTrack(Map<String, dynamic> track, int index) {
    final palette = kTapePalette[index % kTapePalette.length];
    final album = track['album'] as Map<String, dynamic>? ?? {};
    final artists = (track['artists'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final images = (album['images'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return CassetteTape(
      id: track['id'] as String? ?? 'track_$index',
      trackName: track['name'] as String? ?? 'Unknown Track',
      artistName: artists.isNotEmpty ? artists[0]['name'] as String? ?? 'Unknown Artist' : 'Unknown Artist',
      albumName: album['name'] as String? ?? 'Unknown Album',
      year: ((album['release_date'] as String?) ?? '').split('-').first,
      albumArtUrl: images.isNotEmpty ? images[0]['url'] as String? : null,
      spotifyUri: track['uri'] as String? ?? '',
      bodyColor: palette['body']!,
      stripeColor: palette['stripe']!,
    );
  }

  static List<CassetteTape> get demoTapes => const [
        CassetteTape(
          id: 'demo_1',
          trackName: 'Connect to Spotify',
          artistName: 'Tap button above',
          albumName: 'Demo',
          year: '2024',
          spotifyUri: '',
          bodyColor: Color(0xFFE6DBC4),
          stripeColor: Color(0xFFD94532),
        ),
      ];
}
