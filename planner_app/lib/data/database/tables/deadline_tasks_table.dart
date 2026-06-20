import 'package:drift/drift.dart';

class DeadlineTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get deadlineDate => dateTime()();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  TextColumn get memo => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
