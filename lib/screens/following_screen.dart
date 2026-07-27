import 'package:flutter/material.dart';
import '../models/browse.dart';
import '../services/spotify_service.dart';
import '../utils/explore_theme.dart';
import '../widgets/browse_rows.dart';
import '../widgets/glass.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/skeleton.dart';
import 'artist_screen.dart';

/// The artists you follow — `GET /me/following?type=artist`. Each opens their
/// albums.
class FollowingScreen extends StatefulWidget {
  final SpotifyService spotifyService;

  const FollowingScreen({super.key, required this.spotifyService});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  SpotifyService get svc => widget.spotifyService;
  List<ArtistBrief>? _artists;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final artists = await svc.following();
    if (!mounted) return;
    setState(() {
      _artists = artists;
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
                    Text('Following',
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
      return const SkeletonList(round: true);
    }
    final artists = _artists ?? const [];
    if (artists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Text("You aren't following any artists yet.",
              textAlign: TextAlign.center, style: Explore.caption),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, kMiniPlayerInset),
      itemCount: artists.length,
      itemBuilder: (context, i) => ArtistListRow(
        artist: artists[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ArtistScreen(artist: artists[i], spotifyService: svc),
          ),
        ),
      ),
    );
  }
}
