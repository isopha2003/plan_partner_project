import 'package:drift/drift.dart' hide isNull, isNotNull, isIn;
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting());
  tearDown(() => db.close());

  group('TimerSessionsDao - 세션 시작/종료', () {
    test('start and end a session', () async {
      final blockId = await db.blocksDao.insertBlock(const BlocksCompanion(
        title: Value('집중 공부'),
        color: Value(0xFF9C27B0),
      ));

      final start = DateTime(2026, 6, 21, 10, 0);
      final end = DateTime(2026, 6, 21, 10, 50);

      final sessionId =
          await db.timerSessionsDao.startSession(blockId, start);
      await db.timerSessionsDao.endSession(sessionId, end);

      final sessions =
          await db.timerSessionsDao.getSessionsForBlock(blockId);
      expect(sessions.length, 1);
      expect(sessions.first.startedAt, start);
      expect(sessions.first.endedAt, end);
    });

    test('running session has null endedAt', () async {
      final blockId = await db.blocksDao.insertBlock(const BlocksCompanion(
        title: Value('현재 진행중'),
        color: Value(0xFFFFFFFF),
      ));
      final start = DateTime(2026, 6, 21, 14, 0);
      await db.timerSessionsDao.startSession(blockId, start);

      final sessions =
          await db.timerSessionsDao.getSessionsForBlock(blockId);
      expect(sessions.first.endedAt, isNull);
    });

    test('multiple sessions for one block', () async {
      final blockId = await db.blocksDao.insertBlock(const BlocksCompanion(
        title: Value('반복 집중'),
        color: Value(0xFFFFFFFF),
      ));
      await db.timerSessionsDao
          .startSession(blockId, DateTime(2026, 6, 21, 9, 0));
      await db.timerSessionsDao
          .startSession(blockId, DateTime(2026, 6, 21, 11, 0));

      final sessions =
          await db.timerSessionsDao.getSessionsForBlock(blockId);
      expect(sessions.length, 2);
    });
  });
}
