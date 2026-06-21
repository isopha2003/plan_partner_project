import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/domain/timer/timer_machine.dart';
import 'package:planner_app/domain/timer/timer_status.dart';

void main() {
  group('TimerMachine - 상태 전이', () {
    // Controllable fake clock
    late DateTime fakeNow;
    late TimerMachine machine;

    setUp(() {
      fakeNow = DateTime(2026, 6, 21, 10, 0, 0);
      machine = TimerMachine(clock: () => fakeNow);
    });

    // ── initial state ───────────────────────────────────────────────────────

    test('initial state is manuallyPaused with zero elapsed', () {
      expect(machine.status, TimerStatus.manuallyPaused);
      expect(machine.elapsed, Duration.zero);
    });

    // ── basic start / stop ──────────────────────────────────────────────────

    test('start transitions to running', () {
      machine.start();
      expect(machine.status, TimerStatus.running);
    });

    test('manualStop transitions to manuallyPaused', () {
      machine.start();
      machine.manualStop();
      expect(machine.status, TimerStatus.manuallyPaused);
    });

    test('elapsed accumulates while running', () {
      machine.start();
      fakeNow = fakeNow.add(const Duration(minutes: 10));
      expect(machine.elapsed, const Duration(minutes: 10));
    });

    test('elapsed freezes after manualStop', () {
      machine.start();
      fakeNow = fakeNow.add(const Duration(minutes: 5));
      machine.manualStop();
      fakeNow = fakeNow.add(const Duration(minutes: 100));
      expect(machine.elapsed, const Duration(minutes: 5));
    });

    test('elapsed accumulates across multiple start/stop cycles', () {
      machine.start();
      fakeNow = fakeNow.add(const Duration(minutes: 3));
      machine.manualStop();

      machine.start();
      fakeNow = fakeNow.add(const Duration(minutes: 7));
      machine.manualStop();

      expect(machine.elapsed, const Duration(minutes: 10));
    });

    test('reset clears elapsed and returns to manuallyPaused', () {
      machine.start();
      fakeNow = fakeNow.add(const Duration(minutes: 30));
      machine.reset();
      expect(machine.elapsed, Duration.zero);
      expect(machine.status, TimerStatus.manuallyPaused);
    });

    // ── AppLifecycleState 연동 ───────────────────────────────────────────────

    test('running → backgrounded → autoPaused', () {
      machine.start();
      machine.onAppBackgrounded();
      expect(machine.status, TimerStatus.autoPaused);
    });

    test('autoPaused → foregrounded → running', () {
      machine.start();
      machine.onAppBackgrounded();
      machine.onAppForegrounded();
      expect(machine.status, TimerStatus.running);
    });

    test('elapsed is preserved across auto-pause cycle', () {
      machine.start();
      fakeNow = fakeNow.add(const Duration(minutes: 4));
      machine.onAppBackgrounded(); // commits 4 min

      fakeNow = fakeNow.add(const Duration(hours: 1)); // background time
      machine.onAppForegrounded(); // resumes — background time NOT counted

      fakeNow = fakeNow.add(const Duration(minutes: 6));
      expect(machine.elapsed, const Duration(minutes: 10)); // 4 + 6
    });

    // ── KEY RULE: manuallyPaused is immune to lifecycle events ──────────────

    test('manuallyPaused + backgrounded → stays manuallyPaused', () {
      machine.start();
      machine.manualStop(); // manually stopped
      machine.onAppBackgrounded();
      expect(machine.status, TimerStatus.manuallyPaused);
    });

    test('manuallyPaused + foregrounded → stays manuallyPaused (KEY RULE)', () {
      machine.start();
      machine.manualStop(); // manually stopped
      machine.onAppForegrounded(); // foreground return must NOT restart
      expect(machine.status, TimerStatus.manuallyPaused);
    });

    test('manuallyPaused elapsed does not grow on foreground return', () {
      machine.start();
      fakeNow = fakeNow.add(const Duration(minutes: 5));
      machine.manualStop();
      final snapshot = machine.elapsed;

      machine.onAppForegrounded();
      fakeNow = fakeNow.add(const Duration(minutes: 10));
      expect(machine.elapsed, snapshot); // must not have grown
    });

    // ── double-start guard ──────────────────────────────────────────────────

    test('calling start while already running is a no-op', () {
      machine.start();
      fakeNow = fakeNow.add(const Duration(minutes: 2));
      machine.start(); // second start — should be ignored
      fakeNow = fakeNow.add(const Duration(minutes: 3));
      expect(machine.elapsed, const Duration(minutes: 5));
      expect(machine.status, TimerStatus.running);
    });
  });
}
