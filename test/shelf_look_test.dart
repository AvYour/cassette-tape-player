import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/utils/shelf_look.dart';

void main() {
  group('ShelfLook.spines', () {
    test('produces exactly the asked-for number of spines', () {
      expect(ShelfLook.spines(seed: 1, count: 0, paletteSize: 5), isEmpty);
      expect(ShelfLook.spines(seed: 1, count: 8, paletteSize: 5).length, 8);
    });

    test('is deterministic per seed — a shelf never reshuffles itself', () {
      final a = ShelfLook.spines(seed: 42, count: 10, paletteSize: 5);
      final b = ShelfLook.spines(seed: 42, count: 10, paletteSize: 5);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].paletteIndex, b[i].paletteIndex);
        expect(a[i].heightFactor, b[i].heightFactor);
        expect(a[i].leansLeft, b[i].leansLeft);
      }
    });

    test('different seeds shelve different-looking tapes', () {
      final a = ShelfLook.spines(seed: 1, count: 12, paletteSize: 5);
      final b = ShelfLook.spines(seed: 2, count: 12, paletteSize: 5);
      final identical = List.generate(
              a.length, (i) => a[i].paletteIndex == b[i].paletteIndex)
          .every((same) => same);
      expect(identical, isFalse);
    });

    test('keeps every spine within realistic bounds', () {
      for (final s in ShelfLook.spines(seed: 3, count: 40, paletteSize: 5)) {
        expect(s.paletteIndex, inInclusiveRange(0, 4));
        expect(s.heightFactor, inInclusiveRange(0.82, 1.0));
      }
    });
  });

  group('ShelfLook.visibleCount', () {
    test('fills the slots available, never more than the tracks', () {
      expect(ShelfLook.visibleCount(trackCount: 100, slots: 12), 12);
      expect(ShelfLook.visibleCount(trackCount: 5, slots: 12), 5);
      expect(ShelfLook.visibleCount(trackCount: 0, slots: 12), 0);
      expect(ShelfLook.visibleCount(trackCount: 10, slots: 0), 0);
    });
  });

  group('ShelfLook.placeholderCount', () {
    test('dresses an unknown-size shelf with a plausible number of tapes', () {
      for (final seed in [1, 7, 99]) {
        final n = ShelfLook.placeholderCount(seed: seed, slots: 20);
        expect(n, inInclusiveRange(5, 20), reason: 'seed=$seed');
      }
    });

    test('is deterministic per seed and fits small shelves', () {
      expect(ShelfLook.placeholderCount(seed: 3, slots: 20),
          ShelfLook.placeholderCount(seed: 3, slots: 20));
      expect(ShelfLook.placeholderCount(seed: 3, slots: 4),
          inInclusiveRange(1, 4));
      expect(ShelfLook.placeholderCount(seed: 3, slots: 0), 0);
    });
  });
}
