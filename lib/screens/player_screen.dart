import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cassette_tape.dart';
import '../painters/cassette_tape_painter.dart';
import '../services/lyrics_service.dart';
import '../services/sound_service.dart';
import '../services/spotify_service.dart';
import '../utils/colors.dart';
import '../widgets/cassette_tape_view.dart';
import '../widgets/eject_button.dart';
import '../widgets/lyrics_view.dart';
import '../widgets/skeuo_button.dart';
import '../widgets/title_header.dart';
import '../widgets/dynamic_background.dart';
import '../widgets/volume_tuner.dart';

/// The tape player screen: eject bar, J-card marquee header, the cassette,
/// scrolling lyrics and the skeuomorphic component panel — a port of the
/// reference `PlayerScreen` and its frame loop.
class PlayerScreen extends StatefulWidget {
  final List<CassetteTape> queue;
  final int index;
  final SpotifyService spotifyService;

  const PlayerScreen({
    super.key,
    required this.queue,
    required this.index,
    required this.spotifyService,
  });

  /// Convenience for a single tape with no auto-advance queue.
  PlayerScreen.single({
    Key? key,
    required CassetteTape tape,
    required SpotifyService spotifyService,
  }) : this(key: key, queue: [tape], index: 0, spotifyService: spotifyService);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Nominal hub speeds in deg/s. The take-up (right) hub leads the supply
  // (left) hub by the wound-radius ratio, exactly as in the reference.
  static const double _rightSpeed = 120;
  static const double _leftSpeed = 120 * (0.12 / 0.23);

  final ReelAngles _angles = ReelAngles();
  final ValueNotifier<double> _lyricProgress = ValueNotifier(0);
  late final Ticker _ticker;

  TapeState _tapeState = TapeState.stopped;
  double _volume = 0.7;

  late int _index = widget.index;
  CassetteTape get _tape => widget.queue[_index];

  double _left = 0;
  double _right = 0;
  double _speedMul = 0;
  Duration _last = Duration.zero;
  bool _audioStarted = false;
  bool _advancing = false;

  // Playback position (ms), anchored to a known position + wall-clock time so
  // it stays correct even while the app (and its ticker) is backgrounded.
  double _positionMs = 0;
  double _anchorPosMs = 0;
  DateTime _anchorWall = DateTime.now();
  DateTime _lastPoll = DateTime.fromMillisecondsSinceEpoch(0);

  /// Re-anchor the position estimate to [posMs] as of now.
  void _anchor(double posMs) {
    _anchorPosMs = posMs;
    _anchorWall = DateTime.now();
    _positionMs = posMs;
  }

  // Lyrics: liner notes by default, replaced by lrclib results when found.
  late List<String> _lyrics = _tape.lyrics;
  List<int>? _lyricTimesMs; // set when synced lyrics are available

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.spotifyService.addListener(_followSpotify);
    _ticker = createTicker(_tick)..start();
    _fetchLyrics();

