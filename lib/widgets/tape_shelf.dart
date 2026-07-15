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
/// board, and a small brass plaque with the playlist's name. Pressing it
/// eases the whole shelf toward you before the POV swings over.
class _ShelfRow extends StatefulWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const _ShelfRow({required this.playlist, required this.onTap});

  static const double _height = 98;
  static const double _board = 16;

  @override
  State<_ShelfRow> createState() => _ShelfRowState();
}

class _ShelfRowState extends State<_ShelfRow> {
  bool _pressed = false;

  Playlist get playlist => widget.playlist;

  int get _trackCount =>
      playlist.tapes?.length ??
      (playlist.trackCount > 0 ? playlist.trackCount : 0);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: SizedBox(
            height: _ShelfRow._height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Inside of the case, falling into shadow behind the tapes.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: _ShelfRow._board - 2,
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
                  bottom: _ShelfRow._board - 1,
                  child: _SpineRow(playlist: playlist, trackCount: _trackCount),
                ),
                // The shelf board they stand on.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _ShelfRow._board,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2.5),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFD9BC7D), Color(0xFF8F6F3F)],
                        ),
                        border: Border.all(
                            color: const Color(0xFF5E4726), width: 0.7),
                      ),
                      child: Text(
                        _trackCount > 0
                            ? '${playlist.name.toUpperCase()} · $_trackCount'
                            : playlist.name.toUpperCase(),
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
        // A shelf whose true size we don't know yet (metadata missing, tracks
        // not loaded) still gets dressed — it should never look bare.
        final visible = trackCount > 0
            ? ShelfLook.visibleCount(trackCount: trackCount, slots: slots)
            : ShelfLook.placeholderCount(
                seed: playlist.id.hashCode, slots: slots);
        final looks = ShelfLook.spines(
          seed: playlist.id.hashCode,
          count: visible,
          paletteSize: kTapePalette.length,
        );
        return SizedBox(
          height: _maxH,
          width: double.infinity,
          child: CustomPaint(
            painter: _SpinesPainter(
              looks: looks,
              seedKey: playlist.id.hashCode ^ visible,
            ),
          ),
        );
      },
    );
  }
}

/// Paints a whole row of spines in one pass, with the same material care as
/// the cassette painters: curved plastic (light edge into shadowed edge), a
/// lit top arris, a paper label with faint print scratches, an accent stripe,
/// and a soft contact shadow where each tape meets the board.
class _SpinesPainter extends CustomPainter {
  final List<SpineLook> looks;
  final int seedKey;

  const _SpinesPainter({required this.looks, required this.seedKey});

  static const double _w = _SpineRow._spineW;
  static const double _gap = _SpineRow._gap;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < looks.length; i++) {
      final look = looks[i];
      final palette = kTapePalette[look.paletteIndex];
      final x = i * (_w + _gap);
      final h = size.height * look.heightFactor;
      final top = size.height - h;

      canvas.save();
      if (look.leansLeft) {
        canvas.translate(x + _w / 2, size.height);
        canvas.rotate(-0.07);
        canvas.translate(-(x + _w / 2), -size.height);
      }

      // Contact shadow where the tape meets the shelf board.
      canvas.drawOval(
        Rect.fromLTWH(x - 1, size.height - 2.5, _w + 3, 4),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.32)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );

      // Curved plastic shell: lit on the left, rolling into shadow.
      final body = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, _w, h), const Radius.circular(1.5));
      canvas.drawRRect(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color.lerp(palette.body, Colors.white, 0.18)!,
              palette.body,
              Color.lerp(palette.body, Colors.black, 0.35)!,
            ],
            stops: const [0.0, 0.32, 1.0],
          ).createShader(Rect.fromLTWH(x, top, _w, h)),
      );

      // Light on the top arris.
      canvas.drawLine(
        Offset(x + 0.6, top + 0.7),
        Offset(x + _w - 0.6, top + 0.7),
        Paint()
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.30),
      );

      // Paper label with faint print scratches.
      final label = RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 1.5, top + 5, _w - 3, 8), const Radius.circular(1));
      canvas.drawRRect(label, Paint()..color = palette.label);
      final scratch = Paint()
        ..strokeWidth = 0.6
        ..color = const Color(0xFF33261A).withValues(alpha: 0.35);
      canvas.drawLine(
          Offset(x + 3, top + 7.6), Offset(x + _w - 3, top + 7.6), scratch);
      canvas.drawLine(
          Offset(x + 3, top + 10.2), Offset(x + _w - 4.5, top + 10.2), scratch);

      // Accent stripe under the label.
      canvas.drawRect(Rect.fromLTWH(x + 1.5, top + 15, _w - 3, 2),
          Paint()..color = palette.stripe);

      // The right edge falls into the gap between tapes.
      canvas.drawLine(
        Offset(x + _w - 0.6, top + 1),
        Offset(x + _w - 0.6, size.height - 1),
        Paint()
          ..strokeWidth = 1
          ..color = Colors.black.withValues(alpha: 0.2),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SpinesPainter old) =>
      old.seedKey != seedKey || old.looks.length != looks.length;
}
