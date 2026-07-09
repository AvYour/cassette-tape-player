import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cassette_tape.dart';
import '../painters/cassette_tape_painter.dart';
import '../services/spotify_service.dart';
import '../utils/colors.dart';
import '../widgets/cassette_tape_view.dart';
import '../widgets/eject_button.dart';
import '../widgets/lyrics_view.dart';
import '../widgets/skeuo_button.dart';
import '../widgets/title_header.dart';
import '../widgets/vintage_background.dart';
import '../widgets/volume_tuner.dart';

/// The tape player screen: eject bar, J-card marquee header, the cassette,
/// scrolling lyrics and the skeuomorphic component panel — a port of the
/// reference `PlayerScreen` and its frame loop.
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

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  // Nominal hub speeds in deg/s. The take-up (right) hub leads the supply
  // (left) hub by the wound-radius ratio, exactly as in the reference.
  static const double _rightSpeed = 120;
  static const double _leftSpeed = 120 * (0.12 / 0.23);

  final ReelAngles _angles = ReelAngles();
  final ValueNotifier<double> _lyricProgress = ValueNotifier(0);
  late final Ticker _ticker;

  TapeState _tapeState = TapeState.stopped;
  double _volume = 0.7;

  double _left = 0;
  double _right = 0;
  double _speedMul = 0;
  Duration _last = Duration.zero;
  bool _audioStarted = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _angles.dispose();
    _lyricProgress.dispose();
    super.dispose();
  }

  void _setTapeState(TapeState state) {
    if (state == _tapeState) return;
    setState(() => _tapeState = state);
    // The reference frame loop restarts per state change, resetting the
    // multiplier so every transition re-ramps from zero.
    _speedMul = 0;
    _handleAudio(state);
  }

  void _handleAudio(TapeState state) {
    final svc = widget.spotifyService;
    if (!svc.isConnected) return;
    switch (state) {
      case TapeState.playing:
        if (_audioStarted) {
          svc.resume();
        } else {
          _audioStarted = true;
          svc.playTape(widget.tape);
        }
      case TapeState.stopped:
        svc.pause();
      case TapeState.ff:
      case TapeState.rew:
        break;
    }
  }

  void _eject() {
    // Stop playback (and the demo sim) before leaving the player.
    widget.spotifyService.pause();
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

      final maxProgress =
          (widget.tape.lyrics.length - 1).clamp(0, 1 << 30).toDouble();
      final next = _lyricProgress.value + _speedMul * 0.25 * dt;
      if (next >= maxProgress &&
          (_tapeState == TapeState.playing || _tapeState == TapeState.ff)) {
        _lyricProgress.value = maxProgress;
        _setTapeState(TapeState.stopped);
      } else if (next <= 0 && _tapeState == TapeState.rew) {
        _lyricProgress.value = 0;
        _setTapeState(TapeState.stopped);
      } else {
        _lyricProgress.value = next.clamp(0.0, maxProgress);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeAnim =
        ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;
    final headerAnim = CurvedAnimation(
        parent: routeAnim, curve: const Interval(0.3, 1, curve: Curves.easeOutCubic));
    final panelAnim = CurvedAnimation(
        parent: routeAnim, curve: const Interval(0.4, 1, curve: Curves.easeOutCubic));

    return Scaffold(
      body: VintageBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                        tape: widget.tape,
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
                  tag: 'tape_${widget.tape.id}',
                  flightShuttleBuilder: cassetteFlightShuttle(widget.tape),
                  child: _PlayerCassette(tape: widget.tape, angles: _angles),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: FadeTransition(
                  opacity: panelAnim,
                  child: FractionallySizedBox(
                    widthFactor: 0.88,
                    child: VintageLyrics(
                      lyrics: widget.tape.lyrics,
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
                const SizedBox(height: 28),
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
