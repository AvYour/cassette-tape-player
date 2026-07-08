import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TapeCounter extends StatelessWidget {
  final double progress;

  const TapeCounter({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final value = (progress.clamp(0.0, 1.0) * 999).round();
    final hundreds = (value ~/ 100).toString();
    final tens = ((value % 100) ~/ 10).toString();
    final ones = (value % 10).toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Digit(digit: hundreds),
          _Divider(),
          _Digit(digit: tens),
          _Divider(),
          _Digit(digit: ones),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

class _Digit extends StatelessWidget {
  final String digit;

  const _Digit({required this.digit});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 140),
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.6),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
      child: Text(
        digit,
        key: ValueKey(digit),
        style: GoogleFonts.vt323(
          fontSize: 26,
          color: const Color(0xFFD6A033),
          letterSpacing: 2,
        ),
      ),
    );
  }
}
