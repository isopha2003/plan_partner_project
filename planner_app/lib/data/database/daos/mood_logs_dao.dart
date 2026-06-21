import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/mood_logs_table.dart';

part 'mood_logs_dao.g.dart';

@DriftAccessor(tables: [MoodLogs])
class MoodLogsDao extends DatabaseAccessor<AppDatabase>
    with _$MoodLogsDaoMixin {
  MoodLogsDao(super.db);

  // date must be 'YYYY-MM-DD'. Replaces existing record for the same date.
  Future<int> upsertMoodLog(MoodLogsCompanion log) => into(moodLogs).insert(
        log,
        onConflict: DoUpdate((_) => log, target: [moodLogs.date]),
      );

  Future<MoodLog?> getMoodLogByDate(String date) =>
      (select(moodLogs)..where((m) => m.date.equals(date))).getSingleOrNull();

  Stream<MoodLog?> watchMoodLogByDate(String date) =>
      (select(moodLogs)..where((m) => m.date.equals(date)))
          .watchSingleOrNull();

  Future<List<MoodLog>> getAllMoodLogs() => select(moodLogs).get();
}
