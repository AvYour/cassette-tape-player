import 'package:audioplayers/audioplayers.dart';

/// Plays the mechanical cassette sound effects (deck insert/close/eject).
/// Fails silently if the assets are missing or audio is unavailable.
class SoundService {
  static final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  static Future<void> _play(String asset) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(asset), volume: 0.8);
    } catch (_) {}
  }

  /// Inserting/engaging the tape — played when playback starts or a new tape
  /// begins.
  static void tapeStart() => _play('sounds/tape_insert.mp3');

  /// Closing the deck — played when playback stops / the tape finishes.
  static void tapeStop() => _play('sounds/tape_close.mp3');

  /// Ejecting the tape — played when leaving the player via Eject.
  static void eject() => _play('sounds/tape_eject.mp3');
}