    // Reopened (e.g. from the mini-player) while this tape is already playing:
    // resume the visuals in sync instead of starting from stopped.
    final svc = widget.spotifyService;
    if (svc.isConnected && svc.nowPlaying?.id == _tape.id && svc.isPlaying) {
      _tapeState = TapeState.playing;
      _audioStarted = true;
      svc.fetchPositionMs().then((ms) {
        if (ms != null && mounted) _anchor(ms.toDouble());
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.spotifyService.setNowPlaying(widget.queue, _index);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The ticker freezes in the background while Spotify keeps playing, so on
    // return we snap our position to Spotify's real one to re-sync the lyrics.
    if (state == AppLifecycleState.resumed && _tapeState == TapeState.playing) {
      widget.spotifyService.fetchPositionMs().then((ms) {
        if (ms != null && mounted) _anchor(ms.toDouble());
      });
    }
  }

  Future<void> _fetchLyrics() async {
    final t = _tape;
    final lyrics = await LyricsService.fetch(
      track: t.trackName,
      artist: t.artistName,
      album: t.albumName,
      durationMs: t.durationMs,
    );
    if (!mounted || t.id != _tape.id || lyrics == null || lyrics.isEmpty) {
      return;
    }
    setState(() {
      _lyrics = lyrics.lines;
      _lyricTimesMs = lyrics.timesMs;
    });
  }

  /// Loads and starts playing the tape at [i], resetting all playback state.
  void _goToIndex(int i) {
    if (i < 0 || i >= widget.queue.length) return;
    setState(() {
      _index = i;
      _lyrics = _tape.lyrics;
      _lyricTimesMs = null;
      _tapeState = TapeState.playing;
    });
    _anchor(0);
    _lastPoll = DateTime.fromMillisecondsSinceEpoch(0);
    _speedMul = 0;
    _lyricProgress.value = 0;
    _audioStarted = true;
    SoundService.tapeStart();
    widget.spotifyService.playTape(_tape);
    widget.spotifyService.setNowPlaying(widget.queue, _index);
    _fetchLyrics();
  }

  /// When the track ends, roll on to the next tape and keep playing — like
  /// flipping to the next song on a mixtape.
  void _advanceToNext() {
    if (_advancing) return;
    if (_index + 1 >= widget.queue.length) {
      _setTapeState(TapeState.stopped);
      return;
    }
    _advancing = true;
    _goToIndex(_index + 1);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _advancing = false;
    });
  }

  void _skipNext() {
    final svc = widget.spotifyService;
    if (svc.isConnected) {
      // Let Spotify advance its queue; _followSpotify updates the display.
      svc.skipNext();
    } else if (_index + 1 < widget.queue.length) {
      _goToIndex(_index + 1);
    }
  }

