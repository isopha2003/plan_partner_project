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
}
