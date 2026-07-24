import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cassette_tape.dart';
import '../models/playlist.dart';
import '../services/spotify_service.dart';
import '../utils/explore_theme.dart';
import '../widgets/glass.dart';
import '../widgets/track_row.dart';
import 'player_screen.dart';

/// A playlist's songs, plainly listed. This is the step between Explore and
/// the player: pick the playlist, then pick the track. Tracks load lazily the
/// first time you get here.
class PlaylistScreen extends StatefulWidget {
  final Playlist playlist;
  final SpotifyService spotifyService;

  const PlaylistScreen({
    super.key,
    required this.playlist,
    required this.spotifyService,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  // Mutable so "Your Top Songs" can swap its window in place: a new range is a
  // new Playlist (new id → new cache) that we then load.
  late Playlist _playlist = widget.playlist;
  Playlist get playlist => _playlist;
  SpotifyService get svc => widget.spotifyService;

  @override
  void initState() {
    super.initState();
    // Harmless if Explore already kicked this off — the service no-ops on a
    // playlist that is loading or already loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      svc.loadPlaylistTracks(playlist);
    });
  }

  void _setRange(TopRange range) {
    if ('top_${range.api}' == _playlist.id) return;
    svc.topRange = range; // also swaps the Explore row
    setState(() => _playlist = Playlist.topTracks(range));
    svc.loadPlaylistTracks(_playlist);
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
          contextUri: playlist.contextUri,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Explore.bgTop,
      body: GlassBackdrop(
        tint: playlist.accent,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: svc,
            builder: (context, _) {
              final tapes = playlist.tapes;
              return Column(
                children: [
                  _topBar(),
                  _headerCard(tapes),
                  if (playlist.kind == PlaylistKind.top) _rangeChips(),
                  Expanded(child: _body(tapes)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _rangeChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          for (final r in TopRange.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _RangeChip(
                label: r.label,
                selected: 'top_${r.api}' == playlist.id,
                onTap: () => _setRange(r),
              ),
            ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 14, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Explore.ink),
            tooltip: 'Back',
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _headerCard(List<CassetteTape>? tapes) {
    final count = tapes?.length ?? playlist.trackCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 2, 24, 18),
      child: Row(
        children: [
          _cover(84),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Explore.screenTitle.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  count > 0
                      ? '${playlist.owner} · $count songs'
                      : playlist.owner,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Explore.rowOwner,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(List<CassetteTape>? tapes) {
    if (playlist.loading && (tapes == null || tapes.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(color: Explore.ink, strokeWidth: 2.4),
      );
    }
    if (tapes == null || tapes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Text(
            playlist.loadError ?? 'No songs in this playlist.',
            textAlign: TextAlign.center,
            style: Explore.caption,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: tapes.length,
      itemBuilder: (context, i) => TrackRow(
        tape: tapes[i],
        nowPlaying: svc.nowPlaying?.id == tapes[i].id,
        onTap: () => _play(tapes, i),
      ),
    );
  }

  Widget _cover(double size) {
    final url = playlist.imageUrl;
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: url == null || url.isEmpty
            ? Container(
                color: playlist.accent,
                alignment: Alignment.center,
                child: Text(
                  playlist.name.trim().isEmpty
                      ? '♪'
                      : playlist.name.trim().characters.first.toUpperCase(),
                  style: Explore.rowTitle
                      .copyWith(color: Colors.white, fontSize: size * 0.4),
                ),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: (size * 3).round(),
                errorBuilder: (_, __, ___) => Container(color: playlist.accent),
              ),
      ),
    );
  }
}

/// A pill for choosing the Top Songs window: filled glass when picked, a plain
/// hairline outline otherwise.
class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Explore.card : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : Explore.hairline,
          ),
          boxShadow: selected ? Explore.lift : null,
        ),
        child: Text(
          label,
          style: Explore.caption.copyWith(
            color: selected ? Explore.ink : Explore.muted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
