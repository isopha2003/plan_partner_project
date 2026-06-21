import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:planner_app/data/database/app_database.dart';

/// Generates concrete [BlocksCompanion] instances from a [RecurrenceRule].
class RecurrenceGenerator {
  RecurrenceGenerator._();

  /// Returns a list of block companions for each occurrence of [rule] in the
  /// half-open window [from, from + daysAhead).
  ///
  /// Times-of-day are copied from [template]; only the date is shifted.
  static List<BlocksCompanion> generate({
    required RecurrenceRule rule,
    required Block template,
    required DateTime from,
    required int daysAhead,
  }) {
    final instances = <BlocksCompanion>[];

    final windowEnd = _midnight(from).add(Duration(days: daysAhead));
    final effectiveEnd = (rule.endDate != null && rule.endDate!.isBefore(windowEnd))
        ? _midnight(rule.endDate!)
        : windowEnd;

    final daysOfWeek = _parseDaysOfWeek(rule.daysOfWeek);

    var current = _midnight(from);
    while (current.isBefore(effectiveEnd)) {
      if (_matches(rule, daysOfWeek, current)) {
        instances.add(_makeCompanion(template, current, rule.id));
      }
      current = current.add(const Duration(days: 1));
    }

    return instances;
  }

  // ── matching ──────────────────────────────────────────────────────────────

  static bool _matches(
    RecurrenceRule rule,
    List<int> daysOfWeek,
    DateTime date,
  ) {
    final base = _midnight(rule.startDate);
    if (date.isBefore(base)) return false;

    switch (rule.type) {
      case 'daily':
        final daysDiff = date.difference(base).inDays;
        return daysDiff % rule.interval == 0;

      case 'weekly':
        if (daysOfWeek.isEmpty || !daysOfWeek.contains(date.weekday)) {
          return false;
        }
        // Which calendar-week are we in relative to the base week?
        final baseMonday = _mondayOf(base);
        final currentMonday = _mondayOf(date);
        final weeksDiff = currentMonday.difference(baseMonday).inDays ~/ 7;
        return weeksDiff % rule.interval == 0;

      case 'monthly':
        if (date.day != rule.startDate.day) return false;
        final monthsDiff =
            (date.year - base.year) * 12 + (date.month - base.month);
        return monthsDiff % rule.interval == 0;

      default:
        return false;
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  static List<int> _parseDaysOfWeek(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return (jsonDecode(json) as List<dynamic>).cast<int>();
    } catch (_) {
      return [];
    }
  }

  static DateTime _midnight(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static DateTime _mondayOf(DateTime dt) {
    final day = _midnight(dt);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static BlocksCompanion _makeCompanion(
    Block template,
    DateTime date,
    int ruleId,
  ) {
    return BlocksCompanion(
      title: Value(template.title),
      color: Value(template.color),
      startTime: Value(
        template.startTime != null
            ? _copyTime(template.startTime!, date)
            : null,
      ),
      endTime: Value(
        template.endTime != null ? _copyTime(template.endTime!, date) : null,
      ),
      recurrenceRuleId: Value(ruleId),
      memo: Value(template.memo),
    );
  }

  static DateTime _copyTime(DateTime time, DateTime date) =>
      DateTime(date.year, date.month, date.day,
          time.hour, time.minute, time.second);
}
