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
  /// used for search and playlist endpoints. Best-effort: may stay null even
  /// when remote playback is connected.
  static String? accessToken;

  static bool get hasWebApi => accessToken != null;

  /// Best-effort Web API token for search/playlists. Runs first so it can
  /// reuse the auth session for the remote connect that follows.
  static Future<String?> fetchToken() async {
    try {
      accessToken = await SpotifySdk.getAccessToken(
        clientId: clientId,
        redirectUrl: redirectUri,
        scope: _scope,
      );
    } catch (_) {
      accessToken = null;
    }
    return accessToken;
  }

  /// Connects to the Spotify app for remote playback control. This is the gate
  /// for playback; the Web API token is a bonus fetched separately.
  static Future<bool> connectRemote() async {
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
    accessToken = null;
  }
}
