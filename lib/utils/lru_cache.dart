import 'dart:collection';

/// A tiny least-recently-used cache. Keeps at most [capacity] entries; when
/// full, inserting a new key evicts the least-recently-used one. Reading or
/// re-writing a key marks it most-recently-used.
///
/// Supports "negative caching": storing a null value records that a key was
/// looked up and found nothing, so it isn't fetched again. Use [containsKey]
/// (not a null [get]) to tell a cached-null from an absent key.
class LruCache<T> {
  final int capacity;
  // LinkedHashMap keeps insertion/refresh order, so the first key is the LRU.
  final LinkedHashMap<String, T> _entries = LinkedHashMap<String, T>();

  LruCache({required int capacity}) : capacity = capacity < 1 ? 1 : capacity;

  int get length => _entries.length;

  bool containsKey(String key) => _entries.containsKey(key);

  /// Returns the value for [key] (or null if absent) and marks it as recently
  /// used. Because null is also a valid stored value, pair this with
  /// [containsKey] when you need to distinguish a miss from a cached null.
  T? get(String key) {
    if (!_entries.containsKey(key)) return null;
    final value = _entries.remove(key) as T;
    _entries[key] = value; // re-insert at the end (most recent)
    return value;
  }

  void put(String key, T value) {
    _entries.remove(key); // drop any old position so re-put refreshes recency
    _entries[key] = value;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first); // evict least-recently-used
    }
  }

  void clear() => _entries.clear();
}
