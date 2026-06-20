import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/deadline_tasks_table.dart';

part 'deadline_tasks_dao.g.dart';

@DriftAccessor(tables: [DeadlineTasks])
class DeadlineTasksDao extends DatabaseAccessor<AppDatabase>
    with _$DeadlineTasksDaoMixin {
  DeadlineTasksDao(super.db);

  Future<int> insertTask(DeadlineTasksCompanion task) =>
      into(deadlineTasks).insert(task);

  Future<List<DeadlineTask>> getAllTasksSortedByDeadline() =>
      (select(deadlineTasks)
            ..orderBy([(t) => OrderingTerm.asc(t.deadlineDate)]))
          .get();

  Future<void> completeTask(int id) =>
      (update(deadlineTasks)..where((t) => t.id.equals(id)))
          .write(const DeadlineTasksCompanion(isCompleted: Value(true)));

  Future<int> deleteTask(int id) =>
      (delete(deadlineTasks)..where((t) => t.id.equals(id))).go();
}
