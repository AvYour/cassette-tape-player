import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';

class LyricScroller extends StatelessWidget {
  final String trackName;
  final String artistName;
  final String albumName;

  const LyricScroller({
    super.key,
    required this.trackName,
    required this.artistName,
    required this.albumName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              trackName,
              key: ValueKey(trackName),
              style: GoogleFonts.specialElite(
                fontSize: 17,
                color: kTextDark,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 5),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              artistName,
              key: ValueKey(artistName),
              style: GoogleFonts.courierPrime(
                fontSize: 13,
                color: kTextDark.withOpacity(0.68),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              albumName,
              key: ValueKey(albumName),
              style: GoogleFonts.courierPrime(
                fontSize: 11,
                color: kTextDark.withOpacity(0.42),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
