// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deadline_tasks_dao.dart';

// ignore_for_file: type=lint
mixin _$DeadlineTasksDaoMixin on DatabaseAccessor<AppDatabase> {
  $DeadlineTasksTable get deadlineTasks => attachedDatabase.deadlineTasks;
  DeadlineTasksDaoManager get managers => DeadlineTasksDaoManager(this);
}

class DeadlineTasksDaoManager {
  final _$DeadlineTasksDaoMixin _db;
  DeadlineTasksDaoManager(this._db);
  $$DeadlineTasksTableTableManager get deadlineTasks =>
      $$DeadlineTasksTableTableManager(_db.attachedDatabase, _db.deadlineTasks);
}
