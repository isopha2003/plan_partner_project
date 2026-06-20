import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/recurrence_rules_table.dart';

part 'recurrence_rules_dao.g.dart';

@DriftAccessor(tables: [RecurrenceRules])
class RecurrenceRulesDao extends DatabaseAccessor<AppDatabase>
    with _$RecurrenceRulesDaoMixin {
  RecurrenceRulesDao(super.db);

  Future<int> insertRule(RecurrenceRulesCompanion rule) =>
      into(recurrenceRules).insert(rule);

  Future<RecurrenceRule?> getRuleById(int id) =>
      (select(recurrenceRules)..where((r) => r.id.equals(id)))
          .getSingleOrNull();

  Future<List<RecurrenceRule>> getAllRules() => select(recurrenceRules).get();
}
