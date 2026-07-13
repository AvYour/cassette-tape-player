import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cassette_tape.dart';
import '../painters/cassette_tape_painter.dart';
import '../services/lyrics_service.dart';
import '../services/sound_service.dart';
import '../services/spotify_service.dart';
import '../utils/colors.dart';
import '../utils/playback_math.dart';
import '../utils/scrub_math.dart';
import '../utils/tape_wind.dart';
import '../utils/vu_motion.dart';
import '../widgets/cassette_tape_view.dart';
import '../widgets/eject_button.dart';
import '../widgets/lyrics_view.dart';
import '../widgets/skeuo_button.dart';
import '../widgets/title_header.dart';
import '../widgets/dynamic_background.dart';
import '../widgets/volume_tuner.dart';
import '../widgets/vu_meter.dart';

/// The tape player screen: eject bar, J-card marquee header, the cassette,
/// scrolling lyrics and the skeuomorphic component panel — a port of the
/// reference `PlayerScreen` and its frame loop.
class PlayerScreen extends StatefulWidget {
  final List<CassetteTape> queue;
  final int index;
  final SpotifyService spotifyService;

  /// Spotify context URI (e.g. a playlist) this queue came from. When set,
  /// playback uses it so Spotify's queue mirrors the playlist instead of us
  /// injecting tracks. Null for search results / demo.
  final String? contextUri;

