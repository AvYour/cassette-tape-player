import 'package:flutter/material.dart';
import '../models/browse.dart';
import '../services/spotify_service.dart';
import '../utils/explore_theme.dart';
import '../widgets/glass.dart';
import 'album_screen.dart';

/// An artist's albums, each opening into its tracks. Reached by tapping an
/// artist in search.
class ArtistScreen extends StatefulWidget {
  final ArtistBrief artist;
  final SpotifyService spotifyService;

  const ArtistScreen({
    super.key,
    required this.artist,
    required this.spotifyService,
  });

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  SpotifyService get svc => widget.spotifyService;
  ArtistBrief get artist => widget.artist;

  List<AlbumBrief>? _albums;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final albums = await svc.loadArtistAlbums(artist.id);
    if (!mounted) return;
    setState(() {
      _albums = albums;
      _loading = false;
    });
  }

  void _openAlbum(AlbumBrief album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlbumScreen(album: album, spotifyService: svc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Explore.bgTop,
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              _header(),
              Expanded(child: _body()),
            ],
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
          ],
        ),
      );

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 2, 24, 18),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 84,
              height: 84,
              child: artist.imageUrl == null
                  ? Container(color: Explore.hairline)
                  : Image.network(artist.imageUrl!,
                      fit: BoxFit.cover, cacheWidth: 260),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(artist.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Explore.screenTitle.copyWith(fontSize: 24)),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Explore.ink, strokeWidth: 2.4),
      );
    }
    final albums = _albums ?? const [];
    if (albums.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Text('No albums found for this artist.',
              textAlign: TextAlign.center, style: Explore.caption),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: albums.length,
      itemBuilder: (context, i) => _albumRow(albums[i]),
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
                  child: Text(album.name,
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
}
