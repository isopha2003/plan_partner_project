enum TimerStatus {
  /// User pressed Start — clock is ticking.
  running,

  /// App went to background while timer was running — paused automatically.
  /// Foreground return WILL resume automatically.
  autoPaused,

  /// User explicitly pressed Stop.
  /// Foreground/background transitions have NO effect on this state.
  manuallyPaused,
}
