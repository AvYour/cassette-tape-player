import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/playlist.dart';
import '../services/spotify_service.dart';
import '../utils/carousel_math.dart';
import '../utils/explore_theme.dart';
import '../widgets/glass.dart';
import 'player_screen.dart';
import 'playlist_screen.dart';
import 'search_screen.dart';

/// Home: your playlists on a slow vertical wheel. The row under the reading
/// line sits full-size on a white lozenge and is the only one that offers
/// Play; the rest fall away above and below, fading and drifting right.
///
/// Tapping a row opens its tracks — pick the playlist, then the song. The
/// cabinet-and-drawer room this replaced is gone from the browsing path.
class HomeScreen extends StatefulWidget {
  final SpotifyService spotifyService;

  /// Connect to Spotify on first frame. Off in widget tests, which have no
  /// platform channels to answer the SDK.
  final bool autoConnect;

  const HomeScreen({
    super.key,
    required this.spotifyService,
    this.autoConnect = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Height of one row on the wheel.
  static const double _rowExtent = 106;

  /// The built-in starter mixtape, shown until Spotify hands us real
  /// playlists, so home is never an empty page.
  late final Playlist _demo = Playlist.demo();

  final FixedExtentScrollController _wheel = FixedExtentScrollController();

  int _focused = 0;

  /// Id of the playlist whose Play chip is busy loading its tracks.
  String? _starting;

  SpotifyService get svc => widget.spotifyService;

  @override
  void initState() {
    super.initState();
    if (widget.autoConnect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!svc.isConnected && !svc.isLoading) svc.connectToSpotify();
      });
    }
  }

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  /// Fractional position of the wheel in rows, so a row knows how far it is
  /// from the focus mid-scroll and not just once it has settled.
  double get _page {
    if (!_wheel.hasClients) return _focused.toDouble();
    final position = _wheel.position;
    if (!position.hasPixels) return _focused.toDouble();
    return position.pixels / _rowExtent;
  }

  /// A row off the reading line only pulls itself into focus; the focused one
  /// opens its tracks.
  void _tapRow(Playlist playlist, int index) {
    if (index != _focused) {
      _wheel.animateToItem(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    HapticFeedback.selectionClick();
    svc.loadPlaylistTracks(playlist);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistScreen(playlist: playlist, spotifyService: svc),
      ),
    );
  }

  /// Play chip: load the playlist if needed, then drop the needle on track one.
  Future<void> _playAll(Playlist playlist) async {
    if (_starting != null) return;
    HapticFeedback.mediumImpact();
    setState(() => _starting = playlist.id);
    await svc.loadPlaylistTracks(playlist);
    if (!mounted) return;
    setState(() => _starting = null);

    final tapes = playlist.tapes;
    if (tapes == null || tapes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(playlist.loadError ?? 'This playlist came back empty.'),
      ));
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          queue: tapes,
          index: 0,
          spotifyService: svc,
          contextUri: playlist.contextUri,
        ),
      ),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchScreen(spotifyService: svc)),
    );
  }

  void _openNowPlaying() {
    if (svc.nowPlaying == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing is playing yet.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          queue: svc.nowQueue,
          index: svc.nowIndex,
          spotifyService: svc,
          contextUri: svc.nowContextUri,
        ),
      ),
    );
  }

  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Explore.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!svc.isConnected)
              ListTile(
                leading: const Icon(Icons.link_rounded, color: Color(0xFF1DB954)),
                title: Text('Connect Spotify', style: Explore.chip),
                onTap: () {
                  Navigator.pop(sheet);
                  svc.connectToSpotify();
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.refresh_rounded, color: Explore.ink),
                title: Text('Refresh playlists', style: Explore.chip),
                onTap: () {
                  Navigator.pop(sheet);
                  svc.fetchPlaylists();
                },
              ),
            ListTile(
              leading: const Icon(Icons.search_rounded, color: Explore.ink),
              title: Text('Search Spotify', style: Explore.chip),
              onTap: () {
                Navigator.pop(sheet);
                _openSearch();
              },
            ),
          ],
        ),
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
            builder: (context, _) {
              final playlists =
                  svc.playlists.isEmpty ? [_demo] : svc.playlists;
              return Column(
                children: [
                  _header(),
                  Expanded(child: _buildWheel(playlists)),
                  _navBar(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final String? note = svc.isLoading
        ? 'Connecting to Spotify…'
        : !svc.isConnected
            ? 'Connect Spotify to see your playlists'
            : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 16, 14, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Explore', style: Explore.screenTitle),
                if (note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(note, style: Explore.caption),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _openMenu,
            icon: const Icon(Icons.more_horiz_rounded,
                color: Explore.ink, size: 26),
            tooltip: 'More',
          ),
        ],
      ),
    );
  }

  Widget _buildWheel(List<Playlist> playlists) {
    return ListWheelScrollView.useDelegate(
      controller: _wheel,
      itemExtent: _rowExtent,
      physics: const FixedExtentScrollPhysics(),
      // Nearly flat: the fall-away is ours (scale/fade/drift), not the wheel's.
      diameterRatio: 8,
      perspective: 0.0009,
      onSelectedItemChanged: (index) {
        HapticFeedback.selectionClick();
        setState(() => _focused = index);
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: playlists.length,
        builder: (context, index) => AnimatedBuilder(
          animation: _wheel,
          builder: (context, _) {
            final d = index - _page;
            return Transform.translate(
              offset: Offset(CarouselMath.shiftX(d), 0),
              child: Transform.scale(
                scale: CarouselMath.scale(d),
                alignment: Alignment.centerLeft,
                child: Opacity(
                  opacity: CarouselMath.opacity(d),
                  child: _row(playlists[index], index, d),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _row(Playlist playlist, int index, double d) {
    // 1 on the reading line, 0 a full row away — drives the lozenge and chip.
    final focus = (1 - d.abs()).clamp(0.0, 1.0);
    final chipOpacity = ((focus - 0.35) / 0.65).clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _tapRow(playlist, index),
      child: SizedBox(
        height: _rowExtent,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            if (focus > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(46, 14, 16, 14),
                child: Opacity(
                  opacity: focus,
                  child: const GlassPanel(radius: 40, child: SizedBox.expand()),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 28, 0),
              child: Row(
                children: [
                  _cover(playlist, 74),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Explore.rowTitle,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          playlist.owner,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Explore.rowOwner,
                        ),
                      ],
                    ),
                  ),
                  if (chipOpacity > 0)
                    Opacity(
                      opacity: chipOpacity,
                      child: _playChip(playlist),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playChip(Playlist playlist) {
    final busy = _starting == playlist.id;
    return GestureDetector(
      onTap: busy ? null : () => _playAll(playlist),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: Explore.bgTop,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Explore.hairline),
        ),
        child: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Explore.ink),
              )
            : Text('Play', style: Explore.chip),
      ),
    );
  }

  /// Round playlist cover. Without Spotify art (the starter mixtape, or a
  /// playlist with none) it falls back to a disc in the playlist's own accent.
  Widget _cover(Playlist playlist, double size) {
    final url = playlist.imageUrl;
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: url == null || url.isEmpty
            ? _coverFallback(playlist, size)
            : Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: (size * 3).round(),
                errorBuilder: (_, __, ___) => _coverFallback(playlist, size),
              ),
      ),
    );
  }

  // The three system shelves get a meaningful glyph instead of a letter, so
  // they read as different in kind from the playlists around them.
  static const Map<PlaylistKind, IconData> _kindIcon = {
    PlaylistKind.liked: Icons.favorite_rounded,
    PlaylistKind.top: Icons.trending_up_rounded,
    PlaylistKind.recent: Icons.history_rounded,
  };

  Widget _coverFallback(Playlist playlist, double size) {
    final icon = _kindIcon[playlist.kind];
    // A soft two-tone disc under the mark, richer than a flat swatch.
    final disc = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            playlist.accent,
            Color.lerp(playlist.accent, Colors.black, 0.18)!,
          ],
        ),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: Colors.white, size: size * 0.42)
            : Text(
                playlist.name.trim().isEmpty
                    ? '♪'
                    : playlist.name.trim().characters.first.toUpperCase(),
                style: Explore.rowTitle
                    .copyWith(color: Colors.white, fontSize: size * 0.4),
              ),
      ),
    );
    return SizedBox(width: size, height: size, child: disc);
  }

  Widget _navBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavIcon(
            icon: Icons.search_rounded,
            label: 'Search',
            onTap: _openSearch,
          ),
          const _NavIcon(
            icon: Icons.album_rounded,
            label: 'Explore',
            active: true,
          ),
          _NavIcon(
            icon: Icons.play_circle_fill_rounded,
            label: 'Now playing',
            onTap: _openNowPlaying,
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavIcon({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: label,
      icon: Icon(
        icon,
        size: active ? 30 : 26,
        color: active ? Explore.ink : Explore.muted,
      ),
    );
  }
}
