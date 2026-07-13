import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/playlist.dart';
import '../services/spotify_service.dart';
import '../utils/colors.dart';
import '../utils/grid_math.dart';
import '../widgets/cassette_spine.dart';
import '../widgets/mini_player_bar.dart';
import 'player_screen.dart';

/// Looking straight down into an open drawer: the cassettes are filed in rows
/// ([columns] per row) and you scroll vertically through them. Reached from the
/// cabinet via a POV rotation, as if you leaned over the drawer you just pulled.
class DrawerScreen extends StatefulWidget {
  final Playlist playlist;
  final SpotifyService spotifyService;

  const DrawerScreen({
    super.key,
    required this.playlist,
    required this.spotifyService,
  });

  /// Cassettes per row in the drawer.
  static const int columns = 5;

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen>
    with SingleTickerProviderStateMixin {
  // Rows of tapes settle into the drawer one after another on entry.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  int _enteredCount = -1;

  // Cell geometry: a spine is 66 wide and gets ~170 of height in the drawer.
  static const double _spineW = CassetteSpine.width;
  static const double _spineH = 170;

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  void _openPlayer(int index) {
    final tapes = widget.playlist.tapes;
    if (tapes == null || index < 0 || index >= tapes.length) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: PlayerScreen(
            queue: tapes,
            index: index,
            spotifyService: widget.spotifyService,
            contextUri: widget.playlist.contextUri,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The dark room around the pulled-out drawer.
      backgroundColor: const Color(0xFF171008),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.spotifyService,
          builder: (context, _) {
            final tapes = widget.playlist.tapes;
            // Replay the settle-in choreography when the tapes first arrive.
            final count = tapes?.length ?? -1;
            if (count != _enteredCount && !widget.playlist.loading) {
              _enteredCount = count;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _enter.forward(from: 0);
              });
            }
            return Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildDrawer()),
                MiniPlayerBar(service: widget.spotifyService),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact(); // pushing the drawer back in
              Navigator.of(context).maybePop();
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.playlist.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.robotoMono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF4EFE6),
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '${widget.playlist.tapes?.length ?? widget.playlist.trackCount} tapes · ${widget.playlist.owner}',
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    color: const Color(0xFFF4EFE6).withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          // The playlist's accent, like a colored index tab on the drawer rim.
          Container(
            width: 10,
            height: 34,
            decoration: BoxDecoration(
              color: widget.playlist.accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  /// The drawer itself, seen from above: a wooden rim around a felt-lined
  /// interior holding the grid of filed cassettes.
  Widget _buildDrawer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        // Wooden rim.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C5537), Color(0xFF5E3E27)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Container(
          decoration: const BoxDecoration(
            // Felt interior.
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A1C12), Color(0xFF382515)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildContent(),
              // Inner walls shading all four sides for depth.
              _innerShadow(Alignment.topCenter, Alignment.bottomCenter, 26),
              _innerShadow(Alignment.bottomCenter, Alignment.topCenter, 26),
              _innerShadowSide(left: true),
              _innerShadowSide(left: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _innerShadow(Alignment from, Alignment to, double size) {
    return Positioned(
      top: from == Alignment.topCenter ? 0 : null,
      bottom: from == Alignment.bottomCenter ? 0 : null,
      left: 0,
      right: 0,
      height: size,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: from,
              end: to,
              colors: const [Color(0x66000000), Color(0x00000000)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _innerShadowSide({required bool left}) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      width: 14,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: left ? Alignment.centerLeft : Alignment.centerRight,
              end: left ? Alignment.centerRight : Alignment.centerLeft,
              colors: const [Color(0x59000000), Color(0x00000000)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.playlist.loading) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2, color: kGold),
        ),
      );
    }
    final tapes = widget.playlist.tapes ?? const [];
    if (tapes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            widget.playlist.loadError ?? 'Empty drawer',
            textAlign: TextAlign.center,
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              height: 1.4,
              color: const Color(0xFFF4EFE6).withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, _) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: DrawerScreen.columns,
          mainAxisSpacing: 10,
          crossAxisSpacing: 6,
          childAspectRatio: _spineW / _spineH,
        ),
        itemCount: tapes.length,
        itemBuilder: (context, i) {
          // Rows settle into the drawer one after another.
          final row = GridMath.rowOf(i, columns: DrawerScreen.columns);
          final (ws, we) = GridMath.rowStaggerWindow(row);
          final rise = Interval(ws, we, curve: Curves.easeOutBack)
              .transform(_enter.value);
          final fade =
              Interval(ws, we, curve: Curves.easeOut).transform(_enter.value);
          return Opacity(
            opacity: fade,
            child: Transform.translate(
              offset: Offset(0, (1 - rise) * 22),
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _spineW,
                  height: _spineH,
                  child: CassetteSpine(
                    tape: tapes[i],
                    onTap: () => _openPlayer(i),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
