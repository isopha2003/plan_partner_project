import 'package:drift/drift.dart';

/// Reusable activity definition. Instances (Blocks) reference a template.
class BlockTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get color => integer()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
