import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/domain/services/deadline_calculator.dart';

DeadlineTask _task({
  int id = 1,
  String title = '과제',
  required DateTime deadline,
  bool completed = false,
}) =>
    DeadlineTask(
      id: id,
      title: title,
      deadlineDate: deadline,
      isCompleted: completed,
      memo: null,
      createdAt: DateTime(2026, 6, 21),
    );

void main() {
  group('DeadlineCalculator - 마감 작업 상태', () {
    final today = DateTime(2026, 6, 21);

    test('deadline is today → inProgress', () {
      final task = _task(deadline: DateTime(2026, 6, 21, 23, 59));
      expect(
        DeadlineCalculator.calculateStatus(task, now: today),
        DeadlineTaskStatus.inProgress,
      );
    });

    test('deadline is tomorrow → inProgress', () {
      final task = _task(deadline: DateTime(2026, 6, 22));
      expect(
        DeadlineCalculator.calculateStatus(task, now: today),
        DeadlineTaskStatus.inProgress,
      );
    });

    test('deadline is yesterday → overdue', () {
      final task = _task(deadline: DateTime(2026, 6, 20));
      expect(
        DeadlineCalculator.calculateStatus(task, now: today),
        DeadlineTaskStatus.overdue,
      );
    });

    test('deadline long past → overdue', () {
      final task = _task(deadline: DateTime(2026, 1, 1));
      expect(
        DeadlineCalculator.calculateStatus(task, now: today),
        DeadlineTaskStatus.overdue,
      );
    });

    test('completed task is always inProgress regardless of deadline', () {
      final task = _task(deadline: DateTime(2026, 1, 1), completed: true);
      expect(
        DeadlineCalculator.calculateStatus(task, now: today),
        DeadlineTaskStatus.inProgress,
      );
    });

    test('date comparison ignores time-of-day', () {
      // deadline is 2026-06-20 at 23:59 — still past
      final task = _task(deadline: DateTime(2026, 6, 20, 23, 59));
      expect(
        DeadlineCalculator.calculateStatus(task, now: today),
        DeadlineTaskStatus.overdue,
      );
    });
  });
}
