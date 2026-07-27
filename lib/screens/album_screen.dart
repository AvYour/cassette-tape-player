import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/browse.dart';
import '../models/cassette_tape.dart';
import '../services/spotify_service.dart';
import '../utils/explore_theme.dart';
import '../widgets/glass.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/skeleton.dart';
import '../widgets/track_row.dart';
import 'player_screen.dart';

/// An album's tracks, browsed like a playlist. Reached from a search album or
/// from an artist's album list. Playing a track plays that album context.
class AlbumScreen extends StatefulWidget {
  final AlbumBrief album;
  final SpotifyService spotifyService;

  const AlbumScreen({
    super.key,
    required this.album,
    required this.spotifyService,
  });

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  SpotifyService get svc => widget.spotifyService;
  AlbumBrief get album => widget.album;

  List<CassetteTape>? _tapes;
  bool _loading = true;

  /// Whether this album is in the library — read from the service, which knows
  /// it from your saved-albums list rather than a per-album lookup.
  bool? get _saved => svc.albumSavedOrNull(album.id);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tapes = await svc.loadAlbumTracks(album.id);
    if (!mounted) return;
    setState(() {
      _tapes = tapes;
      _loading = false;
    });
    await svc.ensureSavedAlbums();
    if (tapes.isNotEmpty) {
      await svc.ensureSavedLibrary();
    }
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await _load();
  }

  Future<void> _toggleSaved() async {
    HapticFeedback.lightImpact();
    await svc.setAlbumSaved(album.id, !(_saved ?? false));
  }

  void _play(List<CassetteTape> tapes, int index) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          queue: tapes,
          index: index,
          spotifyService: svc,
          contextUri: album.contextUri,
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
          // Listening to the service so a heart toggled here — or in the
          // player — redraws every row that shows it.
          child: ListenableBuilder(
            listenable: svc,
            builder: (context, _) => MiniPlayerOverlay(
              service: svc,
              child: Column(
                children: [
                  _topBar(),
                  _header(),
                  Expanded(child: _body()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 14, 0),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: Explore.ink),
              tooltip: 'Back',
            ),
            const Spacer(),
            IconButton(
              onPressed: _saved == null ? null : _toggleSaved,
              tooltip: (_saved ?? false) ? 'Remove from library' : 'Save album',
              icon: Icon(
                (_saved ?? false)
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: _saved == null
                    ? Explore.muted.withValues(alpha: 0.4)
                    : (_saved ?? false)
                        ? const Color(0xFFE0526B)
                        : Explore.ink,
                size: 26,
              ),
            ),
          ],
        ),
      );

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 2, 24, 18),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 84,
              height: 84,
              child: album.imageUrl == null
                  ? Container(color: Explore.hairline)
                  : Image.network(album.imageUrl!,
                      fit: BoxFit.cover, cacheWidth: 260),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(album.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Explore.screenTitle.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text(album.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Explore.rowOwner),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const SkeletonList();
    }
    final tapes = _tapes ?? const [];
    if (tapes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Couldn't load this album.",
                  textAlign: TextAlign.center, style: Explore.caption),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _reload,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: Explore.card,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: Explore.lift,
                  ),
                  child: Text('Try again', style: Explore.chip),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      color: Explore.ink,
      backgroundColor: Explore.card,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, kMiniPlayerInset),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: tapes.length,
        itemBuilder: (context, i) => TrackRow(
          tape: tapes[i],
          nowPlaying: svc.nowPlaying?.id == tapes[i].id,
          saved: svc.savedOrNull(tapes[i].id),
          onToggleSaved: svc.hasWebApi
              ? () => svc.setSaved(
                  tapes[i].id, !(svc.savedOrNull(tapes[i].id) ?? false))
              : null,
          onTap: () => _play(tapes, i),
        ),
      ),
    );
  }
}
