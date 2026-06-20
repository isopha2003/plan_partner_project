// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mood_logs_dao.dart';

// ignore_for_file: type=lint
mixin _$MoodLogsDaoMixin on DatabaseAccessor<AppDatabase> {
  $MoodLogsTable get moodLogs => attachedDatabase.moodLogs;
  MoodLogsDaoManager get managers => MoodLogsDaoManager(this);
}

class MoodLogsDaoManager {
  final _$MoodLogsDaoMixin _db;
  MoodLogsDaoManager(this._db);
  $$MoodLogsTableTableManager get moodLogs =>
      $$MoodLogsTableTableManager(_db.attachedDatabase, _db.moodLogs);
}
