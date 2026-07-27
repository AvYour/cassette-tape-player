import 'package:flutter/material.dart';
import '../screens/player_screen.dart';
import '../services/spotify_service.dart';
import '../utils/explore_theme.dart';
import 'glass.dart';

/// Floats a [MiniPlayerBar] over a page instead of stacking it in the layout,
/// so the bar appears the moment something plays without shrinking the list
/// underneath it. Lists should leave [kMiniPlayerInset] of bottom padding so
/// their last row can still be scrolled clear of the bar.
class MiniPlayerOverlay extends StatelessWidget {
  final SpotifyService service;
  final Widget child;

  /// Distance from the bottom of the page — raise it above a nav bar.
  final double bottomInset;

  const MiniPlayerOverlay({
    super.key,
    required this.service,
    required this.child,
    this.bottomInset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomInset,
          child: MiniPlayerBar(service: service),
        ),
      ],
    );
  }
}

/// Bottom padding a scrollable should reserve so the floating bar never covers
/// its last row.
const double kMiniPlayerInset = 96;

/// A frosted "now playing" bar for the bottom of Explore and Search. Shows the
/// loaded tape, toggles play/pause in place, and taps through to the full
/// player. Hides itself when nothing is loaded.
class MiniPlayerBar extends StatelessWidget {
  final SpotifyService service;

  const MiniPlayerBar({super.key, required this.service});

  void _open(BuildContext context) {
    if (service.nowPlaying == null) return;
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
            contextUri: service.nowContextUri,
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
        final art = tape.thumbUrl;
        final playing = service.isPlaying;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: GlassPanel(
            radius: 20,
            fill: 0.6,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _open(context),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: art == null || art.isEmpty
                            ? Container(color: tape.stripeColor)
                            : Image.network(art,
                                fit: BoxFit.cover, cacheWidth: 132),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tape.trackName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Explore.rowTitle.copyWith(fontSize: 14.5)),
                          Text(tape.artistName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Explore.rowOwner.copyWith(fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          playing ? service.pause() : service.resume(),
                      icon: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Explore.ink,
                        size: 30,
                      ),
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
}
