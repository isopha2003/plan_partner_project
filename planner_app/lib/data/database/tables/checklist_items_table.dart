import 'package:drift/drift.dart';

import 'blocks_table.dart';

class ChecklistItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  // Self-reference: unlimited nesting for checklists
  IntColumn get parentItemId => integer().nullable()();
  // Root items belong to a timeblock; child items inherit via parentItemId
  IntColumn get blockId =>
      integer().nullable().references(Blocks, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
