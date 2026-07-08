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

  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  List<CassetteTape> get tapes => _tapes;
  PlayerState? get playerState => _playerState;

  bool get isPlaying =>
      _playerState != null && !(_playerState!.isPaused);

  double get trackProgress {
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

  Future<void> play(String spotifyUri) async {
    await SpotifySdk.play(spotifyUri: spotifyUri);
  }

  Future<void> pause() async {
    await SpotifySdk.pause();
  }

  Future<void> resume() async {
    await SpotifySdk.resume();
  }

  Future<void> skipNext() async {
    await SpotifySdk.skipNext();
  }

  Future<void> skipPrevious() async {
    await SpotifySdk.skipPrevious();
  }

  Future<void> seekTo(int positionMs) async {
    await SpotifySdk.seekTo(positionedMilliseconds: positionMs);
  }

  // spotify_sdk 2.x has no volume API; volume knob adjusts system/app volume
  // only as a UI affordance. Kept as a hook for future SDK support.
  Future<void> setVolume(int volume) async {}
}
