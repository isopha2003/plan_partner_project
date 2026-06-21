/// Tracks how long the timer has been in manuallyPaused state.
///
/// Clock is injectable so tests can advance time without real delays.
class NeglectAlertTrigger {
  final Duration threshold;
  final DateTime Function() _clock;

  DateTime? _pausedAt;

  NeglectAlertTrigger({
    required this.threshold,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Call when the timer enters manuallyPaused.
  void onManualStop() => _pausedAt = _clock();

  /// Call when the timer exits manuallyPaused (start or reset).
  void onResume() => _pausedAt = null;

  /// True if the timer has been manually paused for at least [threshold].
  bool get isNeglected {
    if (_pausedAt == null) return false;
    return _clock().difference(_pausedAt!) >= threshold;
  }

  /// How long the timer has been manually paused, or null if not paused.
  Duration? get neglectedDuration {
    if (_pausedAt == null) return null;
    return _clock().difference(_pausedAt!);
  }
}
