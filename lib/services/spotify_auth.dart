import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:spotify_sdk/spotify_sdk.dart';

/// Spotify auth using the Authorization Code + PKCE flow, which yields a
/// refresh token — so the Web API token is renewed silently and the user only
/// consents once. (App Remote playback still uses its own redirect.)
class SpotifyAuth {
  static String get clientId => dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';

  /// Redirect used by the App Remote (spotify_sdk) connection.
  static String get remoteRedirect =>
      dotenv.env['SPOTIFY_REDIRECT_URI'] ?? 'cassetteplayer://callback';

  /// Dedicated redirect for the PKCE web-auth flow — a distinct scheme so it
  /// never collides with the App Remote's redirect. Register this exact value
  /// in the Spotify dashboard.
  static const String pkceRedirect = 'cassettepkce://callback';
  static const String _pkceScheme = 'cassettepkce';

  static const String _scope =
      'user-read-playback-state user-modify-playback-state '
      'user-read-currently-playing playlist-read-private '
      'playlist-read-collaborative user-library-read '
      'user-read-recently-played';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _kAccess = 'sp_access';
  static const String _kRefresh = 'sp_refresh';
  static const String _kExpiry = 'sp_expiry';

  static String? accessToken;
  static bool get hasWebApi => accessToken != null;

  static String _randomString(int n) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final r = Random.secure();
    return List.generate(n, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static String _challenge(String verifier) =>
      base64UrlEncode(sha256.convert(utf8.encode(verifier)).bytes)
          .replaceAll('=', '');

  /// Gets a Web API token WITHOUT showing any UI: reuse the stored one or
  /// silently refresh it. Returns false if neither is available.
  static Future<bool> ensureTokenSilent() async {
    final stored = await _storage.read(key: _kAccess);
    final expiry = int.tryParse(await _storage.read(key: _kExpiry) ?? '');
    if (stored != null &&
        expiry != null &&
        DateTime.now().millisecondsSinceEpoch < expiry) {
      accessToken = stored;
      return true;
    }
    final refresh = await _storage.read(key: _kRefresh);
    return refresh != null && await _refresh(refresh);
  }

  /// Prompts the user for consent (PKCE web-auth) to obtain a fresh token and a
  /// refresh token. Call this only from an explicit user action.
  static Future<bool> authorizeInteractive() => _authorize();

  static Future<bool> _authorize() async {
    try {
      final verifier = _randomString(96);
      final url = Uri.https('accounts.spotify.com', '/authorize', {
        'client_id': clientId,
        'response_type': 'code',
        'redirect_uri': pkceRedirect,
        'scope': _scope,
        'code_challenge_method': 'S256',
        'code_challenge': _challenge(verifier),
      }).toString();

      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: _pkceScheme,
      );
      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) return false;

      final res = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': pkceRedirect,
          'client_id': clientId,
          'code_verifier': verifier,
        },
      );
      if (res.statusCode != 200) return false;
      return _store(json.decode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _refresh(String refreshToken) async {
    try {
      final res = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': clientId,
        },
      );
      if (res.statusCode != 200) return false;
      return _store(json.decode(res.body) as Map<String, dynamic>,
          fallbackRefresh: refreshToken);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _store(Map<String, dynamic> body,
      {String? fallbackRefresh}) async {
    final access = body['access_token'] as String?;
    if (access == null) return false;
    accessToken = access;
    final expiresIn = (body['expires_in'] as int?) ?? 3600;
    final expiry = DateTime.now()
        .add(Duration(seconds: expiresIn - 60))
        .millisecondsSinceEpoch;
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kExpiry, value: expiry.toString());
    final newRefresh = body['refresh_token'] as String? ?? fallbackRefresh;
    if (newRefresh != null) {
      await _storage.write(key: _kRefresh, value: newRefresh);
    }
    return true;
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
      await _storage.delete(key: _kAccess);
      await _storage.delete(key: _kRefresh);
      await _storage.delete(key: _kExpiry);
    } catch (_) {}
  }
}
