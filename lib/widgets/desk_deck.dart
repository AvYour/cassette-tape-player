import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../painters/wood_painter.dart';
import '../services/spotify_service.dart';

/// The desk of the 1985 room: a wooden desktop carrying the tape deck (the
/// room's living now-playing — reels turn while music plays; tap to reopen the
/// full player) and a little bakelite radio that opens search.
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
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The desktop slab.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 112,
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
                    child:
                        ColoredBox(color: Colors.white.withValues(alpha: 0.22)),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 22,
            child: _TapeDeck(service: service, onTap: onOpenPlayer),
          ),
          Positioned(
            right: 14,
            bottom: 26,
            child: _Radio(onTap: onOpenSearch),
          ),
        ],
      ),
    );
  }
}

/// The deck: LCD readout and a small cassette bay whose reels spin while
/// Spotify plays. Tapping it reopens the full player for the loaded tape.
class _TapeDeck extends StatelessWidget {
  final SpotifyService service;
  final VoidCallback onTap;

  const _TapeDeck({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final tape = service.nowPlaying;
        final playing = service.isPlaying;
        return GestureDetector(
          onTap: tape == null ? null : onTap,
          child: Container(
            width: 208,
            height: 100,
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
                // Cassette bay.
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(10, 2, 10, 10),
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
                              const SizedBox(width: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: SizedBox(
                                  width: 44,
                                  height: 30,
                                  child: tape.thumbUrl != null &&
                                          tape.thumbUrl!.isNotEmpty
                                      ? Image.network(
                                          tape.thumbUrl!,
                                          fit: BoxFit.cover,
                                          cacheWidth: 130,
                                          errorBuilder: (_, __, ___) =>
                                              const ColoredBox(
                                                  color: Color(0xFF262420)),
                                        )
                                      : const ColoredBox(
                                          color: Color(0xFF262420)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _Reel(spinning: playing),
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
      canvas.drawLine(
        c,
        c + Offset.fromDirection(a, r - 3),
        spoke,
      );
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
                      // Tuning dial.
                      Container(
                        width: 34,
                        height: 34,
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
                            angle: 0.7,
                            child: Container(
                              width: 1.6,
                              height: 13,
                              color: const Color(0xFF8A2F23),
                            ),
                          ),
                        ),
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
