import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/utils/grid_math.dart';

void main() {
  group('GridMath rows/cols', () {
    test('maps an index to its row and column (5 per row)', () {
      expect(GridMath.rowOf(0, columns: 5), 0);
      expect(GridMath.rowOf(4, columns: 5), 0);
      expect(GridMath.rowOf(5, columns: 5), 1);
      expect(GridMath.rowOf(12, columns: 5), 2);
      expect(GridMath.colOf(0, columns: 5), 0);
      expect(GridMath.colOf(4, columns: 5), 4);
      expect(GridMath.colOf(12, columns: 5), 2);
    });

    test('counts the rows needed for n items', () {
      expect(GridMath.rowCount(0, columns: 5), 0);
      expect(GridMath.rowCount(1, columns: 5), 1);
      expect(GridMath.rowCount(5, columns: 5), 1);
      expect(GridMath.rowCount(6, columns: 5), 2);
      expect(GridMath.rowCount(72, columns: 5), 15);
    });
  });

  group('GridMath.rowStaggerWindow', () {
    test('each row enters a beat after the previous', () {
      expect(GridMath.rowStaggerWindow(0), (0.0, 0.45));
      final (s1, e1) = GridMath.rowStaggerWindow(1);
      expect(s1, closeTo(0.09, 1e-9));
      expect(e1, closeTo(0.54, 1e-9));
    });

    test('windows stay inside 0..1 and keep their span for any row', () {
      for (final r in [0, 3, 6, 40]) {
        final (s, e) = GridMath.rowStaggerWindow(r);
        expect(s, inInclusiveRange(0.0, 1.0), reason: 'row=$r');
        expect(e, inInclusiveRange(0.0, 1.0), reason: 'row=$r');
        expect(e - s, closeTo(0.45, 1e-9), reason: 'row=$r');
      }
    });

    test('deep rows are capped so they never wait past the timeline', () {
      expect(GridMath.rowStaggerWindow(100), GridMath.rowStaggerWindow(6));
    });
  });
}
