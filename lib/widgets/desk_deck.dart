import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../painters/wood_painter.dart';
import '../services/spotify_service.dart';
import '../utils/vu_motion.dart';

/// The desk of the 1985 room: floorboards under a wooden desktop carrying the
/// tape deck (the room's living now-playing — reels turn, VU needles dance;
/// tap to reopen the full player) and a little bakelite radio that opens
/// search.
class DeskDeck extends StatelessWidget {
  final SpotifyService service;
  final VoidCallback onOpenPlayer;
  final VoidCallback onOpenSearch;

  const DeskDeck({
    super.key,
    required this.service,
    required this.onOpenPlayer,
    required this.onOpenSearch,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 158,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Floorboards under the desk.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 14,
            child: CustomPaint(painter: _FloorPainter()),
          ),
          // The desktop slab, standing just above the floor.
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            height: 104,
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const CustomPaint(
                      painter: WoodPainter(
                        light: Color(0xFF96683F),
                        dark: Color(0xFF6E4A2C),
                        seed: 19,
                        bevelled: false,
                      ),
                    ),
                    // Light catching the desk's front edge.
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 2,
                      child: ColoredBox(
                          color: Colors.white.withValues(alpha: 0.22)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 30,
            child: _TapeDeck(service: service, onTap: onOpenPlayer),
          ),
          Positioned(
            right: 14,
            bottom: 34,
            child: _Radio(onTap: onOpenSearch),
          ),
        ],
      ),
    );
  }
}

/// Dark floorboards catching a little light, with the desk's shadow across
/// their top edge.
class _FloorPainter extends CustomPainter {
  const _FloorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF221710), Color(0xFF120C07)],
        ).createShader(rect),
    );
    // Plank seams.
    final seam = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (double x = 26; x < size.width; x += 46) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), seam);
    }
    // The desk's shadow falling on the floor.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 4),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(_FloorPainter old) => false;
}

/// The deck: LCD readout, a cassette bay whose reels spin, and a pair of VU
/// meters whose needles dance while the music plays. Tapping it reopens the
/// full player for the loaded tape.
class _TapeDeck extends StatefulWidget {
  final SpotifyService service;
  final VoidCallback onTap;

  const _TapeDeck({required this.service, required this.onTap});

  @override
  State<_TapeDeck> createState() => _TapeDeckState();
}

class _TapeDeckState extends State<_TapeDeck>
    with SingleTickerProviderStateMixin {
  // Repaints the VU needles while playing; the clock drives VuMotion.
  late final AnimationController _tick = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  final Stopwatch _clock = Stopwatch()..start();

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  void _syncTicker(bool playing) {
    if (playing && !_tick.isAnimating) _tick.repeat();
    if (!playing && _tick.isAnimating) _tick.stop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.service,
      builder: (context, _) {
        final tape = widget.service.nowPlaying;
        final playing = widget.service.isPlaying;
        _syncTicker(playing);
        return GestureDetector(
          onTap: tape == null ? null : widget.onTap,
          child: Container(
            width: 220,
            height: 106,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3B3833), Color(0xFF232019)],
              ),
              border: const Border(
                top: BorderSide(color: Color(0x14FFFFFF), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // LCD readout.
                Container(
                  height: 20,
                  margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E170E),
                    borderRadius: BorderRadius.circular(3),
                    border:
                        Border.all(color: Colors.black.withValues(alpha: 0.6)),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    tape == null
                        ? 'NO TAPE'
                        : '${tape.trackName} — ${tape.artistName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.robotoMono(
                      fontSize: 8.5,
                      letterSpacing: 1,
                      color: const Color(0xFF8FD99A)
                          .withValues(alpha: tape == null ? 0.45 : 0.95),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                    child: Row(
                      children: [
                        // Cassette bay.
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF17150F), Color(0xFF0E0D0A)],
                              ),
                              border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.5)),
                            ),
                            child: tape == null
                                ? Center(
                                    child: Text(
                                      'INSERT TAPE',
                                      style: GoogleFonts.robotoMono(
                                        fontSize: 8,
                                        letterSpacing: 2.5,
                                        color: const Color(0xFFF4EFE6)
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _Reel(spinning: playing),
                                      const SizedBox(width: 7),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: SizedBox(
                                          width: 38,
                                          height: 28,
                                          child: tape.thumbUrl != null &&
                                                  tape.thumbUrl!.isNotEmpty
                                              ? Image.network(
                                                  tape.thumbUrl!,
                                                  fit: BoxFit.cover,
                                                  cacheWidth: 120,
                                                  errorBuilder: (_, __, ___) =>
                                                      const ColoredBox(
                                                          color: Color(
                                                              0xFF262420)),
                                                )
                                              : const ColoredBox(
                                                  color: Color(0xFF262420)),
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      _Reel(spinning: playing),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // The VU meters, dancing while music plays.
                        AnimatedBuilder(
                          animation: _tick,
                          builder: (context, _) {
                            final t = _clock.elapsedMilliseconds / 1000.0;
                            final l = playing ? VuMotion.deflection(t) : 0.0;
                            final r = playing
                                ? VuMotion.deflection(t, phase: 0.9)
                                : 0.0;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(46, 25),
                                  painter: _VuPainter(deflection: l),
                                ),
                                const SizedBox(height: 4),
                                CustomPaint(
                                  size: const Size(46, 25),
                                  painter: _VuPainter(deflection: r),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One small VU meter: cream face, tick arc with a red zone, and a needle
/// pivoting from the bottom edge.
class _VuPainter extends CustomPainter {
  final double deflection;

  const _VuPainter({required this.deflection});

  @override
  void paint(Canvas canvas, Size size) {
    final face =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3));
    canvas.drawRRect(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF2E9D4), Color(0xFFD8C7A0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black.withValues(alpha: 0.55),
    );

    final pivot = Offset(size.width / 2, size.height - 2);
    const start = -2.35; // needle sweep, radians (leftmost)
    const sweep = 1.55; // to rightmost

    // Scale ticks along the arc; the last third is the red zone.
    for (var i = 0; i <= 6; i++) {
      final f = i / 6;
      final a = start + sweep * f;
      final outer = pivot + Offset.fromDirection(a, size.height - 6);
      final inner = pivot + Offset.fromDirection(a, size.height - 9.5);
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..strokeWidth = 1
          ..color = f > 0.66
              ? const Color(0xFFB33A2C)
              : Colors.black.withValues(alpha: 0.6),
      );
    }

    // The needle.
    final angle = start + sweep * deflection.clamp(0.0, 1.0);
    canvas.drawLine(
      pivot,
      pivot + Offset.fromDirection(angle, size.height - 5),
      Paint()
        ..strokeWidth = 1.3
        ..color = const Color(0xFF7E241B),
    );
    canvas.drawCircle(pivot, 1.8, Paint()..color = const Color(0xFF3A3733));

    // Glass glare.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 2, size.width - 4, size.height * 0.32),
          const Radius.circular(2)),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
  }

  @override
  bool shouldRepaint(_VuPainter old) => old.deflection != deflection;
}

/// A small deck reel that turns while the music plays.
class _Reel extends StatefulWidget {
  final bool spinning;

  const _Reel({required this.spinning});

  @override
  State<_Reel> createState() => _ReelState();
}

class _ReelState extends State<_Reel> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _spin.repeat();
  }

  @override
  void didUpdateWidget(_Reel old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_spin.isAnimating) _spin.repeat();
    if (!widget.spinning && _spin.isAnimating) _spin.stop();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _spin,
      child: const CustomPaint(size: Size(22, 22), painter: _ReelPainter()),
    );
  }
}

