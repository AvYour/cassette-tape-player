import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cassette_tape.dart';
import '../services/spotify_service.dart';
import '../widgets/cassette_card.dart';
import '../widgets/transport_controls.dart';
import '../widgets/volume_knob.dart';
import '../widgets/tape_counter.dart';
import '../widgets/lyric_scroller.dart';
import '../utils/colors.dart';

class PlayerScreen extends StatefulWidget {
  final CassetteTape tape;
  final SpotifyService spotifyService;

  const PlayerScreen({
    super.key,
    required this.tape,
    required this.spotifyService,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  TapeState _tapeState = TapeState.stopped;
  late CassetteTape _tape;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _tape = widget.tape;
    // Auto-start playback (real Spotify when connected, otherwise the demo
    // simulation) so the tape comes alive on open.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPlayback());
  }

  Future<void> _startPlayback() async {
    _started = true;
    await widget.spotifyService.playTape(_tape);
    if (mounted) setState(() => _tapeState = TapeState.playing);
  }

  Future<void> _handlePlay() async {
    if (!_started) {
      await _startPlayback();
    } else {
      await widget.spotifyService.resume();
      if (mounted) setState(() => _tapeState = TapeState.playing);
    }
  }

  Future<void> _handlePause() async {
    await widget.spotifyService.pause();
    if (mounted) setState(() => _tapeState = TapeState.stopped);
  }

  Future<void> _handleSkipNext() async {
    await widget.spotifyService.skipNext();
    if (mounted) setState(() => _tapeState = TapeState.playing);
  }

  Future<void> _handleSkipPrevious() async {
    await widget.spotifyService.skipPrevious();
    if (mounted) setState(() => _tapeState = TapeState.playing);
  }

  void _handleFfStart() => setState(() => _tapeState = TapeState.ff);
  void _handleFfEnd() => setState(() => _tapeState = TapeState.playing);
  void _handleRewStart() => setState(() => _tapeState = TapeState.rew);
  void _handleRewEnd() => setState(() => _tapeState = TapeState.playing);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBackground1, kBackground2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: kTextDark,
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'NOW PLAYING',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.vt323(
                          fontSize: 22,
                          color: kTextDark,
                          letterSpacing: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ListenableBuilder(
                  listenable: widget.spotifyService,
                  builder: (context, _) {
                    return CassetteCard(
                      tape: _tape,
                      tapeState: _tapeState,
                      progress: widget.spotifyService.trackProgress,
                      isHero: true,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LyricScroller(
                  trackName: _tape.trackName,
                  artistName: _tape.artistName,
                  albumName: _tape.albumName,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TransportControls(
                  tapeState: _tapeState,
                  isPlaying: _tapeState == TapeState.playing,
                  onPlay: _handlePlay,
                  onPause: _handlePause,
                  onSkipNext: _handleSkipNext,
                  onSkipPrevious: _handleSkipPrevious,
                  onFfStart: _handleFfStart,
                  onFfEnd: _handleFfEnd,
                  onRewStart: _handleRewStart,
                  onRewEnd: _handleRewEnd,
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        VolumeKnob(
                          initialVolume: 0.7,
                          onVolumeChanged: (v) {
                            widget.spotifyService.setVolume((v * 100).round());
                          },
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'VOLUME',
                          style: GoogleFonts.courierPrime(
                            fontSize: 9,
                            color: kTextDark.withValues(alpha: 0.45),
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ),
                    ListenableBuilder(
                      listenable: widget.spotifyService,
                      builder: (context, _) => Column(
                        children: [
                          TapeCounter(
                            progress: widget.spotifyService.trackProgress,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'COUNTER',
                            style: GoogleFonts.courierPrime(
                              fontSize: 9,
                              color: kTextDark.withValues(alpha: 0.45),
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
