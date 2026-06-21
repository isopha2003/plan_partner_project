import 'package:drift/drift.dart';

import 'block_templates_table.dart';
import 'recurrence_rules_table.dart';

/// A scheduled instance of a BlockTemplate placed on the calendar.
class Blocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  // All display info (title, color) lives on the template.
  IntColumn get blockTemplateId =>
      integer().references(BlockTemplates, #id)();
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
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