class _ReelPainter extends CustomPainter {
  const _ReelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFFD8D8D2);
    canvas.drawCircle(c, r - 1, ring);
    final spoke = Paint()
      ..strokeWidth = 1.4
      ..color = const Color(0xFFD8D8D2);
    for (var i = 0; i < 3; i++) {
      final a = i * 2.0943951; // 120°
      canvas.drawLine(c, c + Offset.fromDirection(a, r - 3), spoke);
    }
    canvas.drawCircle(c, 2.2, Paint()..color = const Color(0xFFD8D8D2));
  }

  @override
  bool shouldRepaint(_ReelPainter old) => false;
}

/// The little bakelite radio that tunes into Spotify search.
class _Radio extends StatelessWidget {
  final VoidCallback onTap;

  const _Radio({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Antenna.
          Positioned(
            top: -18,
            right: 12,
            child: Transform.rotate(
              angle: -0.45,
              child: Container(
                width: 2,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF9C9C9C),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          Container(
            width: 104,
            height: 88,
            padding: const EdgeInsets.all(9),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Tuning dial with tick ring.
                      const SizedBox(
                        width: 34,
                        height: 34,
                        child: CustomPaint(painter: _DialPainter()),
                      ),
                      const SizedBox(width: 8),
                      // Speaker grill.
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (var i = 0; i < 4; i++)
                              Container(
                                width: 3.5,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'SEARCH',
                  style: GoogleFonts.robotoMono(
                    fontSize: 7.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                    color: const Color(0xFFF4EFE6).withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The radio's tuning dial: cream face, tick ring, red needle.
class _DialPainter extends CustomPainter {
  const _DialPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFF2E9D4), Color(0xFFC9B588)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.black.withValues(alpha: 0.4),
    );
    // Tick ring.
    final tick = Paint()
      ..strokeWidth = 0.9
      ..color = const Color(0xFF352314).withValues(alpha: 0.55);
    for (var i = 0; i < 10; i++) {
      final a = i * (2 * 3.14159265 / 10);
      canvas.drawLine(
        c + Offset.fromDirection(a, r - 5),
        c + Offset.fromDirection(a, r - 2.5),
        tick,
      );
    }
    // Needle.
    canvas.drawLine(
      c + Offset.fromDirection(0.7, -6),
      c + Offset.fromDirection(0.7, 9),
      Paint()
        ..strokeWidth = 1.5
        ..color = const Color(0xFF8A2F23),
    );
    canvas.drawCircle(c, 1.6, Paint()..color = const Color(0xFF3A2B14));
  }

  @override
  bool shouldRepaint(_DialPainter old) => false;
}
