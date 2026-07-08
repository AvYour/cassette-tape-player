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
  final Color labelColor;
  final Color stripeColor;
  final int durationMs;
  final List<String> lyrics;

  const CassetteTape({
    required this.id,
    required this.trackName,
    required this.artistName,
    this.albumName = '',
    required this.year,
    this.albumArtUrl,
    required this.spotifyUri,
    required this.bodyColor,
    required this.labelColor,
    required this.stripeColor,
    this.durationMs = 210000,
    required this.lyrics,
  });

  factory CassetteTape.fromSpotifyTrack(Map<String, dynamic> track, int index) {
    final palette = kTapePalette[index % kTapePalette.length];
    final album = track['album'] as Map<String, dynamic>? ?? {};
    final artists =
        (track['artists'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final images = (album['images'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final name = track['name'] as String? ?? 'Unknown Track';
    final artist = artists.isNotEmpty
        ? artists[0]['name'] as String? ?? 'Unknown Artist'
        : 'Unknown Artist';
    final albumName = album['name'] as String? ?? '';
    final year = ((album['release_date'] as String?) ?? '').split('-').first;

    return CassetteTape(
      id: track['id'] as String? ?? 'track_$index',
      trackName: name,
      artistName: artist,
      albumName: albumName,
      year: year,
      albumArtUrl: images.isNotEmpty ? images[0]['url'] as String? : null,
      spotifyUri: track['uri'] as String? ?? '',
      bodyColor: palette.body,
      labelColor: palette.label,
      stripeColor: palette.stripe,
      durationMs: (track['duration_ms'] as int?) ?? 210000,
      lyrics: [
        'Now spinning',
        name,
        artist,
        if (albumName.isNotEmpty) albumName,
        if (year.isNotEmpty) '($year)',
      ],
    );
  }

  /// Built-in tape library so the app is fully explorable offline,
  /// mirroring the reference demo's five-tape lineup.
  static const List<CassetteTape> demoTapes = [
    CassetteTape(
      id: '1',
      trackName: 'Take Me Home, Country Roads',
      artistName: 'John Denver',
      year: '1971',
      spotifyUri: '',
      bodyColor: Color(0xFFE6DBC4),
      labelColor: Color(0xFFF4EFE6),
      stripeColor: Color(0xFFD94532),
      lyrics: [
        'Dust on the dashboard, sun in the pines',
        'An old radio hums down the county lines',
        'Every mile marker knows my name',
        'The valley keeps calling just the same',
        'Roll the windows down, let the evening in',
        'Home is wherever this road has been',
        'Blue hills rising to meet the sky',
        'Carry me back as the fields go by',
        'Take the long way home tonight',
      ],
    ),
    CassetteTape(
      id: '2',
      trackName: 'Dreams',
      artistName: 'Fleetwood Mac',
      year: '1977',
      spotifyUri: '',
      bodyColor: Color(0xFF2A2A2A),
      labelColor: Color(0xFFDCD5C6),
      stripeColor: Color(0xFFD6A033),
      lyrics: [
        'You keep your secrets in a spinning wheel',
        'Round and round till you forget what is real',
        'I hear the rain on a tin-roof night',
        'Chasing echoes of a fading light',
        'Go on and wander where you want to go',
        'The heart remembers what the mind will not know',
        'When the thunder settles you will see',
        'Every road you take leads back to me',
        'Dream a little louder now',
      ],
    ),
    CassetteTape(
      id: '3',
      trackName: 'Here Comes The Sun',
      artistName: 'The Beatles',
      year: '1969',
      spotifyUri: '',
      bodyColor: Color(0xFFE86658),
      labelColor: Color(0xFFF4EFE6),
      stripeColor: Color(0xFF1E3A5F),
      lyrics: [
        'Morning slips over the garden wall',
        'Frost is fading from the windows all',
        'It has been a season of the longest grey',
        'But light is finding its way',
        'Smiles returning to the faces near',
        'Feels like forever since the sky was clear',
        'Warm horizons coming into view',
        'Everything golden, everything new',
        'And I say, it is alright',
      ],
    ),
    CassetteTape(
      id: '4',
      trackName: 'Space Oddity',
      artistName: 'David Bowie',
      year: '1969',
      spotifyUri: '',
      bodyColor: Color(0xFF1E3A5F),
      labelColor: Color(0xFFE0E0E0),
      stripeColor: Color(0xFFE25A3B),
      lyrics: [
        'Tower to traveler, do you read',
        'Systems steady, all the dials agreed',
        'Strap in slowly, count it down from ten',
        'Past the ceiling of the world again',
        'Silver capsule in a sea of black',
        'Stars ahead and the Earth at my back',
        'Tell my darling that I am floating free',
        'The quiet up here is enough for me',
        'Engines dreaming, drifting on',
      ],
    ),
    CassetteTape(
      id: '5',
      trackName: 'Hotel California',
      artistName: 'Eagles',
      year: '1976',
      spotifyUri: '',
      bodyColor: Color(0xFF2E4035),
      labelColor: Color(0xFFE8E3D5),
      stripeColor: Color(0xFFD6A033),
      lyrics: [
        'Neon flickers on a desert road',
        'Cool wind carrying a story untold',
        'A doorway glowing in the fading light',
        'Voices drifting through the velvet night',
        'Candles burning in a mirrored hall',
        'Shadows dancing on the western wall',
        'You can wander but you cannot quite leave',
        'The music plays for those who believe',
        'Welcome, traveler, stay a while',
      ],
    ),
  ];
}
