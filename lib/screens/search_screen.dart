import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cassette_tape.dart';
import '../painters/wallpaper_painter.dart';
import '../services/spotify_service.dart';
import '../utils/debouncer.dart';
import '../utils/grid_math.dart';
import '../widgets/mini_player_bar.dart';
import 'player_screen.dart';

/// The radio, tuned into Spotify: type into the set's green tuning window and
/// matching tracks crackle in as index cards. Tapping one loads it into the
/// player. Lives in the same dusk-lit room as the rest of the app.
class SearchScreen extends StatefulWidget {
  final SpotifyService spotifyService;

  const SearchScreen({super.key, required this.spotifyService});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final Debouncer _debounce = Debouncer(const Duration(milliseconds: 400));
  List<CassetteTape> _results = [];
  bool _searching = false;
  String _lastQuery = '';

  // Result cards slide onto the desk one after another.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  SpotifyService get svc => widget.spotifyService;

  @override
  void dispose() {
    _debounce.dispose();
    _controller.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _onChanged(String value) => _debounce.run(() => _run(value));

  Future<void> _run(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
        _lastQuery = '';
      });
      return;
    }
    setState(() {
      _searching = true;
      _lastQuery = q;
    });
    final res = await svc.searchTracks(q);
    if (!mounted || q != _lastQuery) return;
    setState(() {
      _results = res;
      _searching = false;
    });
    _enter.forward(from: 0);
  }

  void _openPlayer(int index) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: PlayerScreen(
            queue: _results,
            index: index,
            spotifyService: svc,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171008),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: WallpaperPainter()),
          SafeArea(
            child: Column(
              children: [
                _buildRadioBar(),
                Expanded(child: _buildBody()),
                MiniPlayerBar(service: svc),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The radio set's face: back button, a small tuning dial, and the green
  /// tuning window you type into.
  Widget _buildRadioBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2A2724),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFFF4EFE6), size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6E4B33), Color(0xFF47301F)],
                ),
                border: const Border(
                  top: BorderSide(color: Color(0x1FFFFFFF), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Tuning dial.
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFF2E9D4), Color(0xFFC9B588)],
                      ),
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Transform.rotate(
                        angle: _searching ? 1.2 : 0.7,
                        child: Container(
                          width: 1.5,
                          height: 11,
                          color: const Color(0xFF8A2F23),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // The green tuning window.
                  Expanded(
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E170E),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: Colors.black.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.graphic_eq,
                              size: 14, color: Color(0xFF8FD99A)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              onChanged: _onChanged,
                              textInputAction: TextInputAction.search,
                              onSubmitted: _run,
                              cursorColor: const Color(0xFF8FD99A),
                              style: GoogleFonts.robotoMono(
                                fontSize: 13,
                                letterSpacing: 1,
                                color: const Color(0xFF8FD99A),
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'TUNE INTO SPOTIFY…',
                                hintStyle: GoogleFonts.robotoMono(
                                  fontSize: 12,
                                  letterSpacing: 1,
                                  color: const Color(0xFF8FD99A)
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _controller.clear();
                                _run('');
                              },
                              child: const Icon(Icons.close,
                                  size: 16, color: Color(0xFF8FD99A)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!svc.isConnected) {
      return _signal('OFF AIR',
          'Connect Spotify from the den to put this set on the air.');
    }
    if (!svc.hasWebApi) {
      return _signal(
          'OFF AIR',
          'The set has no Web API token. Reconnect from the den and approve '
              'all permissions.');
    }
    if (_searching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF8FD99A)),
            ),
            const SizedBox(height: 12),
            Text(
              'TUNING…',
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                letterSpacing: 3,
                color: const Color(0xFF8FD99A).withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    }
    if (_lastQuery.isEmpty) {
      return _signal('STANDING BY', 'Type a song or artist to find tapes.');
    }
    if (_results.isEmpty) {
      return _signal('NO SIGNAL',
          svc.searchError ?? 'Nothing on the air for "$_lastQuery".');
    }
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, _) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        itemCount: _results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final (ws, we) = GridMath.rowStaggerWindow(i);
          final rise = Interval(ws, we, curve: Curves.easeOutCubic)
              .transform(_enter.value);
          return Opacity(
            opacity: rise,
            child: Transform.translate(
              offset: Offset(0, (1 - rise) * 16),
              child: _ResultCard(
                tape: _results[i],
                onTap: () => _openPlayer(i),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Radio-status messages: a big stamped state and a typed line under it.
  Widget _signal(String state, String detail) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state,
              style: GoogleFonts.specialElite(
                fontSize: 26,
                color: const Color(0xFFF4EFE6).withValues(alpha: 0.35),
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                height: 1.5,
                color: const Color(0xFFF4EFE6).withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One catch off the air: an index card with the cover pasted like a photo,
/// typed title/artist lines and the card's red rule.
class _ResultCard extends StatelessWidget {
  final CassetteTape tape;
  final VoidCallback onTap;

  const _ResultCard({required this.tape, required this.onTap});

  static const Color _ink = Color(0xFF33261A);

  @override
  Widget build(BuildContext context) {
    final art = tape.thumbUrl;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EDDC),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // The cover, pasted on like a photo print.
            Container(
              padding: const EdgeInsets.all(2.5),
              color: Colors.white,
              child: SizedBox(
                width: 46,
                height: 46,
                child: art != null && art.isNotEmpty
                    ? Image.network(art,
                        fit: BoxFit.cover,
                        cacheWidth: 160,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tape.trackName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.specialElite(
                      fontSize: 14,
                      color: _ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(height: 1, color: const Color(0x40A33D2E)),
                  const SizedBox(height: 3),
                  Text(
                    tape.artistName +
                        (tape.year.isNotEmpty ? '  ·  ${tape.year}' : ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.robotoMono(
                      fontSize: 10.5,
                      color: _ink.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.play_arrow_rounded,
                size: 26, color: _ink.withValues(alpha: 0.55)),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF161616),
        child: const Icon(Icons.music_note, color: Color(0xFFF4EFE6), size: 20),
      );
}
