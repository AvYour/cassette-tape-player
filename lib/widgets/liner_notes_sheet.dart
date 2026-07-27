import 'package:flutter/material.dart';
import '../models/browse.dart';
import '../models/cassette_tape.dart';
import '../models/track_info.dart';
import '../screens/album_screen.dart';
import '../screens/artist_screen.dart';
import '../services/spotify_service.dart';
import '../services/wiki_service.dart';
import '../utils/explore_theme.dart';
import '../utils/tape_wind.dart';
import 'glass.dart';

/// The track's full details, slid up as a frosted sheet: every artist, the
/// album and year, length, track number and an EXPLICIT stamp when deserved.
/// The basics show instantly from the tape; the rest fills in when the Web API
/// answers. The artist and album lines are doors — tap either to open it.
class LinerNotesSheet extends StatelessWidget {
  final CassetteTape tape;
  final SpotifyService service;

  const LinerNotesSheet({super.key, required this.tape, required this.service});

  static void show(
      BuildContext context, CassetteTape tape, SpotifyService service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LinerNotesSheet(tape: tape, service: service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: GlassPanel(
        radius: 24,
        fill: 0.6,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
        child: FutureBuilder<TrackInfo?>(
          future: service.fetchTrackInfo(tape),
          builder: (context, snap) {
            final info = snap.data;
            return ListView(
              shrinkWrap: true,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Explore.muted.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title bar, in this tape's own accent.
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: tape.stripeColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          info?.title ?? tape.trackName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Explore.rowTitle.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (info?.explicit ?? false)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('EXPLICIT',
                              style: Explore.caption.copyWith(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: Explore.ink,
                              )),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _openable(
                  context,
                  label: info?.artistsLine.isNotEmpty == true
                      ? info!.artistsLine
                      : tape.artistName,
                  style: Explore.rowTitle.copyWith(fontSize: 15),
                  onTap: info?.artistId == null
                      ? null
                      : () => _openArtist(context, info!),
                ),
                const SizedBox(height: 14),
                _albumRow(context, info),
                _row('Year',
                    info?.releaseYear.isNotEmpty == true ? info!.releaseYear : tape.year),
                _row('Length',
                    TapeWind.clock(info?.durationMs ?? tape.durationMs)),
                if ((info?.trackNumber ?? 0) > 0)
                  _row('Track', '#${info!.trackNumber}'),
                // A popularity meter, follower count and genre chips used to
                // follow. Spotify deprecated all three fields — popularity came
                // back 0 for every track, and genres/followers came back empty
                // — so the notes now show only what the API still fills in.
                if (snap.connectionState == ConnectionState.waiting) ...[
                  const SizedBox(height: 12),
                  Text('Loading details…', style: Explore.caption),
                ],
                // What Spotify has no field for: what the song actually is,
                // and who the artist actually is. Both arrive from Wikipedia
                // and simply don't appear when there is no article.
                _wikiSection(
                  'About this song',
                  WikiService.songBio(tape.trackName, tape.artistName),
                ),
                _wikiSection(
                  'About ${tape.artistName}',
                  WikiService.bio(tape.artistName),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text('DETAILS FROM SPOTIFY · WRITE-UPS FROM WIKIPEDIA',
                      textAlign: TextAlign.center,
                      style: Explore.caption.copyWith(
                        fontSize: 9,
                        letterSpacing: 1.5,
                        color: Explore.muted.withValues(alpha: 0.7),
                      )),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// A write-up block that only exists once Wikipedia answers with something.
  /// While it is in flight, and forever after if there is no article, the
  /// section takes up no room at all.
  Widget _wikiSection(String heading, Future<String?> text) {
    return FutureBuilder<String?>(
      future: text,
      builder: (context, snap) {
        final body = snap.data;
        if (body == null || body.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            Text(heading.toUpperCase(),
                style: Explore.caption.copyWith(letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Text(body,
                style: Explore.rowOwner.copyWith(
                  color: Explore.ink,
                  height: 1.5,
                  fontSize: 13,
                )),
          ],
        );
      },
    );
  }

  /// A line that reads as text until there is somewhere to go, then picks up
  /// an underline and a chevron.
  Widget _openable(
    BuildContext context, {
    required String label,
    required TextStyle style,
    VoidCallback? onTap,
  }) {
    final text = Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: onTap == null
          ? style
          : style.copyWith(decoration: TextDecoration.underline),
    );
    if (onTap == null) return text;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Flexible(child: text),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: Explore.muted),
        ],
      ),
    );
  }

  void _openArtist(BuildContext context, TrackInfo info) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtistScreen(
          artist: ArtistBrief(
            id: info.artistId!,
            name: info.artists.isEmpty ? tape.artistName : info.artists.first,
          ),
          spotifyService: service,
        ),
      ),
    );
  }

  Widget _albumRow(BuildContext context, TrackInfo? info) {
    final name =
        info?.albumName.isNotEmpty == true ? info!.albumName : tape.albumName;
    if (name.isEmpty) return const SizedBox.shrink();
    final id = info?.albumId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child:
                Text('ALBUM', style: Explore.caption.copyWith(letterSpacing: 1)),
          ),
          Expanded(
            child: _openable(
              context,
              label: name,
              style: Explore.rowOwner.copyWith(color: Explore.ink),
              onTap: id == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AlbumScreen(
                            album: AlbumBrief(
                              id: id,
                              name: name,
                              artistName: info?.artists.isEmpty == false
                                  ? info!.artists.first
                                  : tape.artistName,
                              imageUrl: tape.albumArtUrl,
                            ),
                            spotifyService: service,
                          ),
                        ),
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label.toUpperCase(),
                style: Explore.caption.copyWith(letterSpacing: 1)),
          ),
          Expanded(
            child: Text(value,
                style: Explore.rowOwner.copyWith(color: Explore.ink)),
          ),
        ],
      ),
    );
  }

}
