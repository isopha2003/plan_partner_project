import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/domain/timer/neglect_alert_trigger.dart';

void main() {
  group('NeglectAlertTrigger - 방치 알림 트리거', () {
    late DateTime fakeNow;
    late NeglectAlertTrigger trigger;

    setUp(() {
      fakeNow = DateTime(2026, 6, 21, 10, 0);
      trigger = NeglectAlertTrigger(
        threshold: const Duration(minutes: 5),
        clock: () => fakeNow,
      );
    });

    test('not neglected before manual stop', () {
      expect(trigger.isNeglected, false);
      expect(trigger.neglectedDuration, isNull);
    });

    test('not neglected immediately after manual stop', () {
      trigger.onManualStop();
      expect(trigger.isNeglected, false);
    });

    test('neglected after threshold has passed', () {
      trigger.onManualStop();
      fakeNow = fakeNow.add(const Duration(minutes: 5));
      expect(trigger.isNeglected, true);
    });

    test('not yet neglected just before threshold', () {
      trigger.onManualStop();
      fakeNow = fakeNow.add(const Duration(minutes: 4, seconds: 59));
      expect(trigger.isNeglected, false);
    });

    test('neglectedDuration returns elapsed time since manual stop', () {
      trigger.onManualStop();
      fakeNow = fakeNow.add(const Duration(minutes: 3));
      expect(trigger.neglectedDuration, const Duration(minutes: 3));
    });

    test('onResume clears the neglect state', () {
      trigger.onManualStop();
      fakeNow = fakeNow.add(const Duration(minutes: 10));
      trigger.onResume();
      expect(trigger.isNeglected, false);
      expect(trigger.neglectedDuration, isNull);
    });

    test('neglect resets and restarts after resume + new manual stop', () {
      trigger.onManualStop();
      fakeNow = fakeNow.add(const Duration(minutes: 10));
      trigger.onResume();

      // Start a fresh neglect cycle
      fakeNow = fakeNow.add(const Duration(minutes: 1));
      trigger.onManualStop();
      expect(trigger.isNeglected, false); // only 1 min since new stop

      fakeNow = fakeNow.add(const Duration(minutes: 5));
      expect(trigger.isNeglected, true);
    });
  });
}
