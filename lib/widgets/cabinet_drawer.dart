import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cassette_tape.dart';
import '../models/playlist.dart';
import '../painters/cassette_tape_painter.dart';
import '../utils/colors.dart';
import 'cassette_tape_view.dart';

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
          _DrawerFace(playlist: playlist, isOpen: isOpen, onTap: onTap),
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

  const _DrawerFace({
    required this.playlist,
    required this.isOpen,
    required this.onTap,
  });

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
            // Top edge highlight for a bevelled wooden look.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10)),
                ),
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
                          '${playlist.trackCount} tapes · ${playlist.owner}',
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
                  // Metal drawer handle.
                  Container(
                    width: 54,
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFECECEC), Color(0xFF9A9A9A)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    // Upright cassette: portrait footprint derived from the tray height.
    const trayHeight = 210.0;
    const uprightHeight = trayHeight - 40; // vertical padding
    const uprightWidth = uprightHeight / kCassetteAspect;
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final tape = list[i];
        return Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: () => onTapeTap(tape),
            child: SizedBox(
              width: uprightWidth,
              height: uprightHeight,
              child: Hero(
                tag: 'tape_${tape.id}',
                flightShuttleBuilder: cassetteFlightShuttle(tape),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: CassetteTapeView(tape: tape),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
