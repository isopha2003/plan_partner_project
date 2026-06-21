import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/domain/services/recurrence_generator.dart';

// Helper to build a minimal Block (blockTemplateId=1 is a placeholder for tests).
Block _makeBlock({
  int id = 1,
  int blockTemplateId = 1,
  DateTime? startTime,
  DateTime? endTime,
  int? recurrenceRuleId,
}) =>
    Block(
      id: id,
      blockTemplateId: blockTemplateId,
      startTime: startTime,
      endTime: endTime,
      parentId: null,
      nextBlockId: null,
      recurrenceRuleId: recurrenceRuleId,
      memo: null,
      isCompleted: false,
      createdAt: DateTime(2026, 6, 21),
    );

RecurrenceRule _makeRule({
  int id = 1,
  String type = 'weekly',
  int interval = 1,
  String? daysOfWeek,
  required DateTime startDate,
  DateTime? endDate,
}) =>
    RecurrenceRule(
      id: id,
      type: type,
      interval: interval,
      daysOfWeek: daysOfWeek,
      startDate: startDate,
      endDate: endDate,
    );

void main() {
  // June 22, 2026 is a Monday (weekday == 1)
  final monday = DateTime(2026, 6, 22);

  group('RecurrenceGenerator - 반복 인스턴스 생성', () {
    test('weekly rule on Mondays generates 4 instances over 28 days', () {
      final rule = _makeRule(
        type: 'weekly',
        daysOfWeek: '[1]', // Monday
        startDate: monday,
      );
      final template = _makeBlock(
        recurrenceRuleId: rule.id,
        startTime: DateTime(2026, 6, 22, 9, 0),
        endTime: DateTime(2026, 6, 22, 10, 0),
      );

      final instances = RecurrenceGenerator.generate(
        rule: rule,
        sourceBlock: template,
        from: monday,
        daysAhead: 28,
      );

      // Expect: Jun 22, Jun 29, Jul 6, Jul 13
      expect(instances.length, 4);
    });

    test('generated instances have correct dates (Mondays)', () {
      final rule = _makeRule(
        type: 'weekly',
        daysOfWeek: '[1]',
        startDate: monday,
      );
      final template = _makeBlock(
        startTime: DateTime(2026, 6, 22, 9, 0),
        endTime: DateTime(2026, 6, 22, 10, 0),
      );

      final instances = RecurrenceGenerator.generate(
        rule: rule,
        sourceBlock: template,
        from: monday,
        daysAhead: 28,
      );

      final starts = instances.map((b) => b.startTime.value!).toList();
      expect(starts[0], DateTime(2026, 6, 22, 9, 0));
      expect(starts[1], DateTime(2026, 6, 29, 9, 0));
      expect(starts[2], DateTime(2026, 7, 6, 9, 0));
      expect(starts[3], DateTime(2026, 7, 13, 9, 0));
    });

    test('time-of-day is preserved in each generated instance', () {
      final rule = _makeRule(
        type: 'weekly',
        daysOfWeek: '[1]',
        startDate: monday,
      );
      final template = _makeBlock(
        startTime: DateTime(2026, 6, 22, 14, 30),
        endTime: DateTime(2026, 6, 22, 16, 0),
      );

      final instances = RecurrenceGenerator.generate(
        rule: rule,
        sourceBlock: template,
        from: monday,
        daysAhead: 7,
      );

      expect(instances.length, 1);
      expect(instances.first.startTime.value!.hour, 14);
      expect(instances.first.startTime.value!.minute, 30);
    });

    test('daily rule generates one instance per day', () {
      final rule = _makeRule(
        type: 'daily',
        startDate: DateTime(2026, 6, 21),
      );
      final template = _makeBlock();

      final instances = RecurrenceGenerator.generate(
        rule: rule,
        sourceBlock: template,
        from: DateTime(2026, 6, 21),
        daysAhead: 7,
      );

      expect(instances.length, 7); // half-open [Jun 21, Jun 28) = 7 days
    });

    test('endDate limits generation', () {
      final rule = _makeRule(
        type: 'weekly',
        daysOfWeek: '[1]',
        startDate: monday,
        endDate: DateTime(2026, 7, 5), // before 4th Monday (Jul 13)
      );
      final template = _makeBlock();

      final instances = RecurrenceGenerator.generate(
        rule: rule,
        sourceBlock: template,
        from: monday,
        daysAhead: 28,
      );

      // Jun 22, Jun 29 are before Jul 5; Jul 6 and beyond are excluded
      expect(instances.length, lessThanOrEqualTo(3));
    });

    test('bi-weekly rule (interval=2) generates every other Monday', () {
      final rule = _makeRule(
        type: 'weekly',
        interval: 2,
        daysOfWeek: '[1]',
        startDate: monday, // Jun 22
      );
      final template = _makeBlock();

      final instances = RecurrenceGenerator.generate(
        rule: rule,
        sourceBlock: template,
        from: monday,
        daysAhead: 28,
      );

      // Jun 22 (week 0), skip Jun 29 (week 1), Jul 6 (week 2), skip Jul 13 (week 3)
      expect(instances.length, 2);
    });
  });
}
