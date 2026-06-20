import 'package:drift/drift.dart';

class MoodLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  // YYYY-MM-DD string — one record per calendar day
  TextColumn get date => text().unique()();
  TextColumn get emoji => text()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
