import 'timer_status.dart';

/// Pure state machine for the timer.
///
/// Clock is injectable so unit tests can control time without real delays.
class TimerMachine {
  final DateTime Function() _clock;

  TimerStatus _status = TimerStatus.manuallyPaused;
  DateTime? _sessionStart; // when the current running session began
  Duration _accumulated = Duration.zero; // time from all previous sessions

  TimerMachine({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  TimerStatus get status => _status;

  Duration get elapsed {
    if (_status == TimerStatus.running && _sessionStart != null) {
      return _accumulated + _clock().difference(_sessionStart!);
    }
    return _accumulated;
  }

  // ── user actions ──────────────────────────────────────────────────────────

  /// User taps Start.
  void start() {
    if (_status == TimerStatus.running) return;
    _sessionStart = _clock();
    _status = TimerStatus.running;
  }

  /// User taps Stop explicitly.
  void manualStop() {
    _commitSession();
    _status = TimerStatus.manuallyPaused;
  }

  /// Reset accumulated time and enter manuallyPaused.
  void reset() {
    _commitSession();
    _accumulated = Duration.zero;
    _status = TimerStatus.manuallyPaused;
  }

  // ── lifecycle events ──────────────────────────────────────────────────────

  /// Called when the app moves to background (AppLifecycleState.paused).
  /// Only affects [TimerStatus.running] — manuallyPaused is untouched.
  void onAppBackgrounded() {
    if (_status == TimerStatus.running) {
      _commitSession();
      _status = TimerStatus.autoPaused;
    }
    // manuallyPaused: intentionally ignored
  }

  /// Called when the app returns to foreground (AppLifecycleState.resumed).
  /// Only [TimerStatus.autoPaused] resumes — manuallyPaused is untouched.
  void onAppForegrounded() {
    if (_status == TimerStatus.autoPaused) {
      _sessionStart = _clock();
      _status = TimerStatus.running;
    }
    // manuallyPaused: intentionally ignored — this is the KEY rule
  }

  // ── private ───────────────────────────────────────────────────────────────

  void _commitSession() {
    if (_sessionStart != null) {
      _accumulated += _clock().difference(_sessionStart!);
      _sessionStart = null;
    }
  }
}
