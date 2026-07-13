/// Pure maths for the top-down drawer grid (cassettes filed N per row),
/// extracted so the layout and entrance choreography are unit-testable.
class GridMath {
  const GridMath._();

  static int rowOf(int index, {required int columns}) => index ~/ columns;

  static int colOf(int index, {required int columns}) => index % columns;

  static int rowCount(int itemCount, {required int columns}) =>
      itemCount <= 0 ? 0 : (itemCount + columns - 1) ~/ columns;

  /// Entrance-animation window (start, end) in 0..1 for a grid [row]: each row
  /// settles into the drawer a beat after the one above it. Deep rows are
  /// capped so long playlists don't push the window past the timeline.
  static (double, double) rowStaggerWindow(
    int row, {
    double step = 0.09,
    double span = 0.45,
    int maxStaggered = 6,
  }) {
    final k = row > maxStaggered ? maxStaggered : row;
    final start = (k * step).clamp(0.0, 1.0 - span);
    return (start, start + span);
  }
}
