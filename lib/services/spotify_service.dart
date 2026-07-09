import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_sdk/models/player_state.dart';
import '../models/cassette_tape.dart';
import '../models/playlist.dart';
import 'spotify_auth.dart';

class SpotifyService extends ChangeNotifier {
  bool _isConnected = false;
  bool _isLoading = false;
  final List<CassetteTape> _tapes = CassetteTape.demoTapes;
  List<Playlist> _playlists = [];
  PlayerState? _playerState;

  // --- Demo playback simulation (used when not connected to Spotify) ---
  Timer? _demoTimer;
  CassetteTape? _demoTape;
  double _demoProgress = 0.0;
  bool _demoPlaying = false;
  static const Duration _demoTick = Duration(milliseconds: 200);

  String? _statusMessage;
  String? _searchError;

  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  List<CassetteTape> get tapes => _tapes;
  List<Playlist> get playlists => _playlists;
  PlayerState? get playerState => _playerState;
  bool get isDemoMode => !_isConnected;
  bool get hasWebApi => SpotifyAuth.hasWebApi;

  /// A short human-readable note about the last connect result, e.g. why
  /// playlists/search are unavailable. Null when everything is fine.
  String? get statusMessage => _statusMessage;

  /// Last search error (e.g. the message Spotify returned on a non-200).
  String? get searchError => _searchError;

  /// Extracts Spotify's `error.message` from a JSON error body, if present.
  String _apiError(int status, String body) {
    try {
      final msg = json.decode(body)['error']?['message'];
      if (msg is String && msg.isNotEmpty) return 'HTTP $status: $msg';
    } catch (_) {}
    return 'HTTP $status';
  }

  bool get isPlaying {
    if (!_isConnected) return _demoPlaying;
    return _playerState != null && !(_playerState!.isPaused);
  }

  double get trackProgress {
    if (!_isConnected) return _demoProgress.clamp(0.0, 1.0);
    final state = _playerState;
    if (state == null || state.track == null) return 0.0;
    final duration = state.track!.duration;
    if (duration == 0) return 0.0;
    return (state.playbackPosition / duration).clamp(0.0, 1.0);
  }

