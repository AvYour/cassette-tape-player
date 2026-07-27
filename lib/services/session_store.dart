import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/cassette_tape.dart';

/// What was playing when the app was last closed.
class StoredSession {
  final List<CassetteTape> queue;
  final int index;
  final String? contextUri;

  const StoredSession({
    required this.queue,
    required this.index,
    this.contextUri,
  });
}

/// The small amount of state worth surviving a restart: the recent searches
/// and the tape that was loaded. Everything else — playlists, tracks, lyrics —
/// is refetched, because a stale copy is worse than a fresh request.
class SessionStore {
  const SessionStore._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _kSearches = 'recent_searches';
  static const String _kNowPlaying = 'now_playing';

  /// A long queue is trimmed: restoring the mini-player does not need the
  /// hundredth track, and the store is not a database.
  static const int _maxQueue = 60;

  static Future<void> saveSearches(List<String> searches) async {
    try {
      await _storage.write(key: _kSearches, value: json.encode(searches));
    } catch (_) {}
  }

  static Future<List<String>> loadSearches() async {
    try {
      final raw = await _storage.read(key: _kSearches);
      if (raw == null) return const [];
      final list = json.decode(raw);
      return [
        for (final s in list is List ? list : const [])
          if (s is String && s.isNotEmpty) s,
      ];
    } catch (_) {
      return const [];
    }
  }

  static Future<void> saveNowPlaying(
      List<CassetteTape> queue, int index, String? contextUri) async {
    try {
      // Keep the window around the current track rather than the first N, so a
      // trim never throws away what is actually playing.
      var from = 0;
      var at = index;
      if (queue.length > _maxQueue) {
        from = (index - 5).clamp(0, queue.length - _maxQueue);
        at = index - from;
      }
      final window = queue.skip(from).take(_maxQueue).toList();
      await _storage.write(
        key: _kNowPlaying,
        value: json.encode({
          'index': at,
          'contextUri': contextUri,
          'queue': [for (final t in window) t.toStoredJson()],
        }),
      );
    } catch (_) {}
  }

  static Future<StoredSession?> loadNowPlaying() async {
    try {
      final raw = await _storage.read(key: _kNowPlaying);
      if (raw == null) return null;
      final map = json.decode(raw);
      if (map is! Map) return null;
      final rawQueue = map['queue'];
      if (rawQueue is! List || rawQueue.isEmpty) return null;
      final queue = [
        for (final t in rawQueue)
          if (t is Map<String, dynamic>) CassetteTape.fromStoredJson(t),
      ];
      if (queue.isEmpty) return null;
      final index = map['index'];
      return StoredSession(
        queue: queue,
        index: index is int && index >= 0 && index < queue.length ? index : 0,
        contextUri: map['contextUri'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearNowPlaying() async {
    try {
      await _storage.delete(key: _kNowPlaying);
    } catch (_) {}
  }
}
