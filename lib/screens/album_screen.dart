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

  // Null until /me/albums/contains answers.
  bool? _saved;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tapes = await svc.loadAlbumTracks(album.id);
    final saved = await svc.isAlbumSaved(album.id);
    if (!mounted) return;
    setState(() {
      _tapes = tapes;
      _saved = saved;
      _loading = false;
    });
  }

  Future<void> _toggleSaved() async {
    final next = !(_saved ?? false);
    HapticFeedback.lightImpact();
    setState(() => _saved = next);
    final result = await svc.setAlbumSaved(album.id, next);
    if (!mounted) return;
    setState(() => _saved = result);
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
          child: MiniPlayerOverlay(
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
          child: Text("Couldn't load this album.",
              textAlign: TextAlign.center, style: Explore.caption),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, kMiniPlayerInset),
      itemCount: tapes.length,
      itemBuilder: (context, i) => TrackRow(
        tape: tapes[i],
        nowPlaying: svc.nowPlaying?.id == tapes[i].id,
        onTap: () => _play(tapes, i),
      ),
    );
  }
}
