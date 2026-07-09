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

  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  List<CassetteTape> get tapes => _tapes;
  List<Playlist> get playlists => _playlists;
  PlayerState? get playerState => _playerState;
  bool get isDemoMode => !_isConnected;

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
    notifyListeners();

    _isConnected = await SpotifyAuth.connect();
    if (_isConnected) {
      _subscribeToPlayerState();
      await fetchPlaylists();
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

  /// Loads the user's playlists into drawers (metadata only; tracks load lazily).
  Future<void> fetchPlaylists() async {
    final token = SpotifyAuth.accessToken;
    if (token == null) return;
    try {
      final res = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/playlists?limit=50'),
        headers: _authHeader,
      );
      if (res.statusCode != 200) return;
      final items = (json.decode(res.body)['items'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      _playlists = items
          .asMap()
          .entries
          .map((e) => Playlist.fromJson(e.value, e.key))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  /// Loads the tracks of a playlist as cassettes, caching them on the model.
  Future<void> loadPlaylistTracks(Playlist playlist) async {
    if (playlist.tapes != null || playlist.loading) return;
    final token = SpotifyAuth.accessToken;
    if (token == null) return;
    playlist.loading = true;
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse(
            'https://api.spotify.com/v1/playlists/${playlist.id}/tracks?limit=50'),
        headers: _authHeader,
      );
      if (res.statusCode == 200) {
        final items = (json.decode(res.body)['items'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        final tapes = <CassetteTape>[];
        for (final item in items) {
          final track = item['track'];
          if (track is Map<String, dynamic> && track['id'] != null) {
            tapes.add(CassetteTape.fromSpotifyTrack(track, tapes.length));
          }
        }
        playlist.tapes = tapes;
      } else {
        playlist.tapes = [];
      }
    } catch (_) {
      playlist.tapes = [];
    }
    playlist.loading = false;
    notifyListeners();
  }

  /// Searches Spotify's catalogue for tracks matching [query].
  Future<List<CassetteTape>> searchTracks(String query) async {
    final token = SpotifyAuth.accessToken;
    if (token == null || query.trim().isEmpty) return [];
    try {
      final res = await http.get(
        Uri.parse(
            'https://api.spotify.com/v1/search?type=track&limit=20&q=${Uri.encodeQueryComponent(query)}'),
        headers: _authHeader,
      );
      if (res.statusCode != 200) return [];
      final items = (json.decode(res.body)['tracks']?['items'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      return items
          .asMap()
          .entries
          .map((e) => CassetteTape.fromSpotifyTrack(e.value, e.key))
          .toList();
    } catch (_) {
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
