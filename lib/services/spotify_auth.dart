import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class SpotifyAuth {
  static String get clientId => dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  static String get redirectUri =>
      dotenv.env['SPOTIFY_REDIRECT_URI'] ?? 'cassetteplayer://callback';

  static const String _scope =
      'user-read-playback-state user-modify-playback-state '
      'user-read-currently-playing playlist-read-private '
      'playlist-read-collaborative user-library-read '
      'user-read-recently-played';

  /// Web API access token (implicit grant). Kept in memory for the session —
  /// used for search and playlist endpoints. Refreshed on each connect.
  static String? accessToken;

  /// Authenticates for the Web API and connects to the Spotify app for remote
  /// playback control. The token powers search/playlists; the remote
  /// connection drives play/pause on the installed Spotify app.
  static Future<bool> connect() async {
    try {
      accessToken = await SpotifySdk.getAccessToken(
        clientId: clientId,
        redirectUrl: redirectUri,
        scope: _scope,
      );
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
    accessToken = null;
  }
}
