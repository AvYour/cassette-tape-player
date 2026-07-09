import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/player_screen.dart';
import '../services/spotify_service.dart';
import '../utils/colors.dart';

/// A Spotify-style now-playing bar shown at the bottom of the cabinet/search
/// screens after the full player is dismissed with Back (not Eject). Tapping it
/// reopens the full player; the play/pause button toggles playback in place.
class MiniPlayerBar extends StatelessWidget {
  final SpotifyService service;

  const MiniPlayerBar({super.key, required this.service});

  void _open(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: PlayerScreen(
            queue: service.nowQueue,
            index: service.nowIndex,
            spotifyService: service,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final tape = service.nowPlaying;
        if (tape == null) return const SizedBox.shrink();
        final playing = service.isPlaying;
        final art = tape.albumArtUrl;

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _open(context),
              child: Container(
                height: 62,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2A2724), Color(0xFF17150F)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Album art thumbnail.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: art != null && art.isNotEmpty
                            ? Image.network(art,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _artFallback())
                            : _artFallback(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tape.trackName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.specialElite(
                              fontSize: 13,
                              color: const Color(0xFFF4EFE6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tape.artistName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.courierPrime(
                              fontSize: 11,
                              color: const Color(0xFFF4EFE6).withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: const Color(0xFFF4EFE6),
                        size: 30,
                      ),
                      onPressed: () =>
                          playing ? service.pause() : service.resume(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _artFallback() => Container(
        color: const Color(0xFF161616),
        child: const Icon(Icons.music_note, color: kMark, size: 20),
      );
}
