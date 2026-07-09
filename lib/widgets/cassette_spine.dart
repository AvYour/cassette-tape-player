import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cassette_tape.dart';
import '../utils/colors.dart';

/// A cassette seen edge-on — the way tapes stand filed in a drawer. Shows a
/// small album-art thumbnail on the top cap and the title/artist printed up
/// the cream spine label. Compact, so many fit in a drawer at once.
class CassetteSpine extends StatelessWidget {
  final CassetteTape tape;
  final VoidCallback onTap;

  const CassetteSpine({super.key, required this.tape, required this.onTap});

  static const double width = 52;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              tape.bodyColor,
              darken(tape.bodyColor, 0.18),
              tape.bodyColor,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _topCap(),
            Container(height: 4, color: tape.stripeColor),
            Expanded(child: _label()),
            _bottomNotch(),
          ],
        ),
      ),
    );
  }

  Widget _topCap() {
    final art = tape.albumArtUrl;
    if (art != null && art.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        child: SizedBox(
          height: width,
          width: width,
          child: Image.network(
            art,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _slotCap(),
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : _slotCap(),
          ),
        ),
      );
    }
    return _slotCap();
  }

  // The dark top edge of a cassette with its two head openings.
  Widget _slotCap() {
    return Container(
      height: width,
      decoration: const BoxDecoration(
        color: Color(0xFF161616),
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _slot(),
            const SizedBox(width: 5),
            _slot(),
          ],
        ),
      ),
    );
  }

  Widget _slot() => Container(
        width: 6,
        height: 12,
        decoration: BoxDecoration(
          color: const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(1.5),
        ),
      );

  Widget _label() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EEDD),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: RotatedBox(
        quarterTurns: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          // FittedBox shrinks the text to fit the spine so the full title and
          // artist stay readable — no "..." truncation.
          child: Row(
            children: [
              Flexible(
                flex: 3,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    tape.trackName,
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.specialElite(
                      fontSize: 11,
                      color: kTextDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    tape.artistName,
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.courierPrime(
                      fontSize: 9,
                      color: kTextDark.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNotch() {
    return Container(
      height: 6,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
