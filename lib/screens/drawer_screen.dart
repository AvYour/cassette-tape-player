import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cassette_tape.dart';
import '../models/playlist.dart';
import '../painters/felt_painter.dart';
import '../painters/wood_painter.dart';
import '../services/spotify_service.dart';
import '../utils/colors.dart';
import '../utils/grid_math.dart';
import '../utils/shuffle_pull.dart';
import '../widgets/cassette_spine.dart';
import '../widgets/mini_player_bar.dart';
import 'player_screen.dart';

/// Looking straight down into an open drawer: the cassettes are filed in rows
/// ([columns] per row), each seated in its own slot, and you scroll vertically
/// through them. Reached from the cabinet via a POV rotation, as if you leaned
/// over the drawer you just pulled. Yank the contents down past the threshold
/// and let go to shuffle-play the whole drawer.
class DrawerScreen extends StatefulWidget {
  final Playlist playlist;
  final SpotifyService spotifyService;

  const DrawerScreen({
    super.key,
    required this.playlist,
    required this.spotifyService,
  });

  /// Cassettes per row in the drawer.
  static const int columns = 7;

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen>
    with TickerProviderStateMixin {
  // Rows of tapes settle into the drawer one after another on entry.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  // Slow heartbeat for the now-playing LED on the active tape's slot.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  int _enteredCount = -1;

  // Pull-to-shuffle state: how far the contents are yanked down (0..1) and
  // whether the threshold was crossed (fires on release).
  double _pull = 0;
  bool _pullArmed = false;

  // Cell geometry: a spine is 66 wide and gets ~170 of height in the drawer.
  static const double _spineW = CassetteSpine.width;
  static const double _spineH = 170;

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _openPlayer(int index) {
    final tapes = widget.playlist.tapes;
    if (tapes == null || index < 0 || index >= tapes.length) return;
    HapticFeedback.selectionClick();
    _pushPlayer(tapes, index);
  }

  /// Shuffle the whole drawer and play it front to back.
  void _shufflePlay() {
    final tapes = widget.playlist.tapes;
    if (tapes == null || tapes.isEmpty) return;
    HapticFeedback.heavyImpact();
    final order = ShufflePull.shuffledIndices(tapes.length,
        seed: DateTime.now().millisecondsSinceEpoch);
    final queue = [for (final i in order) tapes[i]];
    _pushPlayer(queue, 0);
  }

  void _pushPlayer(List<CassetteTape> queue, int index) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: PlayerScreen(
            queue: queue,
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
                  '${widget.playlist.tapes?.length ?? widget.playlist.trackCount} tapes · ${widget.playlist.owner} · pull down to shuffle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
      decoration: BoxDecoration(
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
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Varnished timber rim, same wood as the cabinet body.
            const Positioned.fill(
              child: CustomPaint(
                painter: WoodPainter(
                  light: Color(0xFF7C5537),
                  dark: Color(0xFF5E3E27),
                  seed: 13,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: _buildFelt(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFelt() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fibrous felt lining with overhead light and shadowed corners.
          const RepaintBoundary(
            child: CustomPaint(painter: FeltPainter()),
          ),
          _buildContent(),
          // The shuffle stamp, inked in as the drawer is yanked down.
          _buildShuffleStamp(),
          // Inner walls shading all four sides for depth.
          _innerShadow(Alignment.topCenter, Alignment.bottomCenter, 26),
          _innerShadow(Alignment.bottomCenter, Alignment.topCenter, 26),
          _innerShadowSide(left: true),
          _innerShadowSide(left: false),
        ],
      ),
    );
  }

  Widget _buildShuffleStamp() {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: _pull,
            child: Transform.rotate(
              angle: -0.10,
              child: Transform.scale(
                scale: 0.8 + 0.25 * _pull,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFC94F3D)
                          .withValues(alpha: 0.55 + 0.45 * _pull),
                      width: 2.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _pull >= 1 ? 'RELEASE TO SHUFFLE' : 'SHUFFLE',
                    style: GoogleFonts.robotoMono(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: const Color(0xFFC94F3D)
                          .withValues(alpha: 0.55 + 0.45 * _pull),
                    ),
                  ),
                ),
              ),
            ),
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

  /// Watches the grid's overscroll: pulling the contents down past the
  /// threshold arms the shuffle, which fires when the finger lets go.
  bool _onScroll(ScrollNotification n) {
    if (n is ScrollUpdateNotification || n is OverscrollNotification) {
      final pulled = -n.metrics.pixels; // >0 when yanked past the top
      final p = ShufflePull.progress(pulled);
      if (p != _pull) setState(() => _pull = p);
      if (p >= 1 && !_pullArmed) {
        _pullArmed = true;
        HapticFeedback.mediumImpact(); // the detent: far enough
      } else if (p < 1 && _pullArmed && n is ScrollUpdateNotification) {
        _pullArmed = false; // backed out before releasing
      }
    } else if (n is ScrollEndNotification) {
      if (_pullArmed) {
        _pullArmed = false;
        _shufflePlay();
      }
      if (_pull != 0) setState(() => _pull = 0);
    }
    return false;
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
    final tapes = widget.playlist.tapes ?? const <CassetteTape>[];
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
    final playingId = widget.spotifyService.nowPlaying?.id;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: AnimatedBuilder(
        animation: _enter,
        builder: (context, _) => GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: DrawerScreen.columns,
            // Tighter filing at seven per row.
            mainAxisSpacing: 8,
            crossAxisSpacing: 4,
            childAspectRatio: _spineW / _spineH,
          ),
          itemCount: tapes.length,
          itemBuilder: (context, i) {
            // Rows settle into the drawer one after another; each tape drops
            // with a whisper of tilt that straightens as it seats.
            final row = GridMath.rowOf(i, columns: DrawerScreen.columns);
            final (ws, we) = GridMath.rowStaggerWindow(row);
            final rise = Interval(ws, we, curve: Curves.easeOutBack)
                .transform(_enter.value);
            final fade =
                Interval(ws, we, curve: Curves.easeOut).transform(_enter.value);
            final tiltDir =
                GridMath.colOf(i, columns: DrawerScreen.columns).isEven
                    ? 1.0
                    : -1.0;
            final tape = tapes[i];
            return Opacity(
              opacity: fade,
              child: Transform.translate(
                offset: Offset(0, (1 - rise) * 22),
                child: Transform.rotate(
                  angle: (1 - rise) * 0.05 * tiltDir,
                  child: _TapeSlot(
                    tape: tape,
                    isPlaying: tape.id == playingId,
                    pulse: _pulse,
                    spineWidth: _spineW,
                    spineHeight: _spineH,
                    onOpen: () => _openPlayer(i),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One filing slot in the drawer: a recessed berth in the felt, the cassette
/// spine seated in it (lifting slightly under the finger), and a breathing
/// LED when this tape is the one playing.
class _TapeSlot extends StatefulWidget {
  final CassetteTape tape;
  final bool isPlaying;
  final Animation<double> pulse;
  final double spineWidth;
  final double spineHeight;
  final VoidCallback onOpen;

  const _TapeSlot({
    required this.tape,
    required this.isPlaying,
    required this.pulse,
    required this.spineWidth,
    required this.spineHeight,
    required this.onOpen,
  });

  @override
  State<_TapeSlot> createState() => _TapeSlotState();
}

class _TapeSlotState extends State<_TapeSlot> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        // The tape lifts out of its slot under the finger.
        scale: _pressed ? 1.07 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Stack(
          children: [
            // The recessed berth the tape stands in.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1E1209), Color(0xFF2C1B0E)],
                  ),
                  border: Border.all(color: const Color(0x33000000)),
                  boxShadow: const [
                    // Light catching the slot's bottom lip.
                    BoxShadow(
                      color: Color(0x12FFFFFF),
                      blurRadius: 0,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(3),
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: widget.spineWidth,
                  height: widget.spineHeight,
                  child: CassetteSpine(
                    tape: widget.tape,
                    onTap: widget.onOpen,
                  ),
                ),
              ),
            ),
            // Breathing LED marking the tape that's currently playing.
            if (widget.isPlaying)
              Positioned(
                top: 5,
                right: 7,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: widget.pulse,
                    builder: (context, _) {
                      final glow = 0.35 + 0.65 * widget.pulse.value;
                      return Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE0483A),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE0483A)
                                  .withValues(alpha: 0.7 * glow),
                              blurRadius: 7,
                              spreadRadius: 1.2 * glow,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
