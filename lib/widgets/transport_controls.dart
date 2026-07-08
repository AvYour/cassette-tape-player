import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cassette_tape.dart';
import '../utils/colors.dart';

class TransportControls extends StatelessWidget {
  final TapeState tapeState;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onSkipNext;
  final VoidCallback onSkipPrevious;
  final VoidCallback onFfStart;
  final VoidCallback onFfEnd;
  final VoidCallback onRewStart;
  final VoidCallback onRewEnd;

  const TransportControls({
    super.key,
    required this.tapeState,
    required this.isPlaying,
    required this.onPlay,
    required this.onPause,
    required this.onSkipNext,
    required this.onSkipPrevious,
    required this.onFfStart,
    required this.onFfEnd,
    required this.onRewStart,
    required this.onRewEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: kControlPanel,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TapeButton(
            icon: Icons.fast_rewind_rounded,
            onTap: onRewEnd,
            onLongPressStart: (_) {
              HapticFeedback.lightImpact();
              onRewStart();
            },
            onLongPressEnd: (_) => onRewEnd(),
          ),
          _TapeButton(
            icon: Icons.skip_previous_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              onSkipPrevious();
            },
          ),
          _TapeButton(
            icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            iconSize: 34,
            diameter: 56,
            onTap: () {
              HapticFeedback.mediumImpact();
              isPlaying ? onPause() : onPlay();
            },
          ),
          _TapeButton(
            icon: Icons.skip_next_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              onSkipNext();
            },
          ),
          _TapeButton(
            icon: Icons.fast_forward_rounded,
            onTap: onFfEnd,
            onLongPressStart: (_) {
              HapticFeedback.lightImpact();
              onFfStart();
            },
            onLongPressEnd: (_) => onFfEnd(),
          ),
        ],
      ),
    );
  }
}

class _TapeButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double iconSize;
  final double diameter;
  final void Function(LongPressStartDetails)? onLongPressStart;
  final void Function(LongPressEndDetails)? onLongPressEnd;

  const _TapeButton({
    required this.icon,
    this.onTap,
    this.iconSize = 22,
    this.diameter = 44,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  State<_TapeButton> createState() => _TapeButtonState();
}

class _TapeButtonState extends State<_TapeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      onLongPressStart: widget.onLongPressStart,
      onLongPressEnd: widget.onLongPressEnd,
      child: AnimatedScale(
        scale: _pressed ? 0.86 : 1.0,
        duration: const Duration(milliseconds: 70),
        child: Container(
          width: widget.diameter,
          height: widget.diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3A3A3A), Color(0xFF111111)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: Colors.white.withValues(alpha: 0.88),
            size: widget.iconSize,
          ),
        ),
      ),
    );
  }
}
