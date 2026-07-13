import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/utils/wood_grain_spec.dart';

void main() {
  group('WoodGrainSpec.generate', () {
    test('is deterministic for the same seed', () {
      final a = WoodGrainSpec.generate(seed: 7, height: 100);
      final b = WoodGrainSpec.generate(seed: 7, height: 100);
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].y, b[i].y);
        expect(a[i].amplitude, b[i].amplitude);
        expect(a[i].alpha, b[i].alpha);
        expect(a[i].strokeWidth, b[i].strokeWidth);
        expect(a[i].isDark, b[i].isDark);
      }
    });

    test('different seeds give different grain', () {
      final a = WoodGrainSpec.generate(seed: 1, height: 100);
      final b = WoodGrainSpec.generate(seed: 2, height: 100);
      final sameYs = a.length == b.length &&
          List.generate(a.length, (i) => a[i].y == b[i].y)
              .every((same) => same);
      expect(sameYs, isFalse);
    });

    test('lines stay inside the panel and advance down it', () {
      final lines = WoodGrainSpec.generate(seed: 3, height: 80);
      expect(lines, isNotEmpty);
      double prev = -1;
      for (final l in lines) {
        expect(l.y, greaterThan(prev));
        expect(l.y, inInclusiveRange(0, 80));
        prev = l.y;
      }
    });

    test('visual parameters stay in a subtle, paintable range', () {
      for (final l in WoodGrainSpec.generate(seed: 4, height: 300)) {
        expect(l.alpha, inInclusiveRange(0.02, 0.2));
        expect(l.strokeWidth, inInclusiveRange(0.5, 1.6));
        expect(l.amplitude, inInclusiveRange(0.4, 3.5));
      }
    });

    test('a taller panel gets more grain lines', () {
      final short = WoodGrainSpec.generate(seed: 5, height: 60);
      final tall = WoodGrainSpec.generate(seed: 5, height: 600);
      expect(tall.length, greaterThan(short.length));
    });
  });
}
