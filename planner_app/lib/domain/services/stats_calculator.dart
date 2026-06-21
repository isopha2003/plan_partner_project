import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/domain/entities/day_activity.dart';

class StatsCalculator {
  StatsCalculator._();

  /// Ratio of actual focused time vs planned block duration.
  ///
  /// Returns 0.0 if the block has no scheduled times.
  /// Can exceed 1.0 if the user focused longer than planned.
  static double goalActualRatio({
    required Block block,
    required List<TimerSession> sessions,
  }) {
    if (block.startTime == null || block.endTime == null) return 0.0;
    final goalSecs =
        block.endTime!.difference(block.startTime!).inSeconds;
    if (goalSecs <= 0) return 0.0;

    final actualSecs = sessions
        .where((s) => s.endedAt != null)
        .fold<int>(
          0,
          (sum, s) => sum + s.endedAt!.difference(s.startedAt).inSeconds,
        );

    return actualSecs / goalSecs;
  }

  /// Fraction of completed checklist items (0.0–1.0).
  static double checklistCompletionRate(List<ChecklistItem> items) {
    if (items.isEmpty) return 0.0;
    return items.where((i) => i.isCompleted).length / items.length;
  }

  /// Aggregates blocks and timer sessions into per-day 잔디 data.
  ///
  /// Grass credit is assigned to the day the block was *completed* (completedAt),
  /// not the day it was scheduled (startTime). Blocks without completedAt are skipped.
  /// Focus time is still keyed by session.startedAt.
  static Map<String, DayActivity> calculateAttendance({
    required List<Block> blocks,
    required List<TimerSession> sessions,
  }) {
    final result = <String, DayActivity>{};

    for (final block in blocks) {
      if (!block.isCompleted || block.completedAt == null) continue;
      final key = _dateKey(block.completedAt!);
      final current = result[key] ?? DayActivity(date: key);
      result[key] = current.copyWith(
        completedBlocks: current.completedBlocks + 1,
      );
    }

    for (final session in sessions) {
      if (session.endedAt == null) continue;
      final key = _dateKey(session.startedAt);
      final current = result[key] ?? DayActivity(date: key);
      final dur = session.endedAt!.difference(session.startedAt);
      result[key] =
          current.copyWith(totalFocusTime: current.totalFocusTime + dur);
    }

    return result;
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