  Future<void> connectToSpotify() async {
    _isLoading = true;
    _statusMessage = null;
    notifyListeners();

    // Fetch the Web API token first (best-effort) so it can share the auth
    // session with the remote connect, then connect for playback.
    await SpotifyAuth.fetchToken();
    _isConnected = await SpotifyAuth.connectRemote();

    if (_isConnected) {
      _subscribeToPlayerState();
      if (SpotifyAuth.hasWebApi) {
        await fetchPlaylists();
        if (_playlists.isEmpty) {
          _statusMessage = 'Connected, but no playlists found on your account.';
        }
      } else {
        _statusMessage =
            'Playback connected, but Spotify Web API token was not granted — '
            'search and playlists are unavailable.';
      }
    } else {
      _statusMessage =
          'Could not connect to Spotify. Open the Spotify app, log in, and try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void _subscribeToPlayerState() {
    SpotifySdk.subscribePlayerState().listen((state) {
      _playerState = state;
      notifyListeners();
    });
  }

  // --- Spotify Web API -----------------------------------------------------

  Map<String, String> get _authHeader =>
      {'Authorization': 'Bearer ${SpotifyAuth.accessToken}'};

  /// The current user's Spotify id, used to keep only playlists they created.
  Future<String?> _fetchUserId() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.spotify.com/v1/me'),
        headers: _authHeader,
      );
      if (res.statusCode != 200) return null;
      return json.decode(res.body)['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Loads the user's OWN playlists into drawers (metadata only; tracks load
  /// lazily). Playlists owned by others are hidden since Spotify no longer
  /// returns their items.
  Future<void> fetchPlaylists() async {
    final token = SpotifyAuth.accessToken;
    if (token == null) return;
    try {
      final userId = await _fetchUserId();
      final res = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/playlists?limit=50'),
        headers: _authHeader,
      );
      if (res.statusCode != 200) return;
      final items = (json.decode(res.body)['items'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final all = items
          .asMap()
          .entries
          .map((e) => Playlist.fromJson(e.value, e.key))
          .toList();
      // Keep only playlists the user created (owns), when we know the id.
      _playlists = userId == null
          ? all
          : all.where((p) => p.ownerId == userId).toList();
      notifyListeners();
    } catch (_) {}
  }

  /// Loads the tracks of a playlist as cassettes, caching them on the model.
  /// A previously failed/empty load is retried when the drawer is reopened.
  Future<void> loadPlaylistTracks(Playlist playlist) async {
    if (playlist.loading) return;
    if (playlist.tapes != null && playlist.tapes!.isNotEmpty) return;
    final token = SpotifyAuth.accessToken;
    if (token == null) {
      playlist.tapes = [];
      playlist.loadError = 'No Web API token';
      notifyListeners();
      return;
    }
    playlist.loading = true;
    playlist.loadError = null;
    notifyListeners();
    try {
      // Feb 2026 API: /tracks was renamed to /items. Page through all tracks
      // (up to a sane cap) so the whole playlist is shown, not just the first.
      final tapes = <CassetteTape>[];
      const pageSize = 50;
      const maxTracks = 300;
      int offset = 0;
      String? error;
      while (offset < maxTracks) {
        final res = await http.get(
          Uri.parse('https://api.spotify.com/v1/playlists/${playlist.id}/items'
              '?limit=$pageSize&offset=$offset'),
          headers: _authHeader,
        );
        if (res.statusCode != 200) {
          if (offset == 0) error = _apiError(res.statusCode, res.body);
          break;
        }
        final body = json.decode(res.body) as Map<String, dynamic>;
        final items = (body['items'] as List?) ?? [];
        for (final item in items) {
          if (item is! Map) continue;
          // Feb 2026: the track lives under 'item' ('track' is deprecated).
          final raw = item['item'] ?? item['track'];
          if (raw is Map<String, dynamic> &&
              raw['id'] != null &&
              raw['type'] != 'episode') {
            try {
              tapes.add(CassetteTape.fromSpotifyTrack(raw, tapes.length));
            } catch (_) {}
          }
        }
        if (items.length < pageSize || body['next'] == null) break;
        offset += pageSize;
      }
      playlist.tapes = tapes;
      if (tapes.isEmpty) {
        playlist.loadError = error ??
            'No items returned. Spotify only exposes tracks for playlists you '
                'own or collaborate on (Feb 2026 API change).';
      }
    } catch (e) {
      playlist.tapes = [];
      playlist.loadError = 'Error: $e';
    }
    playlist.loading = false;
    notifyListeners();
  }

  /// Searches Spotify's catalogue for tracks matching [query].
  Future<List<CassetteTape>> searchTracks(String query) async {
    _searchError = null;
    final token = SpotifyAuth.accessToken;
    if (token == null || query.trim().isEmpty) return [];
    try {
      // Feb 2026 API: search limit max is now 10 (was 50).
      final res = await http.get(
        Uri.parse(
            'https://api.spotify.com/v1/search?type=track&limit=10&q=${Uri.encodeQueryComponent(query)}'),
        headers: _authHeader,
      );
      if (res.statusCode != 200) {
        _searchError = _apiError(res.statusCode, res.body);
        return [];
      }
      final items = (json.decode(res.body)['tracks']?['items'] as List?) ?? [];
      final tapes = <CassetteTape>[];
      for (final item in items) {
        if (item is Map<String, dynamic> && item['id'] != null) {
          try {
            tapes.add(CassetteTape.fromSpotifyTrack(item, tapes.length));
          } catch (_) {}
        }
      }
      return tapes;
    } catch (e) {
      _searchError = 'Error: $e';
      return [];
    }
  }

  /// Start playing a tape. Plays the real track through Spotify when connected
  /// (and the tape has a URI); otherwise runs the local demo simulation so the
  /// reels still spin and the lyrics still scroll.
  Future<void> playTape(CassetteTape tape) async {
    if (_isConnected && tape.spotifyUri.isNotEmpty) {
      await SpotifySdk.play(spotifyUri: tape.spotifyUri);
    } else {
      _demoTape = tape;
      _demoProgress = 0.0;
      _startDemoTimer();
    }
  }

  Future<void> pause() async {
    if (_isConnected) {
      await SpotifySdk.pause();
    } else {
      _demoTimer?.cancel();
      _demoPlaying = false;
      notifyListeners();
    }
  }

  Future<void> resume() async {
    if (_isConnected) {
      await SpotifySdk.resume();
    } else {
      _startDemoTimer();
    }
  }

  Future<void> skipNext() async {
    if (_isConnected) {
      await SpotifySdk.skipNext();
    } else {
      _demoProgress = 0.0;
      _startDemoTimer();
    }
  }

  Future<void> skipPrevious() async {
    if (_isConnected) {
      await SpotifySdk.skipPrevious();
    } else {
      _demoProgress = 0.0;
      _startDemoTimer();
    }
  }

  /// Fetches the live playback position from Spotify (used to re-sync lyrics
  /// after the app returns from the background).
  Future<int?> fetchPositionMs() async {
    if (!_isConnected) return null;
    try {
      final st = await SpotifySdk.getPlayerState();
      return st?.playbackPosition;
    } catch (_) {
      return null;
    }
  }

  Future<void> seekTo(int positionMs) async {
    if (_isConnected) {
      await SpotifySdk.seekTo(positionedMilliseconds: positionMs);
    } else {
      final tape = _demoTape;
      if (tape != null) {
        _demoProgress = (positionMs / tape.durationMs).clamp(0.0, 1.0);
        notifyListeners();
      }
    }
  }

  void _startDemoTimer() {
    final tape = _demoTape;
    if (tape == null) return;
    _demoTimer?.cancel();
    _demoPlaying = true;
    _demoTimer = Timer.periodic(_demoTick, (t) {
      _demoProgress += _demoTick.inMilliseconds / tape.durationMs;
      if (_demoProgress >= 1.0) {
        _demoProgress = 1.0;
        _demoPlaying = false;
        t.cancel();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  // spotify_sdk 3.x has no volume API; volume knob adjusts system/app volume
  // only as a UI affordance. Kept as a hook for future SDK support.
  Future<void> setVolume(int volume) async {}

  @override
  void dispose() {
    _demoTimer?.cancel();
    super.dispose();
  }
}
