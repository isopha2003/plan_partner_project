// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_sessions_dao.dart';

// ignore_for_file: type=lint
mixin _$TimerSessionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BlockTemplatesTable get blockTemplates => attachedDatabase.blockTemplates;
  $RecurrenceRulesTable get recurrenceRules => attachedDatabase.recurrenceRules;
  $BlocksTable get blocks => attachedDatabase.blocks;
  $TimerSessionsTable get timerSessions => attachedDatabase.timerSessions;
  TimerSessionsDaoManager get managers => TimerSessionsDaoManager(this);
}

class TimerSessionsDaoManager {
  final _$TimerSessionsDaoMixin _db;
  TimerSessionsDaoManager(this._db);
  $$BlockTemplatesTableTableManager get blockTemplates =>
      $$BlockTemplatesTableTableManager(
        _db.attachedDatabase,
        _db.blockTemplates,
      );
  $$RecurrenceRulesTableTableManager get recurrenceRules =>
      $$RecurrenceRulesTableTableManager(
        _db.attachedDatabase,
        _db.recurrenceRules,
      );
  $$BlocksTableTableManager get blocks =>
      $$BlocksTableTableManager(_db.attachedDatabase, _db.blocks);
  $$TimerSessionsTableTableManager get timerSessions =>
      $$TimerSessionsTableTableManager(_db.attachedDatabase, _db.timerSessions);
}
