// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence_rules_dao.dart';

// ignore_for_file: type=lint
mixin _$RecurrenceRulesDaoMixin on DatabaseAccessor<AppDatabase> {
  $RecurrenceRulesTable get recurrenceRules => attachedDatabase.recurrenceRules;
  RecurrenceRulesDaoManager get managers => RecurrenceRulesDaoManager(this);
}

class RecurrenceRulesDaoManager {
  final _$RecurrenceRulesDaoMixin _db;
  RecurrenceRulesDaoManager(this._db);
  $$RecurrenceRulesTableTableManager get recurrenceRules =>
      $$RecurrenceRulesTableTableManager(
        _db.attachedDatabase,
        _db.recurrenceRules,
      );
}
