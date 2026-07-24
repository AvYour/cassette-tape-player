import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/browse.dart';
import '../services/spotify_service.dart';
import '../utils/debouncer.dart';
import '../utils/explore_theme.dart';
import '../widgets/glass.dart';
import '../widgets/track_row.dart';
import 'album_screen.dart';
import 'artist_screen.dart';
import 'player_screen.dart';

/// Search Spotify's catalogue across songs, artists and albums. Tracks open
/// the player, artists open their albums, albums open their tracks. Wears the
/// Explore theme, not the radio set it used to be.
class SearchScreen extends StatefulWidget {
  final SpotifyService spotifyService;

  const SearchScreen({super.key, required this.spotifyService});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final Debouncer _debounce = Debouncer(const Duration(milliseconds: 400));
  SearchResults _results = const SearchResults();
  bool _searching = false;
  String _lastQuery = '';

  // Results rise into place one after another.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  SpotifyService get svc => widget.spotifyService;

  @override
  void dispose() {
    _debounce.dispose();
    _controller.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _onChanged(String value) => _debounce.run(() => _run(value));

  Future<void> _run(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _results = const SearchResults();
        _searching = false;
        _lastQuery = '';
      });
      return;
    }
    setState(() {
      _searching = true;
      _lastQuery = q;
    });
    final res = await svc.searchAll(q);
    if (!mounted || q != _lastQuery) return;
    svc.rememberSearch(q);
    setState(() {
      _results = res;
      _searching = false;
    });
    _enter.forward(from: 0);
  }

  void _runFrom(String query) {
    _controller.text = query;
    _controller.selection =
        TextSelection.collapsed(offset: query.length);
    _run(query);
  }

  void _openTrack(int index) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: PlayerScreen(
            queue: _results.tracks,
            index: index,
            spotifyService: svc,
          ),
        ),
      ),
    );
  }

  void _openAlbum(AlbumBrief album) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlbumScreen(album: album, spotifyService: svc),
      ),
    );
  }

  void _openArtist(ArtistBrief artist) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtistScreen(artist: artist, spotifyService: svc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Explore.bgTop,
      body: GlassBackdrop(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: svc,
            builder: (context, _) => Column(
              children: [
                _searchBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Explore.ink),
            tooltip: 'Back',
          ),
          Expanded(
            child: GlassPanel(
              radius: 26,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(
                height: 50,
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        size: 20, color: Explore.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: _onChanged,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _run,
                        cursorColor: Explore.ink,
                        style: Explore.rowTitle.copyWith(fontSize: 16),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Songs, artists',
                          hintStyle: Explore.rowOwner.copyWith(fontSize: 16),
                        ),
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _controller.clear();
                          _run('');
                        },
                        child: const Icon(Icons.close_rounded,
                            size: 20, color: Explore.muted),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!svc.isConnected) {
      return _note('Connect Spotify from Explore to search.');
    }
    if (!svc.hasWebApi) {
      return _note('No Web API token. Reconnect from Explore and approve all '
          'permissions.');
    }
    if (_searching) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              strokeWidth: 2.4, color: Explore.ink),
        ),
      );
    }
    if (_lastQuery.isEmpty) {
      return _emptyState();
    }
    if (_results.isEmpty) {
      return _note(svc.searchError ?? 'Nothing found for "$_lastQuery".');
    }
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, _) => FadeTransition(
        opacity: _enter,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            if (_results.tracks.isNotEmpty) ...[
              _sectionLabel('Songs'),
              for (var i = 0; i < _results.tracks.length; i++)
                TrackRow(
                  tape: _results.tracks[i],
                  nowPlaying: svc.nowPlaying?.id == _results.tracks[i].id,
                  onTap: () => _openTrack(i),
                ),
            ],
            if (_results.artists.isNotEmpty) ...[
              _sectionLabel('Artists'),
              for (final a in _results.artists) _artistRow(a),
            ],
            if (_results.albums.isNotEmpty) ...[
              _sectionLabel('Albums'),
              for (final a in _results.albums) _albumRow(a),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 14, 0, 6),
        child: Text(text.toUpperCase(),
            style: Explore.caption.copyWith(letterSpacing: 1.5)),
      );

  /// Before you type: your recent searches, and your top artists as a jumping
  /// point. (Spotify's recommendation endpoints are retired, so these stand in
  /// for "recommended".)
  Widget _emptyState() {
    final recents = svc.recentSearches;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (recents.isNotEmpty) ...[
          Row(
            children: [
              Expanded(child: _sectionLabel('Recent')),
              GestureDetector(
                onTap: () => setState(svc.clearRecentSearches),
                child: Text('Clear', style: Explore.caption),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final q in recents)
                GestureDetector(
                  onTap: () => _runFrom(q),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Explore.card,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: Explore.lift,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_rounded,
                            size: 15, color: Explore.muted),
                        const SizedBox(width: 6),
                        Text(q, style: Explore.chip.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
        FutureBuilder<List<ArtistBrief>>(
          future: svc.topArtists(),
          builder: (context, snap) {
            final artists = snap.data ?? const [];
            if (artists.isEmpty) {
              if (snap.connectionState == ConnectionState.waiting &&
                  recents.isEmpty) {
                return const SizedBox.shrink();
              }
              if (recents.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: _note('Songs, artists, albums.'),
                );
              }
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Your top artists'),
                for (final a in artists) _artistRow(a),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _artistRow(ArtistBrief artist) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openArtist(artist),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: artist.imageUrl == null
                        ? Container(color: Explore.hairline)
                        : Image.network(artist.imageUrl!,
                            fit: BoxFit.cover, cacheWidth: 150),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Explore.rowTitle.copyWith(fontSize: 15.5)),
                ),
                const Icon(Icons.chevron_right_rounded, color: Explore.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _albumRow(AlbumBrief album) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openAlbum(album),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: album.imageUrl == null
                        ? Container(color: Explore.hairline)
                        : Image.network(album.imageUrl!,
                            fit: BoxFit.cover, cacheWidth: 150),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(album.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Explore.rowTitle.copyWith(fontSize: 15.5)),
                      const SizedBox(height: 2),
                      Text(album.artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Explore.rowOwner.copyWith(fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _note(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Explore.caption,
        ),
      ),
    );
  }
}
