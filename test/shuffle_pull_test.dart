import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/utils/shuffle_pull.dart';

void main() {
  group('ShufflePull.progress', () {
    test('maps pull distance to 0..1 against the threshold', () {
      expect(ShufflePull.progress(0), 0.0);
      expect(ShufflePull.progress(36, thresholdPx: 72), 0.5);
      expect(ShufflePull.progress(72, thresholdPx: 72), 1.0);
      expect(ShufflePull.progress(500, thresholdPx: 72), 1.0);
      expect(ShufflePull.progress(-20, thresholdPx: 72), 0.0);
    });

    test('triggers exactly at the threshold', () {
      expect(ShufflePull.triggered(71.9, thresholdPx: 72), isFalse);
      expect(ShufflePull.triggered(72, thresholdPx: 72), isTrue);
    });
  });

  group('ShufflePull.shuffledIndices', () {
    test('is a complete permutation of 0..n-1', () {
      final order = ShufflePull.shuffledIndices(50, seed: 9);
      expect(order.length, 50);
      expect(List.of(order)..sort(), List.generate(50, (i) => i));
    });

    test('is deterministic for the same seed', () {
      expect(ShufflePull.shuffledIndices(30, seed: 4),
          ShufflePull.shuffledIndices(30, seed: 4));
    });

    test('different seeds give different orders', () {
      expect(
        ShufflePull.shuffledIndices(50, seed: 1),
        isNot(ShufflePull.shuffledIndices(50, seed: 2)),
      );
    });

    test('handles empty and single-item lists', () {
      expect(ShufflePull.shuffledIndices(0, seed: 1), isEmpty);
      expect(ShufflePull.shuffledIndices(1, seed: 1), [0]);
    });
  });
}
