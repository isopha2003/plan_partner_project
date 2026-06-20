import 'package:drift/drift.dart';

import 'blocks_table.dart';

class TimerSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get blockId => integer().references(Blocks, #id)();
  DateTimeColumn get startedAt => dateTime()();
  // null while session is still running
  DateTimeColumn get endedAt => dateTime().nullable()();
}
