import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cassette_tape.dart';
import '../services/spotify_service.dart';
import '../utils/colors.dart';
import '../widgets/cassette_tape_view.dart';
import '../widgets/vintage_background.dart';
import 'player_screen.dart';

/// Horizontal pager of upright cassettes (reference `PagerScreen`).
class LibraryScreen extends StatefulWidget {
  final SpotifyService spotifyService;

  const LibraryScreen({super.key, required this.spotifyService});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.72);
  int _current = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openPlayer(CassetteTape tape) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: PlayerScreen(
            tape: tape,
            spotifyService: widget.spotifyService,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VintageBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 48, 24, 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'MIXTAPES',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          color: kTextDark,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    ListenableBuilder(
                      listenable: widget.spotifyService,
                      builder: (context, _) {
                        if (widget.spotifyService.isConnected) {
                          return const SizedBox.shrink();
                        }
                        return _ConnectButton(
                          onConnect: widget.spotifyService.connectToSpotify,
                          isLoading: widget.spotifyService.isLoading,
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.spotifyService,
                  builder: (context, _) {
                    final tapes = widget.spotifyService.tapes;
                    return PageView.builder(
                      controller: _pageController,
                      itemCount: tapes.length,
                      onPageChanged: (i) => setState(() => _current = i),
                      itemBuilder: (context, i) {
                        final tape = tapes[i];
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double offset = (_current - i).toDouble();
                            if (_pageController.hasClients &&
                                _pageController.position.haveDimensions) {
                              offset = (_pageController.page ?? offset) - i;
                            }
                            final abs = offset.abs().clamp(0.0, 1.0);
                            return Opacity(
                              opacity: 1 - 0.5 * abs,
                              child: Transform.scale(
                                scale: 1 - 0.15 * abs,
                                child: child,
                              ),
                            );
                          },
                          child: Center(
                            child: GestureDetector(
                              onTap: () => _openPlayer(tape),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Hero(
                                  tag: 'tape_${tape.id}',
                                  flightShuttleBuilder:
                                      cassetteFlightShuttle(tape),
                                  child: RotatedBox(
                                    quarterTurns: 3,
                                    child: _ShadowedCassette(tape: tape),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(
                height: 120,
                child: ListenableBuilder(
                  listenable: widget.spotifyService,
                  builder: (context, _) {
                    final tapes = widget.spotifyService.tapes;
                    final tape = tapes[_current.clamp(0, tapes.length - 1)];
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tape.artistName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: kVintageInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              tape.trackName,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSerif(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: kTextDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShadowedCassette extends StatelessWidget {
  final CassetteTape tape;

  const _ShadowedCassette({required this.tape});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CassetteTapeView(tape: tape),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  final VoidCallback onConnect;
  final bool isLoading;

  const _ConnectButton({required this.onConnect, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onConnect,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1DB954),
          borderRadius: BorderRadius.circular(18),
        ),
        child: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'SPOTIFY',
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}
