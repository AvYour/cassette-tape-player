import 'package:flutter/material.dart';
import '../models/cassette_tape.dart';
import '../utils/explore_theme.dart';

/// One song in a list: cover, title, artist, length. Shared by a playlist's
/// tracks and by search results so the two can never drift apart.
class TrackRow extends StatelessWidget {
  final CassetteTape tape;

  /// Sits on a white card when this is the track currently loaded.
  final bool nowPlaying;

  final VoidCallback onTap;

  const TrackRow({
    super.key,
    required this.tape,
    required this.onTap,
    this.nowPlaying = false,
  });

  /// `4:19`. Minutes unpadded, seconds padded — how a track length is written
  /// on a sleeve. Long tracks keep counting in minutes rather than growing an
  /// hours field, and a negative or zero duration reads as `0:00`.
  static String formatDuration(int ms) {
    final total = ms <= 0 ? 0 : (ms / 1000).round();
    final minutes = total ~/ 60;
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final art = tape.thumbUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: nowPlaying ? Explore.card : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: art == null || art.isEmpty
                        ? Container(color: tape.stripeColor)
                        : Image.network(
                            art,
                            fit: BoxFit.cover,
                            cacheWidth: 150,
                            errorBuilder: (_, __, ___) =>
                                Container(color: tape.stripeColor),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tape.trackName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Explore.rowTitle.copyWith(fontSize: 15.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tape.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Explore.rowOwner.copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(formatDuration(tape.durationMs), style: Explore.caption),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
