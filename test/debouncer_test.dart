import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('fires only the last call after the quiet period', () {
      fakeAsync((async) {
        final d = Debouncer(const Duration(milliseconds: 300));
        final fired = <int>[];
        d.run(() => fired.add(1));
        async.elapse(const Duration(milliseconds: 100));
        d.run(() => fired.add(2));
        async.elapse(const Duration(milliseconds: 100));
        d.run(() => fired.add(3));
        expect(fired, isEmpty, reason: 'nothing fires while calls keep coming');
        async.elapse(const Duration(milliseconds: 300));
        expect(fired, [3], reason: 'only the newest call survives');
        d.dispose();
      });
    });

    test('separate quiet periods each fire once', () {
      fakeAsync((async) {
        final d = Debouncer(const Duration(milliseconds: 200));
        final fired = <int>[];
        d.run(() => fired.add(1));
        async.elapse(const Duration(milliseconds: 250));
        d.run(() => fired.add(2));
        async.elapse(const Duration(milliseconds: 250));
        expect(fired, [1, 2]);
        d.dispose();
      });
    });

    test('dispose cancels whatever is pending', () {
      fakeAsync((async) {
        final d = Debouncer(const Duration(milliseconds: 200));
        var fired = false;
        d.run(() => fired = true);
        d.dispose();
        async.elapse(const Duration(seconds: 5));
        expect(fired, isFalse);
      });
    });
  });
}