  /// Restart the current tape if we're past the intro, otherwise go back one.
  void _skipPrevious() {
    final svc = widget.spotifyService;
    if (svc.isConnected) {
      if (_positionMs > 3000) {
        _anchor(0);
        _lyricProgress.value = 0;
        svc.seekTo(0);
      } else {
        svc.skipPrevious();
      }
    } else if (_positionMs > 3000 || _index == 0) {
      _anchor(0);
      _lyricProgress.value = 0;
    } else {
      _goToIndex(_index - 1);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.spotifyService.removeListener(_followSpotify);
    _ticker.dispose();
    _angles.dispose();
    _lyricProgress.dispose();
    super.dispose();
  }

  /// Follow Spotify: when it moves to another tape in our queue (its own
  /// auto-advance, or a background change), update the display to match.
  void _followSpotify() {
    final svc = widget.spotifyService;
    if (!svc.isConnected) return;
    final uri = svc.currentTrackUri;
    if (uri == null || uri.isEmpty || uri == _tape.spotifyUri) return;
    final idx = widget.queue.indexWhere((t) => t.spotifyUri == uri);
    if (idx != -1 && idx != _index) _followToIndex(idx);
  }

  /// Switch the display to queue[i] without issuing playback (Spotify is
  /// already playing it).
  void _followToIndex(int i) {
    if (!mounted) return;
    setState(() {
      _index = i;
      _lyrics = _tape.lyrics;
      _lyricTimesMs = null;
      _tapeState = TapeState.playing;
    });
    _anchor(0);
    _lastPoll = DateTime.fromMillisecondsSinceEpoch(0);
    _speedMul = 0;
    _lyricProgress.value = 0;
    _audioStarted = true;
    SoundService.tapeStart();
    widget.spotifyService.setNowPlaying(widget.queue, _index);
    _fetchLyrics();
  }

  void _setTapeState(TapeState state) {
    if (state == _tapeState) return;
    final wasPlaying = _tapeState == TapeState.playing;
    setState(() => _tapeState = state);
    // The reference frame loop restarts per state change, resetting the
    // multiplier so every transition re-ramps from zero.
    _speedMul = 0;
    if (state == TapeState.playing && !wasPlaying) SoundService.tapeStart();
    if (state == TapeState.stopped) SoundService.tapeStop();
    _handleAudio(state);
  }

  void _handleAudio(TapeState state) {
    final svc = widget.spotifyService;
    if (!svc.isConnected) return;
    switch (state) {
      case TapeState.playing:
        if (!_audioStarted) {
          _audioStarted = true;
          svc.playQueue(widget.queue, _index);
          svc.setNowPlaying(widget.queue, _index);
        } else {
          // Resume at the (possibly scrubbed) position.
          svc.seekTo(_positionMs.round());
          svc.resume();
        }
      case TapeState.stopped:
        svc.pause();
      case TapeState.ff:
      case TapeState.rew:
        // Silence the audio while winding; PLAY reseeks to the new spot.
        svc.pause();
    }
  }

  void _eject() {
    // Eject stops playback for good and clears the mini-player.
    SoundService.tapeStop();
    widget.spotifyService.pause();
    widget.spotifyService.clearNowPlaying();
    Navigator.of(context).maybePop();
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;

    final target = switch (_tapeState) {
      TapeState.playing => 1.0,
      TapeState.ff => 6.0,
      TapeState.rew => -6.0,
      TapeState.stopped => 0.0,
    };
    _speedMul += (target - _speedMul) * (dt * 4);

    final seconds = elapsed.inMicroseconds / 1e6;
    final motorDrift = _tapeState == TapeState.playing
        ? 1.0 + 0.03 * math.sin(seconds * (2 * math.pi / 4))
        : 1.0;

    if (_speedMul.abs() > 0.01) {
      final frameDelta = _speedMul * motorDrift * dt;
      _right += _rightSpeed * frameDelta;
      _left += _leftSpeed * frameDelta;
      _angles.update(_left, _right);
    }

    _updatePosition(dt);
    _updateLyricProgress();

    // In demo mode we advance the queue ourselves; when connected, Spotify
    // advances its own queue and _followSpotify keeps the display in sync.
    final dur = _tape.durationMs.toDouble();
    if (!widget.spotifyService.isConnected &&
        _tapeState == TapeState.playing &&
        dur > 1000 &&
        _positionMs >= dur - 250) {
      _advanceToNext();
    }
  }

  /// Keeps [_positionMs] in step with playback: snap to Spotify events (which
  /// only arrive on changes), interpolate by time while playing, and scrub on
  /// FF/REW.
  void _updatePosition(double dt) {
    final svc = widget.spotifyService;
    final dur = _tape.durationMs.toDouble();

    // Periodically re-sync to Spotify's REAL position via getPlayerState
    // (subscription events carry a stale position, so we don't trust them).
    // Wall-clock interpolation covers the gaps between polls.
    if (svc.isConnected &&
        _tapeState == TapeState.playing &&
        DateTime.now().difference(_lastPoll).inMilliseconds > 3000) {
      _lastPoll = DateTime.now();
      svc.fetchPositionMs().then((ms) {
        if (ms != null && mounted && _tapeState == TapeState.playing) {
          _anchor(ms.toDouble());
        }
      });
    }

    switch (_tapeState) {
      case TapeState.playing:
        // Derive from wall clock so backgrounded time is included.
        final elapsed =
            DateTime.now().difference(_anchorWall).inMilliseconds.toDouble();
        _positionMs = (_anchorPosMs + elapsed).clamp(0.0, dur);
      case TapeState.ff:
        _anchor((_positionMs + dt * 1000 * 8).clamp(0.0, dur));
      case TapeState.rew:
        _anchor((_positionMs - dt * 1000 * 8).clamp(0.0, dur));
      case TapeState.stopped:
        _anchor(_positionMs);
    }
  }

  /// Places the lyric reel from [_positionMs] (synced or proportional).
  void _updateLyricProgress() {
    final lineCount = _lyrics.length;
    if (lineCount == 0) return;
    final maxProgress = (lineCount - 1).toDouble();
    final times = _lyricTimesMs;

    if (times != null && times.length == lineCount) {
      int i = 0;
      while (i < times.length - 1 && times[i + 1] <= _positionMs) {
        i++;
      }
      double frac = 0;
      if (i < times.length - 1) {
        final span = times[i + 1] - times[i];
        if (span > 0) frac = ((_positionMs - times[i]) / span).clamp(0.0, 1.0);
      }
      _lyricProgress.value = (i + frac).clamp(0.0, maxProgress);
    } else {
      final dur = _tape.durationMs.toDouble();
      final ratio = dur > 0 ? _positionMs / dur : 0.0;
      _lyricProgress.value = (ratio * maxProgress).clamp(0.0, maxProgress);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeAnim =
        ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;
    final headerAnim = CurvedAnimation(
        parent: routeAnim,
        curve: const Interval(0.3, 1, curve: Curves.easeOutCubic));
    final panelAnim = CurvedAnimation(
        parent: routeAnim,
        curve: const Interval(0.4, 1, curve: Curves.easeOutCubic));

    return Scaffold(
      body: DynamicMusicBackground(
        tape: _tape,
        progress: _lyricProgress,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      height: 44,
                      child: VintageEjectButton(
                        onPressed: _eject,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: headerAnim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, -1), end: Offset.zero)
                      .animate(headerAnim),
                  child: FractionallySizedBox(
                    widthFactor: 0.85,
                    child: SizedBox(
                      height: 40,
                      child: VintageTitleHeader(
                        tape: _tape,
                        tapeState: _tapeState,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FractionallySizedBox(
                widthFactor: 0.9,
                child: Hero(
                  tag: 'tape_${_tape.id}',
                  flightShuttleBuilder: cassetteFlightShuttle(_tape),
                  child: _PlayerCassette(tape: _tape, angles: _angles),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: FadeTransition(
                  opacity: panelAnim,
                  child: FractionallySizedBox(
                    widthFactor: 0.88,
                    child: VintageLyrics(
                      lyrics: _lyrics,
                      progress: _lyricProgress,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SlideTransition(
                position: Tween(begin: const Offset(0, 2), end: Offset.zero)
                    .animate(panelAnim),
                child: FadeTransition(
                  opacity: panelAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: _buildControlPanel(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      decoration: BoxDecoration(
        color: kControlPanelBg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Machined seam near the top edge.
          Positioned(
            top: 8,
            left: 6,
            right: 6,
            child: Column(
              children: [
                Container(height: 2, color: const Color(0x33000000)),
                Container(height: 1, color: const Color(0x1AFFFFFF)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
            child: Column(
              children: [
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: VintageVolumeTuner(
                    volume: _volume,
                    onChanged: (v) {
                      setState(() => _volume = v);
                      widget.spotifyService.setVolume((v * 100).round());
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'COMPONENT PANEL',
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: kMark.withValues(alpha: 0.8),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SkeuoButton(
                        icon: RetroIcon.prev,
                        onPressed: _skipPrevious,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SkeuoButton(
                        icon: RetroIcon.rec,
                        isRed: true,
                        isToggled: _tapeState == TapeState.playing,
                        onPressed: () => _setTapeState(TapeState.playing),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SkeuoButton(
                        icon: RetroIcon.rew,
                        isToggled: _tapeState == TapeState.rew,
                        onPressed: () => _setTapeState(TapeState.rew),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SkeuoButton(
                        icon: RetroIcon.play,
                        isToggled: _tapeState == TapeState.playing,
                        onPressed: () => _setTapeState(TapeState.playing),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SkeuoButton(
                        icon: RetroIcon.ff,
                        isToggled: _tapeState == TapeState.ff,
                        onPressed: () => _setTapeState(TapeState.ff),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SkeuoButton(
                        icon: RetroIcon.next,
                        enabled: _index + 1 < widget.queue.length,
                        onPressed: _skipNext,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SkeuoButton(
                        icon: RetroIcon.stop,
                        onPressed: () => _setTapeState(TapeState.stopped),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cassette with its dark backing plate and deep shadow (player pose).
class _PlayerCassette extends StatelessWidget {
  final CassetteTape tape;
  final ReelAngles angles;

  const _PlayerCassette({required this.tape, required this.angles});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: kCassetteAspect,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _BackingPainter()),
            CassetteTapeView(tape: tape, angles: angles),
          ],
        ),
      ),
    );
  }
}

class _BackingPainter extends CustomPainter {
  const _BackingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(size.height * 0.06));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF0A0A0A));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height * 0.4),
          const [Color(0xDD000000), Colors.transparent],
        ),
    );
  }

  @override
  bool shouldRepaint(_BackingPainter old) => false;
}
