import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/playlist.dart';
import '../painters/wallpaper_painter.dart';
import '../services/spotify_service.dart';
import '../widgets/desk_deck.dart';
import '../widgets/tape_shelf.dart';
import 'drawer_screen.dart';
import 'player_screen.dart';
import 'search_screen.dart';

/// Home: a 1985 bedroom at dusk. The tape shelf on the wall holds the
/// playlists; the poster shows what's playing; the deck on the desk is the
/// living now-playing (reels turn, tap to reopen the player); the radio on
/// the desk tunes into search.
class CabinetScreen extends StatefulWidget {
  final SpotifyService spotifyService;

  const CabinetScreen({super.key, required this.spotifyService});

  @override
  State<CabinetScreen> createState() => _CabinetScreenState();
}

class _CabinetScreenState extends State<CabinetScreen> {
  // The built-in starter mixtape shelf, shown while there are no Spotify
  // playlists so the room is explorable offline. Its tapes are preloaded,
  // so loadPlaylistTracks() is a no-op for it.
  late final Playlist _demoPlaylist = Playlist.demo();

  SpotifyService get svc => widget.spotifyService;

  @override
  void initState() {
    super.initState();
    // Connect to Spotify automatically on launch. The SDK remembers the grant,
    // so after the first approval this is silent.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!svc.isConnected && !svc.isLoading) svc.connectToSpotify();
    });
  }

  /// Takes a shelf down: the POV swings from facing the wall to looking
  /// straight down into the box of tapes (perspective rotation on the route).
  Future<void> _openDrawer(Playlist playlist) async {
    HapticFeedback.mediumImpact(); // lifting the box off the shelf
    svc.loadPlaylistTracks(playlist);
    await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 560),
        reverseTransitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (context, animation, _) =>
            DrawerScreen(playlist: playlist, spotifyService: svc),
        transitionsBuilder: (context, animation, _, child) {
          // The swing settles with a slight overshoot — the box thumping
          // down on the desk — while the fade stays smooth and clamped.
          final swing = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          );
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeInCubic,
          );
          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final v = swing.value;
              final s = 0.92 + 0.08 * v;
              return Opacity(
                opacity: fade.value.clamp(0.0, 1.0),
                child: Transform(
                  alignment: Alignment.topCenter,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateX(-(1 - v) * 1.05)
                    ..scaleByDouble(s, s, 1, 1),
                  child: child,
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Reopens the full player for whatever tape is in the deck.
  void _openNowPlaying() {
    if (svc.nowPlaying == null) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: PlayerScreen(
            queue: svc.nowQueue,
            index: svc.nowIndex,
            spotifyService: svc,
            contextUri: svc.nowContextUri,
          ),
        ),
      ),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchScreen(spotifyService: svc)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: WallpaperPainter()),
          SafeArea(
            child: ListenableBuilder(
              listenable: svc,
              builder: (context, _) {
                final shelves =
                    svc.playlists.isEmpty ? [_demoPlaylist] : svc.playlists;
                return Column(
                  children: [
                    _buildHeader(),
                    // The wall: poster + a pinned note.
                    SizedBox(
                      height: 142,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Poster(service: svc),
                            const SizedBox(width: 16),
                            Expanded(child: _WallNote(service: svc)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: TapeShelf(
                        playlists: shelves,
                        onOpen: _openDrawer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DeskDeck(
                      service: svc,
                      onOpenPlayer: _openNowPlaying,
                      onOpenSearch: _openSearch,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THE DEN',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    color: Color(0xFFF4EFE6),
                    letterSpacing: 4,
                  ),
                ),
                Text(
                  svc.isConnected
                      ? 'Take a tape off the shelf'
                      : svc.isLoading
                          ? 'Connecting to Spotify…'
                          : 'Connect Spotify to fill the shelf',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    color: const Color(0xFFF4EFE6).withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          if (!svc.isConnected)
            _RoundIconButton(
              icon: Icons.link,
              loading: svc.isLoading,
              color: const Color(0xFF1DB954),
              onTap: svc.isLoading ? null : svc.connectToSpotify,
            ),
        ],
      ),
    );
  }
}

/// The poster over the desk: whatever's playing becomes wall art. With
/// nothing loaded it stays the faded mixtape poster that came with the room.
class _Poster extends StatelessWidget {
  final SpotifyService service;

  const _Poster({required this.service});

  @override
  Widget build(BuildContext context) {
    final tape = service.nowPlaying;
    final art = tape?.thumbUrl;
    return Transform.rotate(
      angle: -0.025,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 116,
            height: 136,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFFEFE6D2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: art != null && art.isNotEmpty
                      ? Image.network(
                          art,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          cacheWidth: 260,
                          errorBuilder: (_, __, ___) => const _PosterFallback(),
                        )
                      : const _PosterFallback(),
                ),
                if (tape != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      tape.trackName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.specialElite(
                        fontSize: 8,
                        color: const Color(0xFF33261A),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Aged sticky tape holding the top corners to the wall.
          Positioned(
            top: -4,
            left: -7,
            child: Transform.rotate(
              angle: -0.72,
              child: Container(
                width: 28,
                height: 10,
                color: const Color(0xFFF4EFE6).withValues(alpha: 0.30),
              ),
            ),
          ),
          Positioned(
            top: -4,
            right: -7,
            child: Transform.rotate(
              angle: 0.72,
              child: Container(
                width: 28,
                height: 10,
                color: const Color(0xFFF4EFE6).withValues(alpha: 0.30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF7E3B32),
      alignment: Alignment.center,
      child: Text(
        'MIX\n’85',
        textAlign: TextAlign.center,
        style: GoogleFonts.specialElite(
          fontSize: 22,
          height: 1.1,
          color: const Color(0xFFEFE6D2),
        ),
      ),
    );
  }
}

/// A paper note pinned to the wall: connection status, errors, or just the
/// room's standing reminder.
class _WallNote extends StatelessWidget {
  final SpotifyService service;

  const _WallNote({required this.service});

  String get _text {
    if (service.statusMessage != null) return service.statusMessage!;
    if (service.isLoading) return 'Connecting to Spotify…';
    if (!service.isConnected) {
      return 'Tap the green link up top to connect Spotify and fill the shelf.';
    }
    return 'Pull a box down off the shelf.\nYank it to shuffle.';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Transform.rotate(
        angle: 0.02,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0E3B2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                _text,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.specialElite(
                  fontSize: 10.5,
                  height: 1.45,
                  color: const Color(0xFF4A3A22),
                ),
              ),
            ),
            // Pushpin.
            Positioned(
              top: -4,
              left: 18,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFF4A7EC2), Color(0xFF1E3A66)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  final Color? color;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.loading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? const Color(0xFF2A2724),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
