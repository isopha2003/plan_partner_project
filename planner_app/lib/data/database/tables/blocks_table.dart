import 'package:drift/drift.dart';

import 'recurrence_rules_table.dart';

class Blocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get color => integer()();
  DateTimeColumn get startTime => dateTime().nullable()();
  DateTimeColumn get endTime => dateTime().nullable()();
  // Self-reference: 1-level nesting limit enforced in domain layer
  IntColumn get parentId => integer().nullable()();
  // Habit stacking: "finish this → start that"
  IntColumn get nextBlockId => integer().nullable()();
  IntColumn get recurrenceRuleId =>
      integer().nullable().references(RecurrenceRules, #id)();
  TextColumn get memo => text().nullable()();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
