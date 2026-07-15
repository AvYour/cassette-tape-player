import 'dart:async';

/// Collapses a burst of calls into one: each [run] restarts the quiet-period
/// timer, and only the newest action fires once the burst stops. Used to keep
/// a dragged volume knob from flooding the Spotify Web API.
class Debouncer {
  final Duration duration;
  Timer? _timer;

  Debouncer(this.duration);

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
