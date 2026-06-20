import 'package:drift/drift.dart' hide isNull, isNotNull, isIn;
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting());
  tearDown(() => db.close());

  group('DeadlineTasksDao - 마감일 기준 정렬', () {
    test('tasks sorted by deadlineDate ascending', () async {
      await db.deadlineTasksDao.insertTask(DeadlineTasksCompanion(
          title: const Value('레포트 제출'),
          deadlineDate: Value(DateTime(2026, 7, 15))));
      await db.deadlineTasksDao.insertTask(DeadlineTasksCompanion(
          title: const Value('기말 발표'),
          deadlineDate: Value(DateTime(2026, 6, 25))));
      await db.deadlineTasksDao.insertTask(DeadlineTasksCompanion(
          title: const Value('독서 과제'),
          deadlineDate: Value(DateTime(2026, 7, 1))));

      final sorted =
          await db.deadlineTasksDao.getAllTasksSortedByDeadline();
      expect(sorted[0].title, '기말 발표');
      expect(sorted[1].title, '독서 과제');
      expect(sorted[2].title, '레포트 제출');
    });

    test('complete a task', () async {
      final id = await db.deadlineTasksDao.insertTask(DeadlineTasksCompanion(
          title: const Value('완료할 일'),
          deadlineDate: Value(DateTime(2026, 7, 10))));
      await db.deadlineTasksDao.completeTask(id);
      final tasks =
          await db.deadlineTasksDao.getAllTasksSortedByDeadline();
      expect(tasks.first.isCompleted, true);
    });

    test('delete a task', () async {
      final id = await db.deadlineTasksDao.insertTask(DeadlineTasksCompanion(
          title: const Value('삭제할 일'),
          deadlineDate: Value(DateTime(2026, 8, 1))));
      await db.deadlineTasksDao.deleteTask(id);
      final tasks =
          await db.deadlineTasksDao.getAllTasksSortedByDeadline();
      expect(tasks, isEmpty);
    });
  });
}
