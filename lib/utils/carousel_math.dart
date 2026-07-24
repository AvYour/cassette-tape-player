import 'dart:math' as math;

/// Geometry for the Explore wheel: rows are laid out on a shallow arc, so the
/// one under the reading line sits full-size at the left edge and the rest fall
/// away — smaller, fainter, and drifting off to the right.
///
/// Every function takes [d], the signed distance in rows from the focused one
/// (0 = focused, +1 = one row below, -2 = two rows above), and is symmetric:
/// what happens above the focus happens below it.
class CarouselMath {
  const CarouselMath._();

  /// How far from the focus a row is still worth reading. Past this the row is
  /// fully faded and pinned at its maximum drift.
  static const double reach = 3.0;

  static double scale(double d) =>
      (1 - 0.13 * d.abs()).clamp(0.62, 1.0).toDouble();

  static double opacity(double d) =>
      (1 - d.abs() / reach).clamp(0.0, 1.0).toDouble();

  /// Sideways drift, quadratic so the rows nearest the focus stay roughly in
  /// column and only the far ones swing wide.
  static double shiftX(double d, {double maxShift = 96}) {
    final t = math.min(1.0, d.abs() / reach);
    return maxShift * t * t;
  }

  /// The row a scroll [offset] has settled on, given a fixed row [itemExtent].
  /// Clamped to the list so an overscroll never reads off the end.
  static int focusedIndex(double offset, double itemExtent, int count) {
    if (count <= 0 || itemExtent <= 0) return 0;
    return (offset / itemExtent).round().clamp(0, count - 1);
  }
}
