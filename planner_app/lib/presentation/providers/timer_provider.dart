import 'dart:async' as async;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:planner_app/domain/timer/neglect_alert_trigger.dart';
import 'package:planner_app/domain/timer/timer_machine.dart';
import 'package:planner_app/domain/timer/timer_status.dart';

/// Snapshot of the timer that the UI observes.
class TimerSnapshot {
  final TimerStatus status;
  final Duration elapsed;

  const TimerSnapshot({
    required this.status,
    this.elapsed = Duration.zero,
  });
}

/// Riverpod notifier that wraps [TimerMachine] and bridges
/// [AppLifecycleState] → timer state transitions.
class TimerNotifier extends Notifier<TimerSnapshot>
    with WidgetsBindingObserver {
  late final TimerMachine _machine;
  late final NeglectAlertTrigger _neglect;
  async.Timer? _ticker;
  async.Timer? _neglectTimer;

  static const _neglectThreshold = Duration(minutes: 5);

  @override
  TimerSnapshot build() {
    _machine = TimerMachine();
    _neglect = NeglectAlertTrigger(threshold: _neglectThreshold);

    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _ticker?.cancel();
      _neglectTimer?.cancel();
    });

    return _snap();
  }

  // ── user actions ──────────────────────────────────────────────────────────

  void start() {
    _machine.start();
    _neglect.onResume();
    _neglectTimer?.cancel();
    _startTicker();
    state = _snap();
  }

  void manualStop() {
    _machine.manualStop();
    _neglect.onManualStop();
    _stopTicker();
    _scheduleNeglectAlert();
    state = _snap();
  }

  void reset() {
    _machine.reset();
    _neglect.onResume();
    _neglectTimer?.cancel();
    _stopTicker();
    state = _snap();
  }

  // ── AppLifecycleState bridge ──────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App moved to background
        _machine.onAppBackgrounded();
        _stopTicker();
      case AppLifecycleState.resumed:
        // App returned to foreground
        _machine.onAppForegrounded();
        if (_machine.status == TimerStatus.running) _startTicker();
      default:
        break;
    }
    this.state = _snap();
  }

  // ── ticker & neglect ──────────────────────────────────────────────────────

  void _startTicker() {
    _ticker?.cancel();
    _ticker = async.Timer.periodic(const Duration(seconds: 1), (_) {
      state = _snap();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _scheduleNeglectAlert() {
    _neglectTimer?.cancel();
    _neglectTimer = async.Timer(_neglectThreshold, _onNeglectAlertFired);
  }

  void _onNeglectAlertFired() {
    // Placeholder — Phase 4 wires this to flutter_local_notifications.
    // At this point _neglect.isNeglected is guaranteed true.
    debugPrint('[TimerNotifier] neglect alert fired after $_neglectThreshold');
  }

  TimerSnapshot _snap() =>
      TimerSnapshot(status: _machine.status, elapsed: _machine.elapsed);
}

final timerProvider =
    NotifierProvider<TimerNotifier, TimerSnapshot>(TimerNotifier.new);
