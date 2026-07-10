import 'package:audioplayers/audioplayers.dart';

/// Plays the mechanical cassette sound effects (deck insert/close/eject) and
/// UI button clicks. Fails silently if the assets are missing or audio is
/// unavailable.
class SoundService {
  // Deck sounds on one player; UI clicks on a separate low-latency player so a
  // rapid button press never cuts off the cassette sound (and vice-versa).
  static final AudioPlayer _deck = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  static final AudioPlayer _ui = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop)
    ..setPlayerMode(PlayerMode.lowLatency);

  static Future<void> _play(AudioPlayer player, String asset,
      {double volume = 0.8}) async {
    try {
      await player.stop();
      await player.play(AssetSource(asset), volume: volume);
    } catch (_) {}
  }

  /// Inserting/engaging the tape — played when playback starts or a new tape
  /// begins.
  static void tapeStart() => _play(_deck, 'sounds/tape_insert.mp3');

  /// Closing the deck — played when playback stops / the tape finishes.
  static void tapeStop() => _play(_deck, 'sounds/tape_close.mp3');

  /// Ejecting the tape — played when leaving the player via Eject.
  static void eject() => _play(_deck, 'sounds/tape_eject.mp3');

  /// A tactile button click for the transport controls.
  static void buttonPress() =>
      _play(_ui, 'sounds/button_press.mp3', volume: 0.6);
}
