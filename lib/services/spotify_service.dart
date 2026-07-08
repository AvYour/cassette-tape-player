import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_sdk/models/player_state.dart';
import '../models/cassette_tape.dart';
import 'spotify_auth.dart';

class SpotifyService extends ChangeNotifier {
  bool _isConnected = false;
  bool _isLoading = false;
  List<CassetteTape> _tapes = CassetteTape.demoTapes;
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
      await _fetchTapes();
      _subscribeToPlayerState();
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

  Future<void> _fetchTapes() async {
    try {
      final token = await SpotifyAuth.getToken();
      if (token == null) return;
      final tracks = await _getRecentlyPlayed(token);
      if (tracks.isNotEmpty) {
        _tapes = tracks;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<List<CassetteTape>> _getRecentlyPlayed(String token) async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/player/recently-played?limit=20'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) return CassetteTape.demoTapes;

    final data = json.decode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return items.asMap().entries.map((e) {
      return CassetteTape.fromSpotifyTrack(
        e.value['track'] as Map<String, dynamic>,
        e.key,
      );
    }).toList();
  }

  /// Start playing a tape. Uses Spotify when connected, otherwise runs the
  /// local demo simulation so the reels spin and the counter advances.
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
