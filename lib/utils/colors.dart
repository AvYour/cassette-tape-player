import 'package:flutter/material.dart';

// Palette ported one-to-one from the reference cassette UI.
// Lyric reel: the focused line is bright cream and fades to a soft taupe for
// distant lines (over the flowing album-color background), so it never reads
// as a dark/muddy wash.
const Color kVintageInk = Color(0xFFC9BEB0);
const Color kActiveLyric = Color(0xFFF7F1E6);
const Color kTextDark = Color(0xFF221F1C);

const Color kBgCenter = Color(0xFFFAF6F0);
const Color kBgEdge = Color(0xFFDFD6C2);
const Color kBgVignette = Color(0x1A4A3B2A);

const Color kTapeBrown = Color(0xFF523321);
const Color kTapeDark = Color(0xFF22140D);
const Color kWindowBg = Color(0xFF0D0D0D);

const Color kControlPanelBg = Color(0xFF151515);
const Color kMark = Color(0xFF7A7366);

const Color kGold = Color(0xFFD6A033);
const Color kCream = Color(0xFFDCD5C6);

// --- Daylight reskin -------------------------------------------------------
// The deck keeps all its machinery — reels, VU needles, seven keys — but it
// now sits in the same lavender room as Explore instead of a dark one. These
// are the surfaces that used to be black: the panel, the key sockets, the
// backing plate behind the cassette, and the lyric reel's ink.
const Color kPanelLight = Color(0xFFFFFFFF);
const Color kPanelSeam = Color(0xFFEAE7F3);
const Color kPanelWell = Color(0xFFE7E4F2);
const Color kInkLight = Color(0xFF14121C);
const Color kInkMuted = Color(0xFF9A96AA);
const Color kActiveLyricLight = Color(0xFF14121C);
const Color kFadedLyricLight = Color(0xFFB8B4C6);

/// Darkens by scaling RGB toward black (reference `Color.darken`).
Color darken(Color c, [double fraction = 0.2]) =>
    Color.lerp(c, const Color(0xFF000000), fraction)!;

/// body / label / stripe color set for a tape shell.
class TapeColors {
  final Color body;
  final Color label;
  final Color stripe;

  const TapeColors(this.body, this.label, this.stripe);
}

const List<TapeColors> kTapePalette = [
  TapeColors(Color(0xFFE6DBC4), Color(0xFFF4EFE6), Color(0xFFD94532)),
  TapeColors(Color(0xFF2A2A2A), Color(0xFFDCD5C6), Color(0xFFD6A033)),
  TapeColors(Color(0xFFE86658), Color(0xFFF4EFE6), Color(0xFF1E3A5F)),
  TapeColors(Color(0xFF1E3A5F), Color(0xFFE0E0E0), Color(0xFFE25A3B)),
  TapeColors(Color(0xFF2E4035), Color(0xFFE8E3D5), Color(0xFFD6A033)),
];
