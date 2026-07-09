import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cassette_tape.dart';
import '../models/playlist.dart';
import '../utils/colors.dart';
import 'cassette_spine.dart';

/// A filing-cabinet drawer representing one playlist. Closed, it shows a wooden
/// drawer face with a metal handle and label. Tapping pulls the drawer open —
/// it slides forward and a recessed tray of upright cassettes is revealed.
class CabinetDrawer extends StatelessWidget {
  final Playlist playlist;
  final bool isOpen;
  final VoidCallback onTap;
  final bool loading;
  final List<CassetteTape>? tapes;
  final String? loadError;
  final void Function(CassetteTape tape) onTapeTap;

  const CabinetDrawer({
    super.key,
    required this.playlist,
    required this.isOpen,
    required this.onTap,
    required this.loading,
    required this.tapes,
    this.loadError,
    required this.onTapeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          _DrawerFace(
            playlist: playlist,
            isOpen: isOpen,
            onTap: onTap,
            loadedCount: tapes?.length,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            child: isOpen
                ? _DrawerTray(
                    loading: loading,
                    tapes: tapes,
                    loadError: loadError,
                    onTapeTap: onTapeTap,
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

class _DrawerFace extends StatelessWidget {
  final Playlist playlist;
  final bool isOpen;
  final VoidCallback onTap;
  final int? loadedCount;

  const _DrawerFace({
    required this.playlist,
    required this.isOpen,
    required this.onTap,
    this.loadedCount,
  });

  String get _subtitle {
    final count = loadedCount ?? (playlist.trackCount > 0 ? playlist.trackCount : null);
    final prefix = count != null ? '$count tapes · ' : '';
    return '$prefix${playlist.owner}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        height: 76,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(10),
            bottom: Radius.circular(isOpen ? 2 : 10),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isOpen
                ? const [Color(0xFF6E4A2E), Color(0xFF573923)]
                : const [Color(0xFF7C5537), Color(0xFF5E3E27)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isOpen ? 0.5 : 0.3),
              blurRadius: isOpen ? 14 : 8,
              offset: Offset(0, isOpen ? 8 : 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Wood grain + bevel.
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(10),
                  bottom: Radius.circular(isOpen ? 2 : 10),
                ),
                child: CustomPaint(painter: _WoodGrainPainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  // Accent color chip for the playlist.
                  Container(
                    width: 6,
                    height: 40,
                    decoration: BoxDecoration(
                      color: playlist.accent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.robotoMono(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF4EFE6),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.robotoMono(
                            fontSize: 10,
                            color: const Color(0xFFF4EFE6).withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Recessed metal cup handle with mounting screws.
                  _CupHandle(open: isOpen),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A recessed drawer cup handle: dark inset well, brushed-metal bar, two screws.
class _CupHandle extends StatelessWidget {
  final bool open;

  const _CupHandle({required this.open});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1C1206), Color(0xFF3A2716)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Brushed metal grip bar.
          Container(
            width: 44,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF2F2F2),
                  Color(0xFFBDBDBD),
                  Color(0xFF8A8A8A),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 2,
                  offset: Offset(0, open ? 1 : 2),
                ),
              ],
            ),
          ),
          Positioned(left: 4, child: _screw()),
          Positioned(right: 4, child: _screw()),
        ],
      ),
    );
  }

  Widget _screw() => Container(
        width: 5,
        height: 5,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0xFFCFCFCF), Color(0xFF5A5A5A)],
          ),
        ),
      );
}

/// Paints warm wood tones with faint horizontal grain and a top bevel.
class _WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final grain = Paint()
      ..strokeWidth = 1
      ..color = Colors.black.withValues(alpha: 0.05);
    for (double y = 4; y < size.height; y += 5) {
      final wobble = (rnd.nextDouble() - 0.5) * 3;
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(
            size.width / 2, y + wobble, size.width, y + wobble * 0.4);
      canvas.drawPath(path, grain);
    }
    // Top bevel highlight and bottom shade.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 2),
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 3, size.width, 3),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );
  }

  @override
  bool shouldRepaint(_WoodGrainPainter old) => false;
}

class _DrawerTray extends StatelessWidget {
  final bool loading;
  final List<CassetteTape>? tapes;
  final String? loadError;
  final void Function(CassetteTape tape) onTapeTap;

  const _DrawerTray({
    required this.loading,
    required this.tapes,
    required this.loadError,
    required this.onTapeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 210,
      decoration: const BoxDecoration(
        // Recessed inside-of-drawer look.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1C12), Color(0xFF3A2717)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2, color: kGold),
        ),
      );
    }
    final list = tapes ?? const [];
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            loadError ?? 'Empty drawer',
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
    // Filed tapes in a coverflow: the centred one lifts out of the drawer.
    return _SpineCarousel(tapes: list, onTapeTap: onTapeTap);
  }
}

/// Horizontal coverflow of cassette spines. The spine nearest the centre
/// rises and enlarges (as if pulled up from the drawer); swiping brings the
/// next tape forward. Tap the raised spine to open it.
class _SpineCarousel extends StatefulWidget {
  final List<CassetteTape> tapes;
  final void Function(CassetteTape tape) onTapeTap;

  const _SpineCarousel({required this.tapes, required this.onTapeTap});

  @override
  State<_SpineCarousel> createState() => _SpineCarouselState();
}

class _SpineCarouselState extends State<_SpineCarousel> {
  // Small fraction packs the spines tightly, like a full drawer of tapes.
  late final PageController _controller =
      PageController(viewportFraction: 0.15);
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _page = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.tapes.length,
      clipBehavior: Clip.none,
      itemBuilder: (context, i) {
        final distance = (_page - i).abs().clamp(0.0, 1.0);
        final scale = 1.18 - 0.34 * distance; // focused biggest
        final lift = (1 - distance) * 20; // focused rises out
        final tape = widget.tapes[i];
        return Center(
          child: Transform.translate(
            offset: Offset(0, -lift),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: 1 - 0.35 * distance,
                child: CassetteSpine(
                  tape: tape,
                  onTap: () {
                    if ((_page - i).abs() < 0.5) {
                      widget.onTapeTap(tape);
                    } else {
                      _controller.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
