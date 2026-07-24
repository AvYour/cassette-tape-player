import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

/// Spotify auth via the Spotify Android SDK's implicit-grant `getAccessToken`
/// (custom scheme works because it's the SDK's native flow, not a browser).
/// There's no refresh token, so the Web API token is cached for its lifetime
/// and re-fetched (usually silently) when it expires.
class SpotifyAuth {
  static String get clientId => dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  static String get remoteRedirect =>
      dotenv.env['SPOTIFY_REDIRECT_URI'] ?? 'cassetteplayer://callback';

  static const String _scope =
      'user-read-playback-state user-modify-playback-state '
      'user-read-currently-playing playlist-read-private '
      'playlist-read-collaborative user-library-read '
      'user-library-modify user-top-read '
      'user-read-recently-played';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _kToken = 'sp_token';
  static const String _kExpiry = 'sp_token_expiry';
  static const String _kScope = 'sp_token_scope';

  static String? accessToken;
  static bool get hasWebApi => accessToken != null;

  /// Reuses a still-valid stored token without any UI. Returns false if none —
  /// including when the app now asks for more scopes than the cached token was
  /// granted, which forces a fresh interactive authorization so new features
  /// (top tracks, saving songs) aren't silently denied until the token expires.
  static Future<bool> ensureTokenSilent() async {
    try {
      final token = await _storage.read(key: _kToken);
      final expiry = int.tryParse(await _storage.read(key: _kExpiry) ?? '');
      final scope = await _storage.read(key: _kScope);
      if (token != null &&
          expiry != null &&
          scope == _scope &&
          DateTime.now().millisecondsSinceEpoch < expiry) {
        accessToken = token;
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Fetches a fresh Web API token via the Spotify SDK. After the first
  /// authorization this is typically silent (no login screen). Persists it with
  /// a ~1h expiry so we can reuse it until then.
  static Future<bool> authorizeInteractive() async {
    try {
      accessToken = await SpotifySdk.getAccessToken(
        clientId: clientId,
        redirectUrl: remoteRedirect,
        scope: _scope,
      );
      final expiry = DateTime.now()
          .add(const Duration(minutes: 55))
          .millisecondsSinceEpoch;
      await _storage.write(key: _kToken, value: accessToken);
      await _storage.write(key: _kExpiry, value: expiry.toString());
      await _storage.write(key: _kScope, value: _scope);
      return accessToken != null;
    } catch (_) {
      accessToken = null;
      return false;
    }
  }

  /// Connects to the Spotify app for remote playback control.
  static Future<bool> connectRemote() async {
    try {
      await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: remoteRedirect,
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
      await _storage.delete(key: _kScope);
    } catch (_) {}
  }
}
