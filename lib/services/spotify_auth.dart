import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _kToken = 'sp_token';
  static const String _kExpiry = 'sp_token_expiry';

  /// Web API access token (implicit grant). Kept in memory for the session —
  /// used for search and playlist endpoints. Best-effort: may stay null even
  /// when remote playback is connected.
  static String? accessToken;

  static bool get hasWebApi => accessToken != null;

  /// Loads a still-valid token from secure storage so we don't re-prompt for
  /// authorization on every launch. Returns true if a usable token was found.
  static Future<bool> loadStoredToken() async {
    try {
      final token = await _storage.read(key: _kToken);
      final expiry = int.tryParse(await _storage.read(key: _kExpiry) ?? '');
      if (token != null &&
          expiry != null &&
          DateTime.now().millisecondsSinceEpoch < expiry) {
        accessToken = token;
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Fetches a fresh Web API token (shows the Spotify consent screen) and
  /// persists it with an expiry so subsequent launches can reuse it silently.
  static Future<String?> fetchToken() async {
    try {
      accessToken = await SpotifySdk.getAccessToken(
        clientId: clientId,
        redirectUrl: redirectUri,
        scope: _scope,
      );
      // Implicit-grant tokens last ~1h; refresh a little early to be safe.
      final expiry = DateTime.now()
          .add(const Duration(minutes: 55))
          .millisecondsSinceEpoch;
      await _storage.write(key: _kToken, value: accessToken);
      await _storage.write(key: _kExpiry, value: expiry.toString());
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
    try {
      await _storage.delete(key: _kToken);
      await _storage.delete(key: _kExpiry);
    } catch (_) {}
  }
}
