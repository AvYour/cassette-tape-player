import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/playlist.dart';
import '../painters/wood_painter.dart';
import '../utils/colors.dart';
import '../utils/shelf_look.dart';

/// The wall unit of the 1985 room: an open wooden bookcase whose rows are the
/// playlists, dressed with stylized cassette spines standing on each shelf.
/// (The real album-art tapes appear when a shelf is taken down — the top-down
/// drawer view.) The dressing is seeded per playlist, so the shelf always
/// looks lived-in the same way.
class TapeShelf extends StatelessWidget {
  final List<Playlist> playlists;
  final void Function(Playlist) onOpen;

  const TapeShelf({super.key, required this.playlists, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // The bookcase timber.
            const Positioned.fill(
              child: CustomPaint(
                painter: WoodPainter(
                  light: Color(0xFF8A5F3C),
                  dark: Color(0xFF69452A),
                  seed: 17,
                  bevelled: false,
                ),
              ),
            ),
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              itemCount: playlists.length,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                child: _ShelfRow(
                  playlist: playlists[i],
                  onTap: () => onOpen(playlists[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One shelf: the dark inside of the case, a row of tapes standing on the
/// board, and a small brass plaque with the playlist's name.
class _ShelfRow extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const _ShelfRow({required this.playlist, required this.onTap});

  static const double _height = 98;
  static const double _board = 16;

  int get _trackCount =>
      playlist.tapes?.length ??
      (playlist.trackCount > 0 ? playlist.trackCount : 0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: _height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Inside of the case, falling into shadow behind the tapes.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: _board - 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1D1006), Color(0xFF33200F)],
                  ),
                ),
              ),
            ),
            // The filed tapes.
            Positioned(
              left: 8,
              right: 8,
              bottom: _board - 1,
              child: _SpineRow(playlist: playlist, trackCount: _trackCount),
            ),
            // The shelf board they stand on.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _board,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF9A6C44), Color(0xFF6B4629)],
                  ),
                  border: const Border(
                    top: BorderSide(color: Color(0x2EFFFFFF), width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            // Brass plaque on the board's face.
            Positioned(
              left: 10,
              right: 10,
              bottom: 1.5,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.5),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFD9BC7D), Color(0xFF8F6F3F)],
                    ),
                    border:
                        Border.all(color: const Color(0xFF5E4726), width: 0.7),
                  ),
                  child: Text(
                    '${playlist.name.toUpperCase()} · $_trackCount',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.robotoMono(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: const Color(0xFF3A2B14),
                    ),
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

/// Stylized spines standing shoulder to shoulder, heights varying, the odd
/// one leaning against its neighbour.
class _SpineRow extends StatelessWidget {
  final Playlist playlist;
  final int trackCount;

  const _SpineRow({required this.playlist, required this.trackCount});

  static const double _spineW = 11;
  static const double _gap = 2;
  static const double _maxH = 64;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slots = (constraints.maxWidth / (_spineW + _gap)).floor();
        final visible =
            ShelfLook.visibleCount(trackCount: trackCount, slots: slots);
        final looks = ShelfLook.spines(
          seed: playlist.id.hashCode,
          count: visible,
          paletteSize: kTapePalette.length,
        );
        return SizedBox(
          height: _maxH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final look in looks)
                Padding(
                  padding: const EdgeInsets.only(right: _gap),
                  child: Transform.rotate(
                    angle: look.leansLeft ? -0.07 : 0,
                    alignment: Alignment.bottomCenter,
                    child: _Spine(look: look),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Spine extends StatelessWidget {
  final SpineLook look;

  const _Spine({required this.look});

  @override
  Widget build(BuildContext context) {
    final palette = kTapePalette[look.paletteIndex];
    return Container(
      width: _SpineRow._spineW,
      height: _SpineRow._maxH * look.heightFactor,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1.5),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            palette.body,
            Color.lerp(palette.body, Colors.black, 0.3)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 2,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // The little cream label band near the top of the spine.
          Positioned(
            top: 5,
            left: 1.5,
            right: 1.5,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.label,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // Its accent stripe.
          Positioned(
            top: 15,
            left: 1.5,
            right: 1.5,
            height: 2,
            child: ColoredBox(color: palette.stripe),
          ),
        ],
      ),
    );
  }
}
