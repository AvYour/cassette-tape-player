import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The daylight half of the app. The player is still a 1985 desk; everything
/// you browse on the way there — Explore, a playlist's tracks — is pale
/// lavender, white cards and plain black type, so the room is a place you
/// arrive at rather than the whole app.
class Explore {
  const Explore._();

  static const Color bgTop = Color(0xFFF1EFF9);
  static const Color bgBottom = Color(0xFFFBFAFE);
  static const Color card = Colors.white;
  static const Color ink = Color(0xFF14121C);
  static const Color muted = Color(0xFF9A96AA);
  static const Color hairline = Color(0xFFEAE7F3);

  static const LinearGradient backdrop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );

  /// The white lozenge under the focused row and the playlist header card.
  static List<BoxShadow> get lift => [
        BoxShadow(
          color: const Color(0xFF3B2E63).withValues(alpha: 0.10),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ];

  static TextStyle get screenTitle => GoogleFonts.plusJakartaSans(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: ink,
      );

  static TextStyle get rowTitle => GoogleFonts.plusJakartaSans(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: ink,
      );

  static TextStyle get rowOwner => GoogleFonts.plusJakartaSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: muted,
      );

  static TextStyle get chip => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: ink,
      );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: muted,
      );
}
