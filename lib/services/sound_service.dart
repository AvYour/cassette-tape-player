import 'package:audioplayers/audioplayers.dart';

/// Plays the short mechanical cassette sound effects (deck engaging/stopping).
/// Fails silently if the assets are missing or audio is unavailable.
class SoundService {
  static final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  static Future<void> _play(String asset) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(asset), volume: 0.7);
    } catch (_) {}
  }

  /// The "ka-chunk" + motor spin-up when playback starts.
  static void tapeStart() => _play('sounds/tape_start.wav');

  /// The firm "clunk" when the deck stops / the tape finishes.
  static void tapeStop() => _play('sounds/tape_stop.wav');
}
