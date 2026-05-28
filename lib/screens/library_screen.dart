import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cassette_tape.dart';
import '../services/spotify_service.dart';
import '../widgets/cassette_card.dart';
import '../utils/colors.dart';
import 'player_screen.dart';

class LibraryScreen extends StatefulWidget {
  final SpotifyService spotifyService;

  const LibraryScreen({super.key, required this.spotifyService});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openPlayer(CassetteTape tape) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, animation, _) => FadeTransition(
          opacity: animation,
          child: PlayerScreen(
            tape: tape,
            spotifyService: widget.spotifyService,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBackground1, kBackground2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'MY TAPES',
                      style: GoogleFonts.vt323(
                        fontSize: 30,
                        color: kTextDark,
                        letterSpacing: 5,
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
              const SizedBox(height: 8),
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.spotifyService,
                  builder: (context, _) {
                    final tapes = widget.spotifyService.tapes;
                    return PageView.builder(
                      controller: _pageController,
                      itemCount: tapes.length,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemBuilder: (context, i) {
                        final tape = tapes[i];
                        return GestureDetector(
                          onTap: () => _openPlayer(tape),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 28,
                            ),
                            child: AnimatedScale(
                              scale: _currentPage == i ? 1.0 : 0.93,
                              duration: const Duration(milliseconds: 220),
                              child: CassetteCard(
                                tape: tape,
                                tapeState: TapeState.stopped,
                                progress: 0,
                                isHero: true,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              ListenableBuilder(
                listenable: widget.spotifyService,
                builder: (context, _) {
                  final count = widget.spotifyService.tapes.length;
                  final dotCount = count > 12 ? 12 : count;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(dotCount, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentPage == i ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? kTextDark
                                : kTextDark.withOpacity(0.28),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF1DB954),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1DB954).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isLoading
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'CONNECT SPOTIFY',
                style: GoogleFonts.courierPrime(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}
