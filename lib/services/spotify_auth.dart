import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

/// Spotify auth using the Authorization Code + PKCE flow, which yields a
/// refresh token — so the Web API token is renewed silently and the user only
/// consents once. (App Remote playback still uses its own redirect.)
class SpotifyAuth {
  static String get clientId => dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';

  /// Redirect used by the App Remote (spotify_sdk) connection.
  static String get remoteRedirect =>
      dotenv.env['SPOTIFY_REDIRECT_URI'] ?? 'cassetteplayer://callback';

  // Spotify (April 2025) no longer accepts custom-scheme redirects for browser
  // auth — only HTTPS or loopback. We use a fixed-port loopback and catch the
  // code with a tiny local server. Register this EXACT value in the dashboard.
  static const int _loopbackPort = 8888;
  static String get pkceRedirect => 'http://127.0.0.1:$_loopbackPort/callback';

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
    HttpServer? server;
    try {
      final verifier = _randomString(96);
      // Local loopback server to catch the redirect with the auth code.
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, _loopbackPort);

      final url = Uri.https('accounts.spotify.com', '/authorize', {
        'client_id': clientId,
        'response_type': 'code',
        'redirect_uri': pkceRedirect,
        'scope': _scope,
        'code_challenge_method': 'S256',
        'code_challenge': _challenge(verifier),
      });
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await server.close(force: true);
        return false;
      }

      final request = await server.first.timeout(const Duration(minutes: 3));
      final code = request.uri.queryParameters['code'];
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write('<!doctype html><html><head><meta name="viewport" '
            'content="width=device-width,initial-scale=1"></head>'
            '<body style="font-family:sans-serif;text-align:center;padding-top:60px;background:#1c1712;color:#f4efe6">'
            '<h2>Connected 🎧</h2><p>You can return to the Cassette Player.</p>'
            '</body></html>');
      await request.response.close();
      await server.close(force: true);
      server = null;

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
      try {
        await server?.close(force: true);
      } catch (_) {}
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
