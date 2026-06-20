import 'package:drift/drift.dart';

class RecurrenceRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  // 'daily' | 'weekly' | 'monthly'
  TextColumn get type => text()();
  IntColumn get interval => integer().withDefault(const Constant(1))();
  // JSON array of weekday ints, e.g. "[1,3,5]" — only used for weekly
  TextColumn get daysOfWeek => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
}
