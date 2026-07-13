import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/playlist.dart';
import '../services/spotify_service.dart';
import '../utils/colors.dart';
import '../painters/wood_painter.dart';
import '../widgets/cabinet_drawer.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/vintage_background.dart';
import 'drawer_screen.dart';
import 'search_screen.dart';

/// Home screen: a filing cabinet whose drawers are playlists. A built-in
/// starter mixtape works offline; connecting to Spotify adds the user's own
/// playlists as drawers. A search button opens live Spotify track search.
class CabinetScreen extends StatefulWidget {
  final SpotifyService spotifyService;

  const CabinetScreen({super.key, required this.spotifyService});

  @override
  State<CabinetScreen> createState() => _CabinetScreenState();
}

class _CabinetScreenState extends State<CabinetScreen> {
  // Key of the currently open drawer; null = all closed.
  String? _openKey;

  // The built-in starter mixtape drawer, shown while there are no Spotify
  // playlists so the cabinet is explorable offline. Its tapes are preloaded,
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

  /// Pulls a drawer open: the POV swings from facing the cabinet to looking
  /// straight down into the drawer (a perspective rotation on the incoming
  /// route). The face stays "pulled" while the drawer view is open.
  Future<void> _openDrawer(Playlist playlist) async {
    HapticFeedback.mediumImpact(); // the tug of the drawer coming free
    setState(() => _openKey = playlist.id);
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
          // The swing settles with a slight overshoot — the drawer thumping
          // against its rails — while the fade stays smooth and clamped.
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
                  // Lean-over-the-drawer POV: the view starts tipped away
                  // (as if still facing the cabinet) and rotates flat, like
                  // your eyes travelling up and over the open drawer.
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
    if (mounted) setState(() => _openKey = null); // drawer pushed back in
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VintageBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: svc,
            builder: (context, _) {
              return Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 32, top: 4),
                      children: [
                        // The user's own Spotify playlists, filed as drawers
                        // in one solid wooden cabinet. With no playlists yet,
                        // the built-in starter mixtape keeps a drawer in it.
                        if (svc.playlists.isNotEmpty || !svc.isLoading)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: _CabinetBody(
                              children: [
                                for (final pl in svc.playlists.isEmpty
                                    ? [_demoPlaylist]
                                    : svc.playlists)
                                  CabinetDrawer(
                                    playlist: pl,
                                    isOpen: _openKey == pl.id,
                                    onTap: () => _openDrawer(pl),
                                    loadedCount: pl.tapes?.length,
                                  ),
                              ],
                            ),
                          ),
                        if (svc.isLoading && svc.playlists.isEmpty)
                          _buildConnecting(),
                        if (svc.statusMessage != null)
                          _buildStatus(svc.statusMessage!),
                        if (!svc.isConnected && !svc.isLoading)
                          _buildConnectHint(),
                      ],
                    ),
                  ),
                  MiniPlayerBar(service: svc),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THE CABINET',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                    color: kTextDark,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  svc.isConnected
                      ? 'Pull a drawer to browse'
                      : svc.isLoading
                          ? 'Connecting to Spotify…'
                          : 'Connect Spotify to load your playlists',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    color: kVintageInk,
                  ),
                ),
              ],
            ),
          ),
          _RoundIconButton(
            icon: Icons.search,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchScreen(spotifyService: svc),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
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

  Widget _buildStatus(String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18, color: kVintageInk),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  height: 1.4,
                  color: kTextDark,
                ),
              ),
            ),
            if (svc.isConnected && !svc.hasWebApi)
              GestureDetector(
                onTap: svc.isLoading ? null : svc.connectToSpotify,
                child: Text(
                  'RETRY',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1DB954),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnecting() {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: kGold),
      ),
    );
  }

  Widget _buildConnectHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Text(
        'Tap the green link icon to connect Spotify and load your own playlists as drawers.',
        textAlign: TextAlign.center,
        style: GoogleFonts.robotoMono(
          fontSize: 11,
          height: 1.5,
          color: kVintageInk.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

/// The cabinet carcass: one continuous timber body whose drawers sit flush in
/// their openings — top plank, frame rails between drawers, a plinth and feet.
/// This is what makes the home read as a real filing cabinet instead of an
/// accordion of floating bars.
class _CabinetBody extends StatelessWidget {
  final List<Widget> children;

  const _CabinetBody({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x40000000)),
            boxShadow: [
              // The cabinet stands in the room: one deep grounded shadow.
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 26,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                // One continuous varnished timber body (calm finish, no bevel;
                // the drawer faces carry the bevels).
                const Positioned.fill(
                  child: CustomPaint(
                    painter: WoodPainter(
                      light: Color(0xFF8A5F3C),
                      dark: Color(0xFF69452A),
                      seed: 11,
                      bevelled: false,
                    ),
                  ),
                ),
                Padding(
                  // Frame: sides and top are slim rails; the bottom is a
                  // heavier plinth, like real casework.
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
                  child: Column(
                    children: [
                      for (int i = 0; i < children.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8), // frame rail
                        children[i],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Feet, slightly inset from the corners.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_foot(), _foot()],
          ),
        ),
      ],
    );
  }

  Widget _foot() => Container(
        width: 54,
        height: 12,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5E3E27), Color(0xFF3E2817)],
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      );
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
