import 'package:drift/drift.dart' hide isNull, isNotNull, isIn;
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting());
  tearDown(() => db.close());

  group('RecurrenceRulesDao - 규칙 생성', () {
    test('create daily rule and retrieve', () async {
      final id = await db.recurrenceRulesDao.insertRule(
        RecurrenceRulesCompanion(
          type: const Value('daily'),
          startDate: Value(DateTime(2026, 6, 21)),
        ),
      );
      final rule = await db.recurrenceRulesDao.getRuleById(id);
      expect(rule, isNotNull);
      expect(rule!.type, 'daily');
      expect(rule.interval, 1);
      expect(rule.endDate, isNull);
    });

    test('create weekly rule with daysOfWeek', () async {
      final id = await db.recurrenceRulesDao.insertRule(
        RecurrenceRulesCompanion(
          type: const Value('weekly'),
          daysOfWeek: const Value('[1,3,5]'),
          startDate: Value(DateTime(2026, 6, 21)),
          endDate: Value(DateTime(2026, 12, 31)),
        ),
      );
      final rule = await db.recurrenceRulesDao.getRuleById(id);
      expect(rule!.type, 'weekly');
      expect(rule.daysOfWeek, '[1,3,5]');
      expect(rule.endDate, isNotNull);
    });

    test('get all rules', () async {
      await db.recurrenceRulesDao.insertRule(RecurrenceRulesCompanion(
          type: const Value('daily'),
          startDate: Value(DateTime(2026, 1, 1))));
      await db.recurrenceRulesDao.insertRule(RecurrenceRulesCompanion(
          type: const Value('monthly'),
          startDate: Value(DateTime(2026, 1, 1))));
      final all = await db.recurrenceRulesDao.getAllRules();
      expect(all.length, 2);
    });
  });
}
