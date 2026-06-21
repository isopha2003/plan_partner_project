import 'package:planner_app/data/database/app_database.dart';

enum DeadlineTaskStatus {
  inProgress,
  overdue,
}

class DeadlineCalculator {
  DeadlineCalculator._();

  /// Compares dates only (ignores time-of-day).
  /// A deadline is overdue if its date is strictly before today's date.
  static DeadlineTaskStatus calculateStatus(
    DeadlineTask task, {
    DateTime? now,
  }) {
    if (task.isCompleted) return DeadlineTaskStatus.inProgress;

    final ref = now ?? DateTime.now();
    final today =
        DateTime(ref.year, ref.month, ref.day);
    final deadline = DateTime(
      task.deadlineDate.year,
      task.deadlineDate.month,
      task.deadlineDate.day,
    );

    return deadline.isBefore(today)
        ? DeadlineTaskStatus.overdue
        : DeadlineTaskStatus.inProgress;
  }
}
