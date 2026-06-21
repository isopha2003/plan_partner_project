import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting());
  tearDown(() => db.close());

  group('MoodLogsDao - 날짜별 단일 레코드 제약', () {
    test('insert mood log and retrieve by date', () async {
      await db.moodLogsDao.upsertMoodLog(const MoodLogsCompanion(
          date: Value('2026-06-21'), emoji: Value('good')));
      final log = await db.moodLogsDao.getMoodLogByDate('2026-06-21');
      expect(log, isNotNull);
      expect(log!.emoji, 'good');
    });

    test('upsert overwrites existing record for same date', () async {
      await db.moodLogsDao.upsertMoodLog(const MoodLogsCompanion(
          date: Value('2026-06-21'), emoji: Value('neutral')));
      await db.moodLogsDao.upsertMoodLog(const MoodLogsCompanion(
          date: Value('2026-06-21'), emoji: Value('happy')));

      final all = await db.moodLogsDao.getAllMoodLogs();
      expect(all.where((m) => m.date == '2026-06-21').length, 1);
      expect(all.first.emoji, 'happy');
    });

    test('different dates can each have one record', () async {
      await db.moodLogsDao.upsertMoodLog(const MoodLogsCompanion(
          date: Value('2026-06-20'), emoji: Value('tired')));
      await db.moodLogsDao.upsertMoodLog(const MoodLogsCompanion(
          date: Value('2026-06-21'), emoji: Value('good')));
      final all = await db.moodLogsDao.getAllMoodLogs();
      expect(all.length, 2);
    });

    test('non-existent date returns null', () async {
      final log = await db.moodLogsDao.getMoodLogByDate('2026-01-01');
      expect(log, isNull);
    });
  });
}