  const PlayerScreen({
    super.key,
    required this.queue,
    required this.index,
    required this.spotifyService,
    this.contextUri,
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
  // Base hub speed in deg/s (an empty pack at constant linear tape speed).
  // Each hub's actual speed follows its pack radius via TapeWind.hubSpeed:
  // the supply hub spins up as it drains, the take-up slows as it fills.
  static const double _baseHubSpeed = 120;

  final ReelAngles _angles = ReelAngles();
  final ValueNotifier<double> _lyricProgress = ValueNotifier(0);
  // Track progress 0..1 — winds the painted tape packs and feeds the counter.
  final ValueNotifier<double> _trackProgress = ValueNotifier(0);
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

  // After we drive a track change ourselves (next/prev/auto-advance), Spotify
  // keeps reporting the OLD track for a moment. Ignore _followSpotify until
  // this time so it doesn't bounce the display back to the previous tape.
  DateTime _ignoreFollowUntil = DateTime.fromMillisecondsSinceEpoch(0);

  // Scrubbing: dragging horizontally on the cassette winds the tape (one
  // cassette-width = the whole track). While active, the drag owns the
  // position; Spotify is sought once on release.
  double? _scrubStartMs;
  double _scrubDx = 0;
  double _cassetteW = 1;
  bool get _scrubbing => _scrubStartMs != null;

  // Clock (seconds) for the VU needles; -1 while not playing (needles rest).
  final ValueNotifier<double> _vuSeconds = ValueNotifier(-1);

  /// Re-anchor the position estimate to [posMs] as of now.
  void _anchor(double posMs) {
    _anchorPosMs = posMs;
    _anchorWall = DateTime.now();
    _positionMs = posMs;
  }

  // Lyrics: liner notes by default, replaced by lrclib results when found.
  late List<String> _lyrics = _tape.lyrics;
  List<int>? _lyricTimesMs; // set when synced lyrics are available
  int _lyricLineHint = 0; // last active line, to scan forward from each frame

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
    final resumingSame =
        svc.isConnected && svc.nowPlaying?.id == _tape.id && svc.isPlaying;
    if (resumingSame) {
      // Reopened (e.g. from the mini-player) while already playing: resume the
      // visuals in sync instead of restarting the track.
      _tapeState = TapeState.playing;
      _audioStarted = true;
      svc.fetchPositionMs().then((ms) {
        if (ms != null && mounted) _anchor(ms.toDouble());
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.spotifyService
          .setNowPlaying(widget.queue, _index, contextUri: widget.contextUri);
      // Auto-play a freshly-opened tape so tapping a cassette just plays it,
      // with no separate PLAY press. (Skip when resuming the tape that's
      // already playing.)
      if (!resumingSame) _goToIndex(_index);
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
    _ignoreFollowUntil = DateTime.now().add(const Duration(seconds: 3));
    _speedMul = 0;
    _lyricProgress.value = 0;
    _lyricLineHint = 0;
    _audioStarted = true;
    SoundService.tapeStart();
    // Play this tape and re-hand the following tracks to Spotify so background
    // auto-advance still works after a manual skip.
    widget.spotifyService
        .playQueue(widget.queue, _index, contextUri: widget.contextUri);
    widget.spotifyService
        .setNowPlaying(widget.queue, _index, contextUri: widget.contextUri);
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

  /// Play the next tape in our queue (drives Spotify directly, so it always
  /// works regardless of Spotify's own queue state).
  void _skipNext() {
    if (_index + 1 < widget.queue.length) _goToIndex(_index + 1);
  }

  /// Restart the current tape if we're past the intro, otherwise go back one.
  void _skipPrevious() {
    if (_positionMs > 3000 || _index == 0) {
      _anchor(0);
      _lyricProgress.value = 0;
      _lyricLineHint = 0;
      if (widget.spotifyService.isConnected) widget.spotifyService.seekTo(0);
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
    _trackProgress.dispose();
    _vuSeconds.dispose();
    super.dispose();
  }

  /// Follow Spotify: when it moves to another tape in our queue (its own
  /// auto-advance, or a background change), update the display to match.
  void _followSpotify() {
    final svc = widget.spotifyService;
    if (!svc.isConnected) return;
    // Only follow once THIS screen is driving playback. Otherwise, opening a
    // fresh tape while another one is still playing would hijack the display to
    // whatever Spotify happens to be playing (showing the wrong cassette).
    if (!_audioStarted) return;
    // Don't react while our own just-issued change is still settling in Spotify.
    if (DateTime.now().isBefore(_ignoreFollowUntil)) return;
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
    _ignoreFollowUntil = DateTime.now().add(const Duration(seconds: 2));
    _speedMul = 0;
    _lyricProgress.value = 0;
    _lyricLineHint = 0;
    _audioStarted = true;
    SoundService.tapeStart();
    widget.spotifyService
        .setNowPlaying(widget.queue, _index, contextUri: widget.contextUri);
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
          svc.playQueue(widget.queue, _index, contextUri: widget.contextUri);
          svc.setNowPlaying(widget.queue, _index,
              contextUri: widget.contextUri);
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

  // --- Scrubbing by dragging the cassette -------------------------------

  void _scrubStart(DragStartDetails d) {
    HapticFeedback.selectionClick();
    _scrubStartMs = _positionMs;
    _scrubDx = 0;
  }

  void _scrubUpdate(DragUpdateDetails d) {
    if (!_scrubbing) return;
    _scrubDx += d.delta.dx;
    _positionMs = ScrubMath.positionAfterDrag(
      startMs: _scrubStartMs!,
      dragDx: _scrubDx,
      trackWidth: _cassetteW,
      durationMs: _tape.durationMs,
    );
    _anchor(_positionMs);
    // The reels wind under the finger.
    final deg = d.delta.dx * 0.9;
    _left += deg;
    _right += deg;
    _angles.update(_left, _right);
  }

  void _scrubEnd([Object? _]) {
    if (!_scrubbing) return;
    _scrubStartMs = null;
    HapticFeedback.selectionClick();
    // Give Spotify a beat before trusting its position again, or a stale
    // report would snap the tape back to where it was.
    _ignoreFollowUntil = DateTime.now().add(const Duration(seconds: 2));
    _lastPoll = DateTime.now();
    widget.spotifyService.seekTo(_positionMs.round());
  }

  void _eject() {
    // Eject stops playback for good and clears the mini-player.
    SoundService.eject();
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
      // Real reel physics: each hub turns at a rate set by how much tape is
      // currently wound on it.
      final p = _trackProgress.value;
      _right += _baseHubSpeed *
          TapeWind.hubSpeed(TapeWind.rightRadiusFraction(p)) *
          frameDelta;
      _left += _baseHubSpeed *
          TapeWind.hubSpeed(TapeWind.leftRadiusFraction(p)) *
          frameDelta;
      _angles.update(_left, _right);
    }

    _updatePosition(dt);
    _updateLyricProgress();

    // Feed the VU needles while playing (rest at -1 otherwise).
    if (_tapeState == TapeState.playing) {
      _vuSeconds.value = seconds;
    } else if (_vuSeconds.value >= 0) {
      _vuSeconds.value = -1;
    }

    // We drive auto-advance ourselves in both demo AND connected mode: playback
    // uses a single track URI (no Spotify context), so Spotify won't advance on
    // its own when a track ends. (Not while the finger is winding the tape.)
    if (!_scrubbing &&
        _tapeState == TapeState.playing &&
        PlaybackMath.reachedEnd(_positionMs, _tape.durationMs)) {
      _advanceToNext();
    }
  }

  // The synced lyrics were landing a touch early; nudge the reel to lag the
  // audio slightly so a line highlights as it's sung, not just before. Tune
  // here if it drifts.
  static const double _lyricLagMs = 0;

  /// Places the lyric reel from [_positionMs], reusing the tested pure helper
  /// and a forward-scanning hint so it stays cheap on the per-frame path.
  void _updateLyricProgress() {
    final lyricPos =
        (_positionMs - _lyricLagMs).clamp(0.0, _tape.durationMs.toDouble());
    final times = _lyricTimesMs;
    if (times != null && times.length == _lyrics.length) {
      _lyricLineHint =
          PlaybackMath.lyricLineIndex(times, lyricPos, hint: _lyricLineHint);
    }
    _lyricProgress.value = PlaybackMath.lyricProgress(
      lyricPos,
      times,
      _lyrics.length,
      _tape.durationMs,
      hint: _lyricLineHint,
    );
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
        !_scrubbing &&
        _tapeState == TapeState.playing &&
        PlaybackMath.shouldReanchorPoll(
          now: DateTime.now(),
          lastPoll: _lastPoll,
          ignoreUntil: _ignoreFollowUntil,
        )) {
      _lastPoll = DateTime.now();
      svc.fetchPositionMs().then((ms) {
        if (ms != null && mounted && _tapeState == TapeState.playing) {
          _anchor(ms.toDouble());
        }
      });
    }

    if (_scrubbing) {
      // The finger owns the position while winding.
      _anchor(_positionMs);
    } else {
      switch (_tapeState) {
        case TapeState.playing:
          // Derive from wall clock so backgrounded time is included.
          final elapsed =
              DateTime.now().difference(_anchorWall).inMilliseconds.toDouble();
          _positionMs =
              PlaybackMath.interpolatePosition(_anchorPosMs, elapsed, dur);
        case TapeState.ff:
          _anchor((_positionMs + dt * 1000 * 8).clamp(0.0, dur));
        case TapeState.rew:
          _anchor((_positionMs - dt * 1000 * 8).clamp(0.0, dur));
        case TapeState.stopped:
          _anchor(_positionMs);
      }
    }

    _trackProgress.value = dur > 0 ? (_positionMs / dur).clamp(0.0, 1.0) : 0.0;
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
                child: LayoutBuilder(
                  builder: (context, cons) {
                    _cassetteW = cons.maxWidth;
                    // Drag across the cassette to wind the tape: one full
                    // width travels the whole track; release to seek there.
                    return GestureDetector(
                      onHorizontalDragStart: _scrubStart,
                      onHorizontalDragUpdate: _scrubUpdate,
                      onHorizontalDragEnd: _scrubEnd,
                      onHorizontalDragCancel: _scrubEnd,
                      child: Hero(
                        tag: 'tape_${_tape.id}',
                        flightShuttleBuilder: cassetteFlightShuttle(_tape),
                        child: _PlayerCassette(
                          tape: _tape,
                          angles: _angles,
                          progress: _trackProgress,
                        ),
                      ),
                    );
                  },
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
                  child: Row(
                    children: [
                      Expanded(
                        child: VintageVolumeTuner(
                          volume: _volume,
                          onChanged: (v) {
                            setState(() => _volume = v);
                            widget.spotifyService.setVolume((v * 100).round());
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Stereo VU meters riding the music.
                      ValueListenableBuilder<double>(
                        valueListenable: _vuSeconds,
                        builder: (context, t, _) {
                          final on = t >= 0;
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              VuMeter(
                                  deflection: on ? VuMotion.deflection(t) : 0),
                              const SizedBox(height: 4),
                              VuMeter(
                                  deflection: on
                                      ? VuMotion.deflection(t, phase: 0.9)
                                      : 0),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Mechanical counter + LCD clock, flanking the panel caption.
                ValueListenableBuilder<double>(
                  valueListenable: _trackProgress,
                  builder: (context, p, _) {
                    final dur = _tape.durationMs;
                    final ms = (p * dur).round();
                    return Row(
                      children: [
                        _CounterCells(digits: TapeWind.counterDigits(ms)),
                        Expanded(
                          child: Text(
                            'COMPONENT PANEL',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.robotoMono(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: kMark.withValues(alpha: 0.8),
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        Text(
                          '${TapeWind.clock(ms)}/${TapeWind.clock(dur)}',
                          style: GoogleFonts.robotoMono(
                            fontSize: 9.5,
                            letterSpacing: 0.5,
                            color:
                                const Color(0xFF8FD99A).withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    );
                  },
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

/// A four-digit mechanical tape counter: each digit sits in its own dark
/// cell, like the odometer wheels on a real deck.
class _CounterCells extends StatelessWidget {
  final String digits;

  const _CounterCells({required this.digits});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final d in digits.split(''))
          Container(
            width: 11,
            height: 16,
            margin: const EdgeInsets.only(right: 1.5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF090909), Color(0xFF1C1C1C)],
              ),
              border: Border.all(color: const Color(0x33000000)),
            ),
            child: Text(
              d,
              style: GoogleFonts.robotoMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE8E2D4),
                height: 1,
              ),
            ),
          ),
      ],
    );
  }
}

/// Cassette with its dark backing plate and deep shadow (player pose).
class _PlayerCassette extends StatelessWidget {
  final CassetteTape tape;
  final ReelAngles angles;
  final ValueNotifier<double> progress;

  const _PlayerCassette(
      {required this.tape, required this.angles, required this.progress});

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
            CassetteTapeView(tape: tape, angles: angles, progress: progress),
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
