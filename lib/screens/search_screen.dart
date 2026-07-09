import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cassette_tape.dart';
import '../services/spotify_service.dart';
import '../utils/colors.dart';
import '../widgets/cassette_tape_view.dart';
import '../widgets/vintage_background.dart';
import 'player_screen.dart';

/// Live Spotify track search. Type a song or artist; matching tracks appear as
/// upright cassettes. Tapping one opens the player and (when connected) plays
/// it. Requires a Spotify connection for results.
class SearchScreen extends StatefulWidget {
  final SpotifyService spotifyService;

  const SearchScreen({super.key, required this.spotifyService});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<CassetteTape> _results = [];
  bool _searching = false;
  String _lastQuery = '';

  SpotifyService get svc => widget.spotifyService;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _run(value));
  }

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
  }

  void _openPlayer(CassetteTape tape) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: PlayerScreen(tape: tape, spotifyService: svc),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VintageBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextDark),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EFE6),
                borderRadius: BorderRadius.circular(23),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20, color: kVintageInk),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _run,
                      style: GoogleFonts.robotoMono(
                        fontSize: 14,
                        color: kTextDark,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search songs on Spotify',
                        hintStyle: GoogleFonts.robotoMono(
                          fontSize: 13,
                          color: kVintageInk.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        _run('');
                      },
                      child: const Icon(Icons.close,
                          size: 18, color: kVintageInk),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!svc.isConnected) {
      return _hint('Connect Spotify from the cabinet to search the catalogue.');
    }
    if (_searching) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: kGold),
      );
    }
    if (_lastQuery.isEmpty) {
      return _hint('Type a song or artist to find tapes.');
    }
    if (_results.isEmpty) {
      return _hint('No tapes found for "$_lastQuery".');
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.62,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final tape = _results[i];
        return GestureDetector(
          onTap: () => _openPlayer(tape),
          child: Hero(
            tag: 'tape_${tape.id}',
            flightShuttleBuilder: cassetteFlightShuttle(tape),
            child: RotatedBox(
              quarterTurns: 3,
              child: CassetteTapeView(tape: tape),
            ),
          ),
        );
      },
    );
  }

  Widget _hint(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            height: 1.5,
            color: kVintageInk,
          ),
        ),
      ),
    );
  }
}
