import 'dart:math' as math;

/// Pull-the-drawer-to-shuffle: yanking the open drawer down past a threshold
/// shuffles the whole playlist. Pure helpers for the gesture maths and the
/// shuffled play order, kept out of the widget so they're unit-testable.
class ShufflePull {
  const ShufflePull._();

  /// 0..1 progress toward triggering, from how far (px) the drawer's contents
  /// have been pulled down past their rest position.
  static double progress(double pulledPx, {double thresholdPx = 72}) =>
      thresholdPx <= 0 ? 1.0 : (pulledPx / thresholdPx).clamp(0.0, 1.0);

  static bool triggered(double pulledPx, {double thresholdPx = 72}) =>
      progress(pulledPx, thresholdPx: thresholdPx) >= 1.0;

  /// A complete permutation of `0..count-1`, deterministic per [seed]
  /// (Fisher–Yates).
  static List<int> shuffledIndices(int count, {required int seed}) {
    final order = List<int>.generate(count, (i) => i);
    final rnd = math.Random(seed);
    for (var i = count - 1; i > 0; i--) {
      final j = rnd.nextInt(i + 1);
      final tmp = order[i];
      order[i] = order[j];
      order[j] = tmp;
    }
    return order;
  }
}
