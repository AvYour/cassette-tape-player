import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/browse.dart';
import '../services/spotify_service.dart';
import '../services/wiki_service.dart';
import '../utils/explore_theme.dart';
import '../widgets/browse_rows.dart';
import '../widgets/glass.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/skeleton.dart';
import 'album_screen.dart';

/// An artist page: a Follow toggle, a Wikipedia paragraph about them, and
/// their albums. Reached from search or the Following list.
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

  // Null until /me/following/contains answers.
  bool? _following;

  // Wikipedia's opening paragraph; null when there is no usable article.
  String? _bio;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final albums = await svc.loadArtistAlbums(artist.id);
    final follows = await svc.isFollowingArtist(artist.id);
    if (!mounted) return;
    setState(() {
      _albums = albums;
      _following = follows;
      _loading = false;
    });
    // Spotify has no biography, so the About text comes from Wikipedia. It
    // arrives on its own schedule — the page is already usable without it.
    final bio = await WikiService.bio(artist.name);
    if (mounted) setState(() => _bio = bio);
  }

  Future<void> _toggleFollow() async {
    final next = !(_following ?? false);
    HapticFeedback.selectionClick();
    setState(() => _following = next);
    final result = await svc.setFollowingArtist(artist.id, next);
    if (!mounted) return;
    setState(() => _following = result);
  }

  void _openAlbum(AlbumBrief album) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlbumScreen(album: album, spotifyService: svc),
        ),
      );

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
          ],
        ),
      );

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 2, 24, 14),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(artist.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Explore.screenTitle.copyWith(fontSize: 23)),
                const SizedBox(height: 8),
                _followButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _followButton() {
    final following = _following ?? false;
    return GestureDetector(
      onTap: _following == null ? null : _toggleFollow,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: following ? Colors.transparent : Explore.ink,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: following ? Explore.muted : Colors.transparent),
        ),
        child: Text(
          following ? 'Following' : 'Follow',
          style: Explore.chip.copyWith(
            fontSize: 13,
            color: following ? Explore.muted : Colors.white,
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
    if (albums.isEmpty && _bio == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Text('Nothing to show for this artist.',
              textAlign: TextAlign.center, style: Explore.caption),
        ),
      );
    }
    // Genres and followers used to sit here. Spotify deprecated both on the
    // artist object (along with popularity) and now returns them empty, so the
    // section only ever rendered a blank — the Wikipedia paragraph below is
    // what actually says something about the artist.
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, kMiniPlayerInset),
      children: [
        if (_bio != null) ...[
          _sectionLabel('About'),
          Text(_bio!,
              style: Explore.rowOwner
                  .copyWith(color: Explore.ink, height: 1.5, fontSize: 13.5)),
          const SizedBox(height: 4),
          Text('From Wikipedia',
              style: Explore.caption.copyWith(fontSize: 10)),
        ],
        if (albums.isNotEmpty) ...[
          _sectionLabel('Albums'),
          for (final a in albums)
            AlbumListRow(album: a, showArtist: false, onTap: () => _openAlbum(a)),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 14, 0, 6),
        child: Text(text.toUpperCase(),
            style: Explore.caption.copyWith(letterSpacing: 1.5)),
      );
}
