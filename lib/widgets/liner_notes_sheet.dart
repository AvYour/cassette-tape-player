import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cassette_tape.dart';
import '../models/track_info.dart';
import '../services/spotify_service.dart';
import '../utils/tape_wind.dart';

/// The cassette's liner notes: a J-card paper inlay that slides up with the
/// track's full details from Spotify — every artist, album and year, length,
/// track number, a popularity meter, an EXPLICIT stamp when deserved, and the
/// artist's genres and following. The basics show instantly from the tape;
/// the rest is typed in when the Web API answers.
class LinerNotesSheet extends StatelessWidget {
  final CassetteTape tape;
  final SpotifyService service;

  const LinerNotesSheet({super.key, required this.tape, required this.service});

  static const Color _ink = Color(0xFF33261A);

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
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EDDC),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: FutureBuilder<TrackInfo?>(
        future: service.fetchTrackInfo(tape),
        builder: (context, snap) {
          final info = snap.data;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull notch.
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: _ink.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Stripe header, in this tape's own color.
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: tape.stripeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        (info?.title ?? tape.trackName).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.specialElite(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF4EFE6),
                        ),
                      ),
                    ),
                    if (info?.explicit ?? false)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFF4EFE6), width: 1.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'EXPLICIT',
                          style: GoogleFonts.robotoMono(
                            fontSize: 7.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: const Color(0xFFF4EFE6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                info?.artistsLine.isNotEmpty == true
                    ? info!.artistsLine
                    : tape.artistName,
                style: GoogleFonts.specialElite(fontSize: 13, color: _ink),
              ),
              const SizedBox(height: 12),
              _row(
                  'ALBUM',
                  info?.albumName.isNotEmpty == true
                      ? info!.albumName
                      : tape.albumName),
              _row(
                  'YEAR',
                  info?.releaseYear.isNotEmpty == true
                      ? info!.releaseYear
                      : tape.year),
              _row('LENGTH',
                  TapeWind.clock(info?.durationMs ?? tape.durationMs)),
              if ((info?.trackNumber ?? 0) > 0)
                _row('TRACK', 'SIDE A · #${info!.trackNumber}'),
              if (info != null) _popularity(info.popularity),
              if (info?.artistFollowers != null)
                _row(
                    'FOLLOWERS', TrackInfo.formatCount(info!.artistFollowers!)),
              if (info != null && info.genres.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final g in info.genres.take(4))
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: _ink.withValues(alpha: 0.45)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          g.toUpperCase(),
                          style: GoogleFonts.robotoMono(
                            fontSize: 8,
                            letterSpacing: 1,
                            color: _ink.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              if (snap.connectionState == ConnectionState.waiting) ...[
                const SizedBox(height: 10),
                Text(
                  'typing up the notes…',
                  style: GoogleFonts.specialElite(
                      fontSize: 10, color: _ink.withValues(alpha: 0.5)),
                ),
              ],
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'RECORDED FROM SPOTIFY · STEREO ▸ DOLBY NR',
                  style: GoogleFonts.robotoMono(
                    fontSize: 7.5,
                    letterSpacing: 1.5,
                    color: _ink.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: GoogleFonts.robotoMono(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: _ink.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.robotoMono(fontSize: 10.5, color: _ink),
            ),
          ),
        ],
      ),
    );
  }

  /// Popularity as inked meter cells, like a chart position on the inlay.
  Widget _popularity(int popularity) {
    final filled = (popularity / 10).round().clamp(0, 10);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              'POPULARITY',
              style: GoogleFonts.robotoMono(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: _ink.withValues(alpha: 0.55),
              ),
            ),
          ),
          for (var i = 0; i < 10; i++)
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1.5),
                color: i < filled
                    ? tape.stripeColor
                    : _ink.withValues(alpha: 0.12),
              ),
            ),
          Text(
            ' $popularity',
            style: GoogleFonts.robotoMono(fontSize: 9.5, color: _ink),
          ),
        ],
      ),
    );
  }
}
