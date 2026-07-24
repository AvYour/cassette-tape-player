import 'package:flutter/material.dart';
import '../models/cassette_tape.dart';
import '../models/track_info.dart';
import '../services/spotify_service.dart';
import '../utils/explore_theme.dart';
import '../utils/tape_wind.dart';
import 'glass.dart';

/// The track's full details, slid up as a frosted sheet: every artist, album
/// and year, length, track number, a popularity meter, an EXPLICIT stamp when
/// deserved, and the artist's genres and following. The basics show instantly
/// from the tape; the rest fills in when the Web API answers.
class LinerNotesSheet extends StatelessWidget {
  final CassetteTape tape;
  final SpotifyService service;

  const LinerNotesSheet({super.key, required this.tape, required this.service});

  static void show(
      BuildContext context, CassetteTape tape, SpotifyService service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LinerNotesSheet(tape: tape, service: service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: GlassPanel(
        radius: 24,
        fill: 0.6,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
        child: FutureBuilder<TrackInfo?>(
          future: service.fetchTrackInfo(tape),
          builder: (context, snap) {
            final info = snap.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  info?.artistsLine.isNotEmpty == true
                      ? info!.artistsLine
                      : tape.artistName,
                  style: Explore.rowTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 14),
                _row('Album',
                    info?.albumName.isNotEmpty == true ? info!.albumName : tape.albumName),
                _row('Year',
                    info?.releaseYear.isNotEmpty == true ? info!.releaseYear : tape.year),
                _row('Length',
                    TapeWind.clock(info?.durationMs ?? tape.durationMs)),
                if ((info?.trackNumber ?? 0) > 0)
                  _row('Track', '#${info!.trackNumber}'),
                if (info != null) _popularity(info.popularity),
                if (info?.artistFollowers != null)
                  _row('Followers',
                      TrackInfo.formatCount(info!.artistFollowers!)),
                if (info != null && info.genres.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final g in info.genres.take(4))
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Explore.bgTop,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Explore.hairline),
                          ),
                          child: Text(g,
                              style: Explore.caption.copyWith(fontSize: 11)),
                        ),
                    ],
                  ),
                ],
                if (snap.connectionState == ConnectionState.waiting) ...[
                  const SizedBox(height: 12),
                  Text('Loading details…', style: Explore.caption),
                ],
                const SizedBox(height: 16),
                Center(
                  child: Text('FROM SPOTIFY',
                      style: Explore.caption.copyWith(
                        fontSize: 9,
                        letterSpacing: 2,
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

  /// Popularity as a row of filled cells, like a chart position.
  Widget _popularity(int popularity) {
    final filled = (popularity / 10).round().clamp(0, 10);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text('POPULARITY',
                style: Explore.caption.copyWith(letterSpacing: 1)),
          ),
          for (var i = 0; i < 10; i++)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i < filled ? tape.stripeColor : Explore.hairline,
              ),
            ),
          const SizedBox(width: 4),
          Text('$popularity',
              style: Explore.rowOwner.copyWith(color: Explore.ink)),
        ],
      ),
    );
  }
}
