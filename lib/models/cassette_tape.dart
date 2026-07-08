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
  final int durationMs;

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
    this.durationMs = 210000,
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
      durationMs: (track['duration_ms'] as int?) ?? 210000,
    );
  }

  /// A pre-populated set of tapes so the app is fully explorable (swipe,
  /// simulated playback, spinning reels) without a Spotify connection.
  static List<CassetteTape> get demoTapes => List.unmodifiable(
        _demoData.asMap().entries.map((e) {
          final i = e.key;
          final d = e.value;
          final palette = kTapePalette[i % kTapePalette.length];
          return CassetteTape(
            id: 'demo_$i',
            trackName: d[0],
            artistName: d[1],
            albumName: d[2],
            year: d[3],
            spotifyUri: '',
            bodyColor: palette['body']!,
            stripeColor: palette['stripe']!,
            durationMs: int.parse(d[4]),
          );
        }),
      );

  // trackName, artist, album, year, durationMs
  static const List<List<String>> _demoData = [
    ['Midnight City', 'Neon Cassette', 'Analog Dreams', '1986', '241000'],
    ['Velvet Static', 'The Reel Sessions', 'Warm Hiss', '1979', '198000'],
    ['Ferric Oxide', 'Dolby & The Nightriders', 'Type II', '1983', '224000'],
    ['Slow Rewind', 'Magnetic Fields Co.', 'Auto-Reverse', '1991', '267000'],
    ['Saturday Tape', 'Cassidy Vaughn', 'Mixtape No. 4', '1988', '203000'],
    ['Golden Hour', 'Amber Chrome', 'Sunset Deck', '1976', '189000'],
    ['Chrome Bias', 'Highway 90', 'B-Side Stories', '1985', '215000'],
    ['Last Play', 'The Fadeouts', 'End of Reel', '1993', '252000'],
  ];
}
