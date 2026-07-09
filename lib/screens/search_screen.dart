import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cassette_tape.dart';
import '../services/spotify_service.dart';
import '../utils/colors.dart';
import '../widgets/vintage_background.dart';
import 'player_screen.dart';

/// Live Spotify track search. Type a song or artist; matching tracks appear as
/// rows with cover art, title and artist. Tapping one opens the player and plays
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

  void _openPlayer(int index) {
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
    if (!svc.hasWebApi) {
      return _hint(
          'Search needs the Spotify Web API token, which was not granted. '
          'Reconnect from the cabinet (RETRY) and approve all permissions.');
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
      return _hint(svc.searchError ?? 'No tapes found for "$_lastQuery".');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) => _ResultRow(
        tape: _results[i],
        onTap: () => _openPlayer(i),
      ),
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

class _ResultRow extends StatelessWidget {
  final CassetteTape tape;
  final VoidCallback onTap;

  const _ResultRow({required this.tape, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final art = tape.albumArtUrl;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EFE6).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 52,
                height: 52,
                child: art != null && art.isNotEmpty
                    ? Image.network(art, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tape.trackName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.specialElite(
                      fontSize: 14,
                      color: kTextDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tape.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.courierPrime(
                      fontSize: 12,
                      color: kTextDark.withValues(alpha: 0.75),
                    ),
                  ),
                  if (tape.albumName.isNotEmpty)
                    Text(
                      '${tape.albumName}${tape.year.isNotEmpty ? '  ·  ${tape.year}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.courierPrime(
                        fontSize: 10,
                        color: kVintageInk,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.play_circle_outline, color: kTextDark.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF161616),
        child: const Icon(Icons.music_note, color: kMark, size: 22),
      );
}
