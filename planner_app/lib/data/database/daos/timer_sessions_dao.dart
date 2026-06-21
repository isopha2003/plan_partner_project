import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/timer_sessions_table.dart';

part 'timer_sessions_dao.g.dart';

@DriftAccessor(tables: [TimerSessions])
class TimerSessionsDao extends DatabaseAccessor<AppDatabase>
    with _$TimerSessionsDaoMixin {
  TimerSessionsDao(super.db);

  Future<int> startSession(int blockId, DateTime startedAt) =>
      into(timerSessions).insert(TimerSessionsCompanion(
        blockId: Value(blockId),
        startedAt: Value(startedAt),
      ));

  Future<void> endSession(int sessionId, DateTime endedAt) =>
      (update(timerSessions)..where((s) => s.id.equals(sessionId)))
          .write(TimerSessionsCompanion(endedAt: Value(endedAt)));

  Future<List<TimerSession>> getSessionsForBlock(int blockId) =>
      (select(timerSessions)
            ..where((s) => s.blockId.equals(blockId))
            ..orderBy([(s) => OrderingTerm.asc(s.startedAt)]))
          .get();

  /// All timer sessions (for attendance / stats calculation).
  Future<List<TimerSession>> getAllSessions() => select(timerSessions).get();

  /// Streams timer sessions whose startedAt falls on the given date.
  Stream<List<TimerSession>> watchSessionsForDay(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return (select(timerSessions)
          ..where((s) =>
              s.startedAt.isBiggerOrEqualValue(start) &
              s.startedAt.isSmallerOrEqualValue(end)))
        .watch();
  }
}
