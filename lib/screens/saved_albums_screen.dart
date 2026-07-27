import 'package:flutter/material.dart';
import '../models/browse.dart';
import '../services/spotify_service.dart';
import '../utils/explore_theme.dart';
import '../widgets/browse_rows.dart';
import '../widgets/glass.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/skeleton.dart';
import 'album_screen.dart';

/// The albums you've saved to your library — `GET /me/albums`. Each opens into
/// its tracks.
class SavedAlbumsScreen extends StatefulWidget {
  final SpotifyService spotifyService;

  const SavedAlbumsScreen({super.key, required this.spotifyService});

  @override
  State<SavedAlbumsScreen> createState() => _SavedAlbumsScreenState();
}

class _SavedAlbumsScreenState extends State<SavedAlbumsScreen> {
  SpotifyService get svc => widget.spotifyService;
  List<AlbumBrief>? _albums;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final albums = await svc.savedAlbums();
    if (!mounted) return;
    setState(() {
      _albums = albums;
      _loading = false;
    });
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
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 24, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Explore.ink),
                      tooltip: 'Back',
                    ),
                    Text('Saved Albums',
                        style: Explore.screenTitle.copyWith(fontSize: 24)),
                  ],
                ),
              ),
                Expanded(child: _body()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const SkeletonList();
    }
    final albums = _albums ?? const [];
    return RefreshIndicator(
      onRefresh: _reload,
      color: Explore.ink,
      backgroundColor: Explore.card,
      child: albums.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    "You haven't saved any albums yet — pull down to check "
                    "again.",
                    textAlign: TextAlign.center,
                    style: Explore.caption,
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, kMiniPlayerInset),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: albums.length,
              itemBuilder: (context, i) => AlbumListRow(
                album: albums[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AlbumScreen(album: albums[i], spotifyService: svc),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await _load();
  }
}
