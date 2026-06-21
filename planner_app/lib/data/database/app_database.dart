import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/block_templates_dao.dart';
import 'daos/blocks_dao.dart';
import 'daos/checklist_items_dao.dart';
import 'daos/deadline_tasks_dao.dart';
import 'daos/mood_logs_dao.dart';
import 'daos/recurrence_rules_dao.dart';
import 'daos/tags_dao.dart';
import 'daos/templates_dao.dart';
import 'daos/timer_sessions_dao.dart';
import 'tables/block_tags_table.dart';
import 'tables/block_templates_table.dart';
import 'tables/blocks_table.dart';
import 'tables/checklist_items_table.dart';
import 'tables/deadline_tasks_table.dart';
import 'tables/mood_logs_table.dart';
import 'tables/recurrence_rules_table.dart';
import 'tables/tags_table.dart';
import 'tables/template_blocks_table.dart';
import 'tables/templates_table.dart';
import 'tables/timer_sessions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    // BlockTemplates must come before Blocks/BlockTags (FK target)
    BlockTemplates,
    Blocks,
    ChecklistItems,
    Tags,
    BlockTags,
    TimerSessions,
    RecurrenceRules,
    Templates,
    TemplateBlocks,
    DeadlineTasks,
    MoodLogs,
  ],
  daos: [
    BlockTemplatesDao,
    BlocksDao,
    ChecklistItemsDao,
    TagsDao,
    TimerSessionsDao,
    RecurrenceRulesDao,
    TemplatesDao,
    DeadlineTasksDao,
    MoodLogsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Dev-mode destructive migration: drop everything and recreate.
          // PRAGMA foreign_keys must be off to allow dropping in any order.
          await customStatement('PRAGMA foreign_keys = OFF');
          for (final table in allTables) {
            await m.drop(table);
          }
          await m.createAll();
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'planner.db'));
    return NativeDatabase.createInBackground(file);
  });
}
