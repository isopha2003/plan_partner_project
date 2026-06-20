import 'package:drift/drift.dart';

import 'templates_table.dart';

class TemplateBlocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(Templates, #id)();
  TextColumn get title => text()();
  IntColumn get color => integer()();
  // Minutes from midnight (null = no fixed time slot)
  IntColumn get startOffsetMinutes => integer().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
