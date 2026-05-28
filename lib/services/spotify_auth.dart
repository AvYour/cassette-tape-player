import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class SpotifyAuth {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'spotify_access_token';

  static String get clientId => dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  static String get redirectUri => dotenv.env['SPOTIFY_REDIRECT_URI'] ?? 'cassetteplayer://callback';

  static const String _scope =
      'user-read-playback-state user-modify-playback-state '
      'user-read-currently-playing playlist-read-private '
      'user-library-read user-read-recently-played';

  static Future<bool> connect() async {
    try {
      final token = await SpotifySdk.getAuthenticationToken(
        clientId: clientId,
        redirectUrl: redirectUri,
        scope: _scope,
      );
      await _storage.write(key: _tokenKey, value: token);

      await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUri,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> disconnect() async {
    await SpotifySdk.disconnect();
    await _storage.delete(key: _tokenKey);
  }

  static Future<bool> isConnected() async {
    try {
      final state = await SpotifySdk.getPlayerState();
      return state != null;
    } catch (_) {
      return false;
    }
  }
}
