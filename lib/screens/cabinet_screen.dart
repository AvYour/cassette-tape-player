import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cassette_tape.dart';
import '../models/playlist.dart';
import '../services/spotify_service.dart';
import '../utils/colors.dart';
import '../widgets/cabinet_drawer.dart';
import '../widgets/vintage_background.dart';
import 'player_screen.dart';
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

  SpotifyService get svc => widget.spotifyService;

  void _openPlayer(CassetteTape tape) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: PlayerScreen(tape: tape, spotifyService: svc),
        ),
      ),
    );
  }

  void _toggle(String key, {Playlist? playlist}) {
    setState(() => _openKey = _openKey == key ? null : key);
    if (_openKey == key && playlist != null) {
      svc.loadPlaylistTracks(playlist);
    }
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
                        // Offline starter drawer.
                        CabinetDrawer(
                          playlist: _demoPlaylist,
                          isOpen: _openKey == 'demo',
                          onTap: () => _toggle('demo'),
                          loading: false,
                          tapes: CassetteTape.demoTapes,
                          onTapeTap: _openPlayer,
                        ),
                        // Real Spotify playlists (after connect).
                        for (final pl in svc.playlists)
                          CabinetDrawer(
                            playlist: pl,
                            isOpen: _openKey == pl.id,
                            onTap: () => _toggle(pl.id, playlist: pl),
                            loading: pl.loading,
                            tapes: pl.tapes,
                            loadError: pl.loadError,
                            onTapeTap: _openPlayer,
                          ),
                        if (svc.statusMessage != null) _buildStatus(svc.statusMessage!),
                        if (!svc.isConnected) _buildConnectHint(),
                      ],
                    ),
                  ),
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
                      : 'Starter tapes · connect for your playlists',
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

  Widget _buildConnectHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
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

  static final Playlist _demoPlaylist = Playlist(
    id: 'demo',
    name: 'Starter Mixtape',
    owner: 'You',
    trackCount: CassetteTape.demoTapes.length,
    accent: const Color(0xFFD94532),
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
