import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Geometry for the shimmer that sweeps across a skeleton placeholder.
class SkeletonShimmer {
  const SkeletonShimmer._();

  /// How wide the bright band is, as a fraction of the box.
  static const double bandWidth = 0.35;

  /// Where the band's centre sits for animation progress [t] (0..1), in
  /// gradient space. It starts left of the box and ends right of it, so the
  /// highlight always travels fully through and never rests inside.
  static double bandCenter(double t) {
    final clamped = t.clamp(0.0, 1.0);
    return -bandWidth + clamped * (1 + 2 * bandWidth);
  }

  /// Three ordered gradient stops — the band's leading edge, its centre and
  /// its trailing edge — clamped to the legal 0..1 range.
  static List<double> stops(double t) {
    final c = bandCenter(t);
    final a = (c - bandWidth).clamp(0.0, 1.0).toDouble();
    final b = c.clamp(0.0, 1.0).toDouble();
    final d = (c + bandWidth).clamp(0.0, 1.0).toDouble();
    // Keep them strictly ordered even after clamping, which LinearGradient
    // requires.
    final mid = math.max(a, b);
    return [a, mid, math.max(mid, d)];
  }
}

/// Drives one shared shimmer clock for every skeleton on screen, so a whole
/// page of placeholders pulses together instead of each on its own phase.
class _ShimmerClock extends StatefulWidget {
  final Widget child;

  const _ShimmerClock({required this.child});

  @override
  State<_ShimmerClock> createState() => _ShimmerClockState();
}

class _ShimmerClockState extends State<_ShimmerClock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ShimmerScope(clock: _c, child: widget.child);
}

class _ShimmerScope extends InheritedWidget {
  final Animation<double> clock;

  const _ShimmerScope({required this.clock, required super.child});

  static Animation<double>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_ShimmerScope>()
      ?.clock;

  @override
  bool updateShouldNotify(_ShimmerScope old) => old.clock != clock;
}

/// One grey placeholder block with a light sweeping across it. Sized like the
/// real thing it stands in for, so the layout doesn't jump when data lands.
class Skeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const Skeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  /// Wraps a subtree so every [Skeleton] inside shares one shimmer clock.
  static Widget group({required Widget child}) => _ShimmerClock(child: child);

  static const Color _base = Color(0xFFE4E1EF);
  static const Color _glint = Color(0xFFF6F4FB);

  @override
  Widget build(BuildContext context) {
    final clock = _ShimmerScope.maybeOf(context);
    final box = SizedBox(width: width, height: height);
    if (clock == null) {
      // Outside a group: a plain, still block rather than nothing at all.
      return DecoratedBox(
        decoration: BoxDecoration(
          color: _base,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: box,
      );
    }
    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [_base, _glint, _base],
            stops: SkeletonShimmer.stops(clock.value),
          ),
        ),
        child: box,
      ),
    );
  }
}

/// A stand-in for one [TrackRow] / album row: square art, two text lines.
class SkeletonTrackRow extends StatelessWidget {
  final bool round;

  const SkeletonTrackRow({super.key, this.round = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Skeleton(width: 50, height: 50, radius: round ? 25 : 14),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Skeleton(width: 170, height: 13, radius: 6),
                  SizedBox(height: 7),
                  Skeleton(width: 105, height: 11, radius: 6),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Skeleton(width: 30, height: 10, radius: 5),
          ],
        ),
      ),
    );
  }
}

/// A list of track placeholders, sharing one shimmer.
class SkeletonList extends StatelessWidget {
  final int count;
  final bool round;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.count = 7,
    this.round = false,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Skeleton.group(
      child: ListView(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < count; i++) SkeletonTrackRow(round: round),
        ],
      ),
    );
  }
}

/// A stand-in for the Explore wheel while playlists are still loading: the
/// focused row on its glass lozenge, the rest falling away — the same shape
/// the real wheel takes, so nothing shifts when the names arrive.
class SkeletonWheel extends StatelessWidget {
  final double rowExtent;

  const SkeletonWheel({super.key, this.rowExtent = 106});

  @override
  Widget build(BuildContext context) {
    return Skeleton.group(
      child: LayoutBuilder(
        builder: (context, cons) {
          final rows = math.max(3, (cons.maxHeight / rowExtent).floor());
          final focus = rows ~/ 2;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < rows; i++)
                Opacity(
                  // Same fall-away as the wheel: brightest on the reading line.
                  opacity: (1 - (i - focus).abs() / 3).clamp(0.15, 1.0),
                  child: SizedBox(
                    height: rowExtent,
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: 8 + (i - focus).abs() * 22.0, right: 28),
                      child: Row(
                        children: [
                          const Skeleton(width: 74, height: 74, radius: 37),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Skeleton(width: 150, height: 15, radius: 7),
                                SizedBox(height: 8),
                                Skeleton(width: 90, height: 12, radius: 6),
                              ],
                            ),
                          ),
                          if (i == focus) ...[
                            const SizedBox(width: 8),
                            const Skeleton(width: 74, height: 38, radius: 24),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
