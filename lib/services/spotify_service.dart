import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_sdk/models/player_state.dart';
import '../models/browse.dart';
import '../models/cassette_tape.dart';
import '../models/playlist.dart';
import '../models/track_info.dart';
import '../utils/debouncer.dart';
import '../utils/lru_cache.dart';
import '../utils/playlist_paging.dart';
import 'spotify_auth.dart';

class SpotifyService extends ChangeNotifier {
  bool _isConnected = false;
  bool _isLoading = false;
  final List<CassetteTape> _tapes = CassetteTape.demoTapes;
  List<Playlist> _playlists = [];
  PlayerState? _playerState;

  // Single live subscription to Spotify's player state. Kept so we can cancel
  // it before re-subscribing (otherwise every reconnect stacks another stream,
  // multiplying notifyListeners() and rebuilds — a major source of jank).
  StreamSubscription<PlayerState>? _playerSub;
  // Last values we notified on, so a stream event only triggers a rebuild when
  // something the UI cares about (track or play/pause) actually changed — not
  // on every position tick Spotify emits.
  String? _lastNotifiedUri;
  bool? _lastNotifiedPaused;

  // --- Demo playback simulation (used when not connected to Spotify) ---
  Timer? _demoTimer;
  CassetteTape? _demoTape;
  double _demoProgress = 0.0;
  bool _demoPlaying = false;
  static const Duration _demoTick = Duration(milliseconds: 200);

  String? _statusMessage;
  String? _searchError;

  // The tape currently loaded for playback, plus its queue, so a mini-player
  // bar can persist after the full player screen is dismissed with Back.
  CassetteTape? _nowPlaying;
  List<CassetteTape> _nowQueue = const [];
  int _nowIndex = 0;
  String? _nowContextUri;

  CassetteTape? get nowPlaying => _nowPlaying;
  List<CassetteTape> get nowQueue => _nowQueue;
  int get nowIndex => _nowIndex;
  String? get nowContextUri => _nowContextUri;

  void setNowPlaying(List<CassetteTape> queue, int index,
      {String? contextUri}) {
    _nowQueue = queue;
    _nowIndex = index;
    _nowContextUri = contextUri;
    _nowPlaying = (index >= 0 && index < queue.length) ? queue[index] : null;
    notifyListeners();
  }

  /// Clears the mini-player (used when the tape is ejected/stopped for good).
  void clearNowPlaying() {
    _nowPlaying = null;
    _nowQueue = const [];
    notifyListeners();
  }

  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  List<CassetteTape> get tapes => _tapes;
  List<Playlist> get playlists => _playlists;
  PlayerState? get playerState => _playerState;
  bool get isDemoMode => !_isConnected;
  bool get hasWebApi => SpotifyAuth.hasWebApi;

  /// A short human-readable note about the last connect result, e.g. why
  /// playlists/search are unavailable. Null when everything is fine.
  String? get statusMessage => _statusMessage;

  /// Last search error (e.g. the message Spotify returned on a non-200).
  String? get searchError => _searchError;

  /// Extracts Spotify's `error.message` from a JSON error body, if present.
  String _apiError(int status, String body) {
    try {
      final msg = json.decode(body)['error']?['message'];
      if (msg is String && msg.isNotEmpty) return 'HTTP $status: $msg';
    } catch (_) {}
    return 'HTTP $status';
  }

  bool get isPlaying {
    if (!_isConnected) return _demoPlaying;
    return _playerState != null && !(_playerState!.isPaused);
  }

  double get trackProgress {
    if (!_isConnected) return _demoProgress.clamp(0.0, 1.0);
    final state = _playerState;
    if (state == null || state.track == null) return 0.0;
    final duration = state.track!.duration;
    if (duration == 0) return 0.0;
    return (state.playbackPosition / duration).clamp(0.0, 1.0);
  }

