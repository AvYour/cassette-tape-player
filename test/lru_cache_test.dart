import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/utils/lru_cache.dart';

void main() {
  group('LruCache', () {
    test('put then get returns the stored value', () {
      final c = LruCache<int>(capacity: 3);
      c.put('a', 1);
      expect(c.get('a'), 1);
      expect(c.length, 1);
    });

    test('contains distinguishes a cached null from an absent key', () {
      // Negative caching: we store null ("looked up, found nothing").
      final c = LruCache<int?>(capacity: 3);
      c.put('missing', null);
      expect(c.containsKey('missing'), isTrue);
      expect(c.get('missing'), isNull);
      expect(c.containsKey('never'), isFalse);
    });

    test('evicts the least-recently-used entry past capacity', () {
      final c = LruCache<int>(capacity: 2);
      c.put('a', 1);
      c.put('b', 2);
      c.put('c', 3); // 'a' is the oldest → evicted
      expect(c.containsKey('a'), isFalse);
      expect(c.containsKey('b'), isTrue);
      expect(c.containsKey('c'), isTrue);
      expect(c.length, 2);
    });

    test('get refreshes recency so a used entry survives eviction', () {
      final c = LruCache<int>(capacity: 2);
      c.put('a', 1);
      c.put('b', 2);
      c.get('a'); // 'a' is now most-recently-used
      c.put('c', 3); // 'b' is now oldest → evicted
      expect(c.containsKey('a'), isTrue);
      expect(c.containsKey('b'), isFalse);
      expect(c.containsKey('c'), isTrue);
    });

    test('re-putting an existing key updates value and recency', () {
      final c = LruCache<int>(capacity: 2);
      c.put('a', 1);
      c.put('b', 2);
      c.put('a', 11); // update + refresh
      c.put('c', 3); // 'b' oldest → evicted
      expect(c.get('a'), 11);
      expect(c.containsKey('b'), isFalse);
      expect(c.length, 2);
    });

    test('capacity below 1 is coerced to 1', () {
      final c = LruCache<int>(capacity: 0);
      c.put('a', 1);
      c.put('b', 2);
      expect(c.length, 1);
      expect(c.containsKey('b'), isTrue);
    });
  });
}
