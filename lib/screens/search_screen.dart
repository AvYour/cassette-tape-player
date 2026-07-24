import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cassette_tape.dart';
import '../services/spotify_service.dart';
import '../utils/debouncer.dart';
import '../utils/explore_theme.dart';
import '../utils/grid_math.dart';
import '../widgets/glass.dart';
import '../widgets/track_row.dart';
import 'player_screen.dart';

/// Search Spotify's catalogue. Type and matching tracks settle in as the same
/// rows a playlist shows; tapping one loads it into the player. Wears the
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
  List<CassetteTape> _results = [];
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
        _results = [];
        _searching = false;
        _lastQuery = '';
      });
      return;
    }
    setState(() {
      _searching = true;
      _lastQuery = q;
    });
    final res = await svc.searchTracks(q);
    if (!mounted || q != _lastQuery) return;
    setState(() {
      _results = res;
      _searching = false;
    });
    _enter.forward(from: 0);
  }

  void _openPlayer(int index) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: PlayerScreen(
            queue: _results,
            index: index,
            spotifyService: svc,
          ),
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
      return _note('Type a song or an artist.');
    }
    if (_results.isEmpty) {
      return _note(svc.searchError ?? 'Nothing found for "$_lastQuery".');
    }
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, _) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _results.length,
        itemBuilder: (context, i) {
          final (ws, we) = GridMath.rowStaggerWindow(i);
          final rise =
              Interval(ws, we, curve: Curves.easeOutCubic).transform(_enter.value);
          return Opacity(
            opacity: rise,
            child: Transform.translate(
              offset: Offset(0, (1 - rise) * 16),
              child: TrackRow(
                tape: _results[i],
                nowPlaying: svc.nowPlaying?.id == _results[i].id,
                onTap: () => _openPlayer(i),
              ),
            ),
          );
        },
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
