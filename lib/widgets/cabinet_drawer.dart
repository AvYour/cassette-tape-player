import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/playlist.dart';

/// A filing-cabinet drawer representing one playlist, meant to sit flush
/// inside the cabinet carcass (see `_CabinetBody` in the cabinet screen). The
/// wooden face rests in a dark drawer OPENING — the recessed gap you'd see
/// around a real drawer front — rather than floating like a list card.
/// Tapping it swings the POV over the drawer (the cabinet screen pushes
/// [DrawerScreen]); while that view is open the face holds its "pulled" pose.
class CabinetDrawer extends StatelessWidget {
  final Playlist playlist;
  final bool isOpen;
  final VoidCallback onTap;
  final int? loadedCount;

  const CabinetDrawer({
    super.key,
    required this.playlist,
    required this.isOpen,
    required this.onTap,
    this.loadedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // The dark cavity behind/around the drawer front.
        color: const Color(0xFF20130A),
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          // A hairline of light catching the opening's lower lip.
          BoxShadow(
            color: Color(0x14FFFFFF),
            blurRadius: 0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      // The face sits proud of its opening: a slim, even gap at the sides and
      // a deeper shadow gap below.
      padding: const EdgeInsets.fromLTRB(3, 3, 3, 6),
      child: _DrawerFace(
        playlist: playlist,
        isOpen: isOpen,
        onTap: onTap,
        loadedCount: loadedCount,
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
    final count =
        loadedCount ?? (playlist.trackCount > 0 ? playlist.trackCount : null);
    final prefix = count != null ? '$count tapes · ' : '';
    return '$prefix${playlist.owner}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        // The face swells a touch when pulled, as if it came toward you.
        scale: isOpen ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: 76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isOpen
                  ? const [Color(0xFF6E4A2E), Color(0xFF573923)]
                  : const [Color(0xFF7C5537), Color(0xFF5E3E27)],
            ),
            boxShadow: [
              // Seated in its opening the face casts only a sliver of shadow;
              // pulled, it floats forward with a deeper one.
              BoxShadow(
                color: Colors.black.withValues(alpha: isOpen ? 0.5 : 0.35),
                blurRadius: isOpen ? 14 : 3,
                offset: Offset(0, isOpen ? 8 : 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Wood grain + bevel.
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: CustomPaint(painter: WoodGrainPainter()),
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
                    // A paper card in a brass card-catalog holder.
                    Expanded(
                      child: _BrassLabelHolder(
                        title: playlist.name.toUpperCase(),
                        subtitle: _subtitle,
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
      ),
    );
  }
}

/// A card-catalog label holder: a bevelled brass frame screwed to the drawer,
/// with a typewritten paper card slipped in behind it. The card tucks UNDER
/// the frame (inner shadow along the top) instead of floating on the wood.
class _BrassLabelHolder extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BrassLabelHolder({required this.title, required this.subtitle});

  static const Color _ink = Color(0xFF33261A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        // Bevelled brass: catches light on top, shades toward the bottom.
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD9BC7D), Color(0xFFA5814C), Color(0xFF7C5D33)],
          stops: [0.0, 0.55, 1.0],
        ),
        border: Border.all(color: const Color(0xFF5E4726), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // Wider side rails leave room for the mounting screws.
      padding: const EdgeInsets.fromLTRB(11, 4, 11, 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The paper card.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF6EEDC),
              borderRadius: BorderRadius.circular(2.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.specialElite(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 1.5),
                // The red rule of an index card.
                Container(height: 1, color: const Color(0x40A33D2E)),
                const SizedBox(height: 2.5),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.robotoMono(
                    fontSize: 9,
                    color: _ink.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // The card is slipped in behind the frame: shadow along the top lip.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 5,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(2.5)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Mounting screws on the side rails.
          Positioned(left: -8, top: 0, bottom: 0, child: _screw()),
          Positioned(right: -8, top: 0, bottom: 0, child: _screw()),
        ],
      ),
    );
  }

  Widget _screw() => Center(
        child: Container(
          width: 4.5,
          height: 4.5,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0xFFEADFB9), Color(0xFF6B5227)],
            ),
          ),
        ),
      );
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

/// Paints warm wood tones with faint horizontal grain and a top bevel. Public
/// so the cabinet carcass (cabinet screen) shares the same timber.
class WoodGrainPainter extends CustomPainter {
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
  bool shouldRepaint(WoodGrainPainter old) => false;
}