  /// Connects for playback and obtains a Web API token. Playback is connected
  /// FIRST so it never depends on the Web API auth.
  Future<void> connectToSpotify() async {
    _isLoading = true;
    _statusMessage = null;
    notifyListeners();

    // 1. App Remote for playback — the important part, independent of Web API.
    _isConnected = await SpotifyAuth.connectRemote();
    if (_isConnected) _subscribeToPlayerState();

    // 2. Web API token: reuse the cached one, else fetch a fresh one via the
    // SDK (usually silent after the first authorization). Renews on every
    // connect, so an expired token is replaced automatically.
    var hasToken = await SpotifyAuth.ensureTokenSilent();
    if (!hasToken) hasToken = await SpotifyAuth.authorizeInteractive();

    if (_isConnected && hasToken) {
      await fetchPlaylists();
      if (_playlists.isEmpty) {
        _statusMessage = 'Connected, but no playlists found on your account.';
      }
    } else if (_isConnected && !hasToken) {
      _statusMessage =
          'Playback connected. Tap the green link to sign in for your '
          'playlists and search.';
    } else {
      _statusMessage =
          'Could not connect to Spotify. Open the Spotify app, log in, and try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void _subscribeToPlayerState() {
    // Drop any previous subscription so reconnects don't stack streams.
    _playerSub?.cancel();
    _lastNotifiedUri = null;
    _lastNotifiedPaused = null;
    _playerSub = SpotifySdk.subscribePlayerState().listen((state) {
      _playerState = state;
      // Only rebuild listeners when the track or the play/pause state changes;
      // Spotify emits frequent position updates we don't need to react to.
      final uri = state.track?.uri;
      final paused = state.isPaused;
      if (uri != _lastNotifiedUri || paused != _lastNotifiedPaused) {
        _lastNotifiedUri = uri;
        _lastNotifiedPaused = paused;
        notifyListeners();
      }
    });
  }

  // --- Spotify Web API -----------------------------------------------------

  Map<String, String> get _authHeader =>
      {'Authorization': 'Bearer ${SpotifyAuth.accessToken}'};

  /// GET a Web API endpoint; if the token has expired (401), fetch a fresh one
  /// and retry once. This is how the token is renewed mid-session.
  Future<http.Response> _authedGet(Uri uri) async {
    var res = await http.get(uri, headers: _authHeader);
    if (res.statusCode == 401 && await SpotifyAuth.authorizeInteractive()) {
      res = await http.get(uri, headers: _authHeader);
    }
    return res;
  }

  /// PUT with the same expired-token retry as [_authedGet].
  Future<http.Response> _authedPut(Uri uri) async {
    var res = await http.put(uri, headers: _authHeader);
    if (res.statusCode == 401 && await SpotifyAuth.authorizeInteractive()) {
      res = await http.put(uri, headers: _authHeader);
    }
    return res;
  }

  /// The current user's Spotify id, used to keep only playlists they created.
  Future<String?> _fetchUserId() async {
    try {
      final res = await _authedGet(Uri.parse('https://api.spotify.com/v1/me'));
      if (res.statusCode != 200) return null;
      return json.decode(res.body)['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Loads the user's OWN playlists into drawers (metadata only; tracks load
  /// lazily). Playlists owned by others are hidden since Spotify no longer
  /// returns their items.
  Future<void> fetchPlaylists() async {
    final token = SpotifyAuth.accessToken;
    if (token == null) return;
    try {
      final userId = await _fetchUserId();
      final res = await _authedGet(
          Uri.parse('https://api.spotify.com/v1/me/playlists?limit=50'));
      if (res.statusCode != 200) return;
      final items = (json.decode(res.body)['items'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final all = items
          .asMap()
          .entries
          .map((e) => Playlist.fromJson(e.value, e.key))
          .toList();
      // Keep only playlists the user created (owns), when we know the id.
      final owned =
          userId == null ? all : all.where((p) => p.ownerId == userId).toList();
      // Your library, top songs and history lead: three shelves every account
      // has, none of them a playlist, so /me/playlists never mentions them.
      _playlists = [
        Playlist.liked(total: await _fetchLikedTotal()),
        Playlist.topTracks(_topRange),
        Playlist.recentlyPlayed(),
        ...owned,
      ];
      notifyListeners();
    } catch (_) {}
  }

  // Which window "Your Top Songs" is showing. Changing it swaps the row for a
  // fresh one (new id → new cache) and rebuilds Explore.
  TopRange _topRange = TopRange.mediumTerm;
  TopRange get topRange => _topRange;
  set topRange(TopRange range) {
    if (range == _topRange) return;
    _topRange = range;
    final i = _playlists.indexWhere((p) => p.kind == PlaylistKind.top);
    if (i != -1) _playlists[i] = Playlist.topTracks(range);
    notifyListeners();
  }

  /// How many songs are saved, read off a one-item page's `total`. Only feeds
  /// the row's subtitle, so a failure just means no count is shown.
  Future<int> _fetchLikedTotal() async {
    try {
      final res = await _authedGet(
          Uri.parse('https://api.spotify.com/v1/me/tracks?limit=1'));
      if (res.statusCode != 200) return 0;
      return (json.decode(res.body)['total'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Loads the tracks of a playlist as cassettes, caching them on the model.
  /// A previously failed/empty load is retried when the drawer is reopened.
  Future<void> loadPlaylistTracks(Playlist playlist) async {
    if (playlist.loading) return;
    if (playlist.tapes != null && playlist.tapes!.isNotEmpty) return;
    final token = SpotifyAuth.accessToken;
    if (token == null) {
      playlist.tapes = [];
      playlist.loadError = 'No Web API token';
      notifyListeners();
      return;
    }
    playlist.loading = true;
    playlist.loadError = null;
    notifyListeners();
    try {
      switch (playlist.kind) {
        case PlaylistKind.liked:
          await _loadSavedTracks(playlist);
        case PlaylistKind.recent:
          await _loadRecentlyPlayed(playlist);
        case PlaylistKind.top:
          await _loadTopTracks(playlist);
        case PlaylistKind.demo:
          break; // preloaded
        case PlaylistKind.spotify:
          await _loadPlaylistItems(playlist);
      }
    } catch (e) {
      playlist.tapes = [];
      playlist.loadError = 'Error: $e';
    }
    playlist.loading = false;
    notifyListeners();
  }

  /// A real playlist. Feb 2026 API: `/tracks` was renamed to `/items`. Pages
  /// through the whole thing (up to a sane cap) rather than the first 50.
  Future<void> _loadPlaylistItems(Playlist playlist) async {
    final tapes = <CassetteTape>[];
    const pageSize = 50;
    const maxTracks = 300;
    int offset = 0;
    String? error;
    while (offset < maxTracks) {
      final res = await _authedGet(
        // market=from_token relative-links the user's market so Spotify sets
        // `is_playable`, letting us drop tracks that have gone unplayable.
        Uri.parse('https://api.spotify.com/v1/playlists/${playlist.id}/items'
            '?limit=$pageSize&offset=$offset&market=from_token'),
      );
      if (res.statusCode != 200) {
        if (offset == 0) error = _apiError(res.statusCode, res.body);
        break;
      }
      final body = json.decode(res.body) as Map<String, dynamic>;
      final items = (body['items'] as List?) ?? [];
      // Tag each track with its TRUE playlist position so context playback
      // (skipToIndex) isn't thrown off by filtered-out items (episodes/nulls).
      tapes.addAll(PlaylistPaging.tapesFromPage(items, pageOffset: offset));
      if (items.length < pageSize || body['next'] == null) break;
      offset += pageSize;
    }
    playlist.tapes = tapes;
    if (tapes.isEmpty) {
      playlist.loadError = error ??
          'No items returned. Spotify only exposes tracks for playlists you '
              'own or collaborate on (Feb 2026 API change).';
    }
  }

  /// Saved songs — `GET /me/tracks` (scope `user-library-read`). Offset-paged
  /// like a playlist, newest save first; each item nests its track.
  Future<void> _loadSavedTracks(Playlist playlist) async {
    final tapes = <CassetteTape>[];
    const pageSize = 50;
    const maxTracks = 300;
    int offset = 0;
    String? error;
    while (offset < maxTracks) {
      final res = await _authedGet(Uri.parse(
          'https://api.spotify.com/v1/me/tracks'
          '?limit=$pageSize&offset=$offset&market=from_token'));
      if (res.statusCode != 200) {
        if (offset == 0) error = _apiError(res.statusCode, res.body);
        break;
      }
      final body = json.decode(res.body) as Map<String, dynamic>;
      final items = (body['items'] as List?) ?? [];
      tapes.addAll(PlaylistPaging.tapesFromPage(items, pageOffset: offset));
      if (items.length < pageSize || body['next'] == null) break;
      offset += pageSize;
    }
    playlist.tapes = tapes;
    if (tapes.isEmpty) {
      playlist.loadError = error ?? 'You have not saved any songs yet.';
    }
  }

  /// Listening history — `GET /me/player/recently-played` (scope
  /// `user-read-recently-played`). Cursor-paged, not offset-paged, and capped
  /// at 50 by Spotify, so this takes the one page and stops. It is a history,
  /// so the same song can appear several times; [PlaylistPaging.dedupeById]
  /// collapses the repeats.
  Future<void> _loadRecentlyPlayed(Playlist playlist) async {
    final res = await _authedGet(Uri.parse(
        'https://api.spotify.com/v1/me/player/recently-played?limit=50'));
    if (res.statusCode != 200) {
      playlist.tapes = [];
      playlist.loadError = _apiError(res.statusCode, res.body);
      return;
    }
    final items = (json.decode(res.body)['items'] as List?) ?? [];
    final tapes = PlaylistPaging.dedupeById(
        PlaylistPaging.tapesFromPage(items, pageOffset: 0));
    playlist.tapes = tapes;
    if (tapes.isEmpty) {
      playlist.loadError = 'Nothing played recently.';
    }
  }

  /// Your most-played tracks — `GET /me/top/tracks` (scope `user-top-read`).
  /// The window is encoded in the playlist id (`top_short_term` etc.). These
  /// are full track objects, so the search parser handles them.
  Future<void> _loadTopTracks(Playlist playlist) async {
    final range = playlist.id.startsWith('top_')
        ? playlist.id.substring(4)
        : 'medium_term';
    final res = await _authedGet(Uri.parse(
        'https://api.spotify.com/v1/me/top/tracks'
        '?limit=50&time_range=$range'));
    if (res.statusCode != 200) {
      playlist.tapes = [];
      playlist.loadError = _apiError(res.statusCode, res.body);
      return;
    }
    final items = (json.decode(res.body)['items'] as List?) ?? [];
    final tapes = <CassetteTape>[];
    for (final item in items) {
      if (item is Map<String, dynamic> && item['id'] != null) {
        try {
          tapes.add(CassetteTape.fromSpotifyTrack(item, tapes.length));
        } catch (_) {}
      }
    }
    playlist.tapes = tapes;
    if (tapes.isEmpty) {
      playlist.loadError = 'Not enough listening yet to rank your top songs.';
    }
  }

  /// Searches Spotify's catalogue for tracks matching [query].
  Future<List<CassetteTape>> searchTracks(String query) async {
    _searchError = null;
    final token = SpotifyAuth.accessToken;
    if (token == null || query.trim().isEmpty) return [];
    try {
      // Feb 2026 API: search limit max is now 10 (was 50).
      final res = await _authedGet(Uri.parse(
          'https://api.spotify.com/v1/search?type=track&limit=10&q=${Uri.encodeQueryComponent(query)}'));
      if (res.statusCode != 200) {
        _searchError = _apiError(res.statusCode, res.body);
        return [];
      }
      final items = (json.decode(res.body)['tracks']?['items'] as List?) ?? [];
      final tapes = <CassetteTape>[];
      for (final item in items) {
        if (item is Map<String, dynamic> && item['id'] != null) {
          try {
            tapes.add(CassetteTape.fromSpotifyTrack(item, tapes.length));
          } catch (_) {}
        }
      }
      return tapes;
    } catch (e) {
      _searchError = 'Error: $e';
      return [];
    }
  }

  // Recent search terms, newest first, in memory for the session. Kept small
  // so the empty search screen stays a shortcut, not a log.
  final List<String> _recentSearches = [];
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  void rememberSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    _recentSearches.removeWhere((s) => s.toLowerCase() == q.toLowerCase());
    _recentSearches.insert(0, q);
    if (_recentSearches.length > 8) _recentSearches.removeLast();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }

  // Your top artists, cached for the session — feeds the empty search screen
  // as tappable suggestions. `user-top-read`.
  List<ArtistBrief>? _topArtists;

  Future<List<ArtistBrief>> topArtists() async {
    if (_topArtists != null) return _topArtists!;
    try {
      final res = await _authedGet(Uri.parse(
          'https://api.spotify.com/v1/me/top/artists?limit=12&time_range=medium_term'));
      if (res.statusCode != 200) return const [];
      final items = (json.decode(res.body)['items'] as List?) ?? [];
      _topArtists = [
        for (final a in items)
          if (a is Map<String, dynamic> && a['id'] != null)
            ArtistBrief.fromJson(a),
      ];
      return _topArtists!;
    } catch (_) {
      return const [];
    }
  }

  /// Searches tracks, artists and albums in one call.
  Future<SearchResults> searchAll(String query) async {
    _searchError = null;
    final token = SpotifyAuth.accessToken;
    if (token == null || query.trim().isEmpty) return const SearchResults();
    try {
      final res = await _authedGet(Uri.parse(
          'https://api.spotify.com/v1/search?type=track,artist,album'
          '&limit=8&q=${Uri.encodeQueryComponent(query)}'));
      if (res.statusCode != 200) {
        _searchError = _apiError(res.statusCode, res.body);
        return const SearchResults();
      }
      return SearchResults.fromJson(json.decode(res.body) as Map<String, dynamic>);
    } catch (e) {
      _searchError = 'Error: $e';
      return const SearchResults();
    }
  }

  /// The tracks of an album — `GET /albums/{id}` — as cassettes, each borrowing
  /// the album's cover (the album's own track list ships none).
  Future<List<CassetteTape>> loadAlbumTracks(String albumId) async {
    try {
      final res = await _authedGet(
          Uri.parse('https://api.spotify.com/v1/albums/$albumId'));
      if (res.statusCode != 200) return [];
      return BrowseParsing.albumTapes(
          json.decode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return [];
    }
  }

  /// An artist's albums — `GET /artists/{id}/albums` — newest first, de-duped
  /// by name (Spotify lists the same album once per market).
  ///
  /// This endpoint caps `limit` at 10 (a 50 is a 400, which was returning an
  /// empty list), so page a few times to build a fuller list. `market` is
  /// omitted — the token's own country applies automatically.
  Future<List<AlbumBrief>> loadArtistAlbums(String artistId) async {
    final seen = <String>{};
    final albums = <AlbumBrief>[];
    try {
      for (var offset = 0; offset < 40; offset += 10) {
        final res = await _authedGet(Uri.parse(
            'https://api.spotify.com/v1/artists/$artistId/albums'
            '?include_groups=album,single&limit=10&offset=$offset'));
        if (res.statusCode != 200) break;
        final items = (json.decode(res.body)['items'] as List?) ?? [];
        for (final item in items) {
          if (item is Map<String, dynamic> && item['id'] != null) {
            final a = AlbumBrief.fromJson(item);
            if (seen.add(a.name.toLowerCase())) albums.add(a);
          }
        }
        if (items.length < 10) break;
      }
    } catch (_) {}
    return albums;
  }

  // --- Liked / saved tracks ------------------------------------------------
  //
  // These use the classic `/me/tracks` family. Spotify has deprecated it in
  // favour of a unified "Saved Items" library endpoint, but the old one still
  // works (it is what Liked Songs reads today); swap the paths here once the
  // replacement's shape is pinned. Requires scope `user-library-modify`.

  /// Which of [ids] are saved, as a map id→saved. Chunked to the 50-id cap.
  Future<Map<String, bool>> savedStatus(List<String> ids) async {
    final result = <String, bool>{};
    for (var i = 0; i < ids.length; i += 50) {
      final chunk = ids.sublist(i, i + 50 > ids.length ? ids.length : i + 50);
      try {
        final res = await _authedGet(Uri.parse(
            'https://api.spotify.com/v1/me/tracks/contains?ids=${chunk.join(',')}'));
        if (res.statusCode != 200) continue;
        final flags = (json.decode(res.body) as List?) ?? [];
        for (var j = 0; j < chunk.length && j < flags.length; j++) {
          result[chunk[j]] = flags[j] == true;
        }
      } catch (_) {}
    }
    return result;
  }

  /// Saves or unsaves one track. Returns the new saved state (unchanged on
  /// failure so the UI can revert an optimistic toggle).
  Future<bool> setSaved(String trackId, bool save) async {
    final uri =
        Uri.parse('https://api.spotify.com/v1/me/tracks?ids=$trackId');
    try {
      final res = save
          ? await http.put(uri, headers: _authHeader)
          : await http.delete(uri, headers: _authHeader);
      var code = res.statusCode;
      if (code == 401 && await SpotifyAuth.authorizeInteractive()) {
        final retry = save
            ? await http.put(uri, headers: _authHeader)
            : await http.delete(uri, headers: _authHeader);
        code = retry.statusCode;
      }
      return (code == 200 || code == 201 || code == 204) ? save : !save;
    } catch (_) {
      return !save;
    }
  }

  /// The Spotify URI of the track Spotify is currently playing (from the
  /// subscription), used to keep the app's display in step with Spotify.
  String? get currentTrackUri => _playerState?.track?.uri;

  // Liner-notes details per track id, cached (incl. misses) so reopening the
  // notes is instant and demo tapes don't refetch a 404 every time.
  final LruCache<TrackInfo?> _infoCache = LruCache<TrackInfo?>(capacity: 150);

  /// Full track details (all artists, popularity, the primary artist's genres
  /// and followers) for the liner-notes card. Null when unavailable.
  Future<TrackInfo?> fetchTrackInfo(CassetteTape tape) async {
    if (_infoCache.containsKey(tape.id)) return _infoCache.get(tape.id);
    if (!hasWebApi) return null;
    try {
      // Deliberately NO market param here: with one, Spotify relinks to a
      // regional duplicate of the track, and popularity is scored per catalog
      // entry — the duplicates all sit at 0. The canonical entry carries the
      // real number (we only need metadata, not playability, from this call).
      final res = await _authedGet(
          Uri.parse('https://api.spotify.com/v1/tracks/${tape.id}'));
      if (res.statusCode != 200) {
        _infoCache.put(tape.id, null);
        return null;
      }
      final trackJson = json.decode(res.body) as Map<String, dynamic>;
      // Enrich with the primary artist's profile (genres, followers).
      Map<String, dynamic>? artistJson;
      final artists = trackJson['artists'] as List?;
      final artistId =
          artists != null && artists.isNotEmpty && artists.first is Map
              ? (artists.first as Map)['id']
              : null;
      if (artistId is String && artistId.isNotEmpty) {
        final ares = await _authedGet(
            Uri.parse('https://api.spotify.com/v1/artists/$artistId'));
        if (ares.statusCode == 200) {
          artistJson = json.decode(ares.body) as Map<String, dynamic>;
        }
      }
      final info = TrackInfo.fromJson(trackJson, artistJson: artistJson);
      if (kDebugMode && info.popularity == 0) {
        // Evidence for the next debugging round if Spotify really sends none.
        debugPrint('TrackInfo debug: popularity=0 for "${info.title}"; '
            'track keys: ${trackJson.keys.toList()}');
      }
      _infoCache.put(tape.id, info);
      return info;
    } catch (_) {
      return null;
    }
  }

  /// Start playing a tape. Plays the real track through Spotify when connected
  /// (and the tape has a URI); otherwise runs the local demo simulation so the
  /// reels still spin and the lyrics still scroll.
  Future<void> playTape(CassetteTape tape) async {
    if (_isConnected && tape.spotifyUri.isNotEmpty) {
      await SpotifySdk.play(spotifyUri: tape.spotifyUri);
    } else {
      _demoTape = tape;
      _demoProgress = 0.0;
      _startDemoTimer();
    }
  }

  /// Play [queue] at [index] by playing the track's exact Spotify URI.
  ///
  /// We deliberately do NOT inject the rest of the queue into Spotify (that
  /// polluted the user's queue) and we do NOT use `skipToIndex` on a playlist
  /// context: Spotify's playable context order can differ from the Web API item
  /// order (unavailable/local tracks), so an index maps to the wrong song.
  /// Playing the URI is unambiguous; the app drives next/auto-advance itself.
  /// [contextUri] is accepted for call-site symmetry but not needed here.
  Future<void> playQueue(List<CassetteTape> queue, int index,
      {String? contextUri}) async {
    if (index < 0 || index >= queue.length) return;
    if (!_isConnected) {
      await playTape(queue[index]);
      return;
    }
    final start = queue[index];
    if (start.spotifyUri.isEmpty) return;
    try {
      await SpotifySdk.play(spotifyUri: start.spotifyUri);
    } catch (_) {}
  }

  Future<void> pause() async {
    if (_isConnected) {
      await SpotifySdk.pause();
    } else {
      _demoTimer?.cancel();
      _demoPlaying = false;
      notifyListeners();
    }
  }

  Future<void> resume() async {
    if (_isConnected) {
      await SpotifySdk.resume();
    } else {
      _startDemoTimer();
    }
  }

  Future<void> skipNext() async {
    if (_isConnected) {
      await SpotifySdk.skipNext();
    } else {
      _demoProgress = 0.0;
      _startDemoTimer();
    }
  }

  Future<void> skipPrevious() async {
    if (_isConnected) {
      await SpotifySdk.skipPrevious();
    } else {
      _demoProgress = 0.0;
      _startDemoTimer();
    }
  }

  /// Fetches the live playback position from Spotify (used to re-sync lyrics
  /// after the app returns from the background).
  Future<int?> fetchPositionMs() async {
    if (!_isConnected) return null;
    try {
      final st = await SpotifySdk.getPlayerState();
      return st?.playbackPosition;
    } catch (_) {
      return null;
    }
  }

  Future<void> seekTo(int positionMs) async {
    if (_isConnected) {
      await SpotifySdk.seekTo(positionedMilliseconds: positionMs);
    } else {
      final tape = _demoTape;
      if (tape != null) {
        _demoProgress = (positionMs / tape.durationMs).clamp(0.0, 1.0);
        notifyListeners();
      }
    }
  }

  void _startDemoTimer() {
    final tape = _demoTape;
    if (tape == null) return;
    _demoTimer?.cancel();
    _demoPlaying = true;
    _demoTimer = Timer.periodic(_demoTick, (t) {
      _demoProgress += _demoTick.inMilliseconds / tape.durationMs;
      if (_demoProgress >= 1.0) {
        _demoProgress = 1.0;
        _demoPlaying = false;
        t.cancel();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  // The volume knob drives the real playback volume via the Web API (the
  // native SDK has no volume call). Debounced so a knob drag sends one
  // request, not dozens; scope user-modify-playback-state is already granted.
  final Debouncer _volumeDebounce =
      Debouncer(const Duration(milliseconds: 250));

  Future<void> setVolume(int volume) async {
    if (!_isConnected || !hasWebApi) return;
    final percent = volume.clamp(0, 100);
    _volumeDebounce.run(() async {
      try {
        await _authedPut(Uri.parse(
            'https://api.spotify.com/v1/me/player/volume?volume_percent=$percent'));
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _playerSub?.cancel();
    _volumeDebounce.dispose();
    super.dispose();
  }
}
