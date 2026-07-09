import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class SpotifyAuth {
  static String get clientId => dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  static String get redirectUri =>
      dotenv.env['SPOTIFY_REDIRECT_URI'] ?? 'cassetteplayer://callback';

  /// Connects to the Spotify app for remote playback control. This is all we
  /// need to play/pause/skip — the audio is produced by the Spotify app.
  static Future<bool> connect() async {
    try {
      await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUri,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> disconnect() async {
    await SpotifySdk.disconnect();
  }
}
