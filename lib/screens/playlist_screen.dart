import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cassette_tape.dart';
import '../models/playlist.dart';
import '../services/spotify_service.dart';
import '../utils/explore_theme.dart';
import '../utils/track_query.dart';
import '../widgets/glass.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/skeleton.dart';
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

  final TextEditingController _filter = TextEditingController();
  TrackSort _sort = TrackSort.original;
  bool _filtering = false;

  @override
  void initState() {
    super.initState();
    // Harmless if Explore already kicked this off — the service no-ops on a
    // playlist that is loading or already loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Not gated on the tracks arriving: loadPlaylistTracks returns straight
    // away when Explore already started the same fetch, so waiting on its
    // result here would skip the library entirely and leave every row without
    // a heart.
    unawaited(svc.ensureSavedLibrary());
    await svc.loadPlaylistTracks(playlist);
  }

  /// Pull-to-refresh and the retry button share this: forget what we have and
  /// fetch it again.
  Future<void> _refresh() async {
    playlist.tapes = null;
    playlist.loadError = null;
    await _load();
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
              return MiniPlayerOverlay(
                service: svc,
                child: Column(
                  children: [
                    _topBar(),
                    _headerCard(tapes),
                    if (playlist.kind == PlaylistKind.top) _rangeChips(),
                    if (_filtering) _filterBar(),
                    if ((tapes?.length ?? 0) > 8) _sortChips(),
                    Expanded(child: _body(tapes)),
                  ],
                ),
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
          if ((playlist.tapes?.length ?? 0) > 8)
            IconButton(
              tooltip: _filtering ? 'Close search' : 'Search in this list',
              onPressed: () {
                setState(() {
                  _filtering = !_filtering;
                  if (!_filtering) _filter.clear();
                });
              },
              icon: Icon(_filtering ? Icons.close_rounded : Icons.search_rounded,
                  color: Explore.ink),
            ),
        ],
      ),
    );
  }

  /// A search box for the list you are already in — Spotify has no endpoint
  /// for "the songs in this playlist matching X", so it filters in memory.
  Widget _filterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GlassPanel(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 18, color: Explore.muted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _filter,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  cursorColor: Explore.ink,
                  style: Explore.rowTitle.copyWith(fontSize: 14.5),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Find in this list',
                    hintStyle: Explore.rowOwner.copyWith(fontSize: 14.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortChips() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        children: [
          for (final s in TrackSort.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _RangeChip(
                label: s.label,
                selected: _sort == s,
                onTap: () => setState(() => _sort = s),
              ),
            ),
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
      return const SkeletonList();
    }
    if (tapes == null || tapes.isEmpty) {
      return _emptyOrError();
    }

    // Filter first, then order — so sorting applies to what you can see.
    final shown =
        TrackQuery.sort(TrackQuery.filter(tapes, _filter.text), _sort);
    if (shown.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Text('Nothing here matches "${_filter.text.trim()}".',
              textAlign: TextAlign.center, style: Explore.caption),
        ),
      );
    }
    // Spotify's paging is capped, so a very long playlist arrives short. Say
    // so rather than let it look like the whole thing.
    final truncated = _filter.text.trim().isEmpty &&
        playlist.trackCount > tapes.length &&
        tapes.length >= 300;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: Explore.ink,
      backgroundColor: Explore.card,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, kMiniPlayerInset),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: shown.length + (truncated ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == shown.length) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
              child: Text(
                'Showing the first ${tapes.length} of ${playlist.trackCount} '
                'songs — Spotify caps how many we can page through.',
                textAlign: TextAlign.center,
                style: Explore.caption,
              ),
            );
          }
          final tape = shown[i];
          return TrackRow(
            tape: tape,
            nowPlaying: svc.nowPlaying?.id == tape.id,
            saved: svc.savedOrNull(tape.id),
            onToggleSaved: svc.hasWebApi
                ? () => svc.setSaved(tape.id, !(svc.savedOrNull(tape.id) ?? false))
                : null,
            // Play from the list as shown, so next/previous follow what you
            // are looking at rather than the unsorted original.
            onTap: () => _play(shown, i),
          );
        },
      ),
    );
  }

  /// Nothing came back — say why, and offer the way out.
  Widget _emptyOrError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            children: [
              Text(
                playlist.loadError ?? 'No songs in this playlist.',
                textAlign: TextAlign.center,
                style: Explore.caption,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _refresh,
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
      ],
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
