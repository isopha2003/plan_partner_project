import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/domain/services/stats_calculator.dart';

Block _block({
  int id = 1,
  String title = '공부',
  DateTime? start,
  DateTime? end,
  bool completed = false,
}) =>
    Block(
      id: id,
      title: title,
      color: 0xFFFFFFFF,
      startTime: start,
      endTime: end,
      parentId: null,
      nextBlockId: null,
      recurrenceRuleId: null,
      memo: null,
      isCompleted: completed,
      createdAt: DateTime(2026, 6, 21),
    );

TimerSession _session({
  int id = 1,
  int blockId = 1,
  required DateTime start,
  DateTime? end,
}) =>
    TimerSession(
      id: id,
      blockId: blockId,
      startedAt: start,
      endedAt: end,
    );

ChecklistItem _item({int id = 1, bool completed = false}) => ChecklistItem(
      id: id,
      title: '항목',
      isCompleted: completed,
      parentItemId: null,
      blockId: 1,
      sortOrder: 0,
      createdAt: DateTime(2026, 6, 21),
    );

void main() {
  group('StatsCalculator - 목표 대비 실제 시간 비율', () {
    test('100% ratio when actual equals goal', () {
      final block = _block(
        start: DateTime(2026, 6, 21, 9, 0),
        end: DateTime(2026, 6, 21, 10, 0),
      );
      final sessions = [
        _session(
          start: DateTime(2026, 6, 21, 9, 0),
          end: DateTime(2026, 6, 21, 10, 0),
        ),
      ];
      expect(StatsCalculator.goalActualRatio(block: block, sessions: sessions),
          closeTo(1.0, 0.001));
    });

    test('50% ratio when actual is half of goal', () {
      final block = _block(
        start: DateTime(2026, 6, 21, 9, 0),
        end: DateTime(2026, 6, 21, 11, 0), // 2h goal
      );
      final sessions = [
        _session(
          start: DateTime(2026, 6, 21, 9, 0),
          end: DateTime(2026, 6, 21, 10, 0), // 1h actual
        ),
      ];
      expect(StatsCalculator.goalActualRatio(block: block, sessions: sessions),
          closeTo(0.5, 0.001));
    });

    test('running session (no endedAt) is excluded from ratio', () {
      final block = _block(
        start: DateTime(2026, 6, 21, 9, 0),
        end: DateTime(2026, 6, 21, 10, 0),
      );
      final sessions = [_session(start: DateTime(2026, 6, 21, 9, 0))]; // still running
      expect(StatsCalculator.goalActualRatio(block: block, sessions: sessions),
          closeTo(0.0, 0.001));
    });

    test('block without scheduled time returns 0.0', () {
      final block = _block();
      expect(
          StatsCalculator.goalActualRatio(block: block, sessions: []), 0.0);
    });
  });

  group('StatsCalculator - 체크리스트 달성률', () {
    test('empty list returns 0.0', () {
      expect(StatsCalculator.checklistCompletionRate([]), 0.0);
    });

    test('all completed returns 1.0', () {
      final items = [
        _item(id: 1, completed: true),
        _item(id: 2, completed: true),
      ];
      expect(StatsCalculator.checklistCompletionRate(items), 1.0);
    });

    test('half completed returns 0.5', () {
      final items = [
        _item(id: 1, completed: true),
        _item(id: 2, completed: false),
      ];
      expect(StatsCalculator.checklistCompletionRate(items), 0.5);
    });
  });

  group('StatsCalculator - 잔디(출석) 데이터 집계', () {
    test('completed block appears in correct date bucket', () {
      final blocks = [
        _block(
          id: 1,
          start: DateTime(2026, 6, 21, 9, 0),
          end: DateTime(2026, 6, 21, 10, 0),
          completed: true,
        ),
      ];
      final attendance =
          StatsCalculator.calculateAttendance(blocks: blocks, sessions: []);
      expect(attendance.containsKey('2026-06-21'), true);
      expect(attendance['2026-06-21']!.completedBlocks, 1);
      expect(attendance['2026-06-21']!.totalBlocks, 1);
    });

    test('timer session duration accumulates per date', () {
      final sessions = [
        _session(
          id: 1,
          start: DateTime(2026, 6, 21, 9, 0),
          end: DateTime(2026, 6, 21, 10, 0),
        ),
        _session(
          id: 2,
          start: DateTime(2026, 6, 21, 11, 0),
          end: DateTime(2026, 6, 21, 11, 30),
        ),
      ];
      final attendance = StatsCalculator.calculateAttendance(
          blocks: [], sessions: sessions);
      expect(attendance['2026-06-21']!.totalFocusTime,
          const Duration(hours: 1, minutes: 30));
    });

    test('different dates are bucketed separately', () {
      final blocks = [
        _block(id: 1, start: DateTime(2026, 6, 20, 9, 0), completed: true),
        _block(id: 2, start: DateTime(2026, 6, 21, 9, 0), completed: false),
      ];
      final attendance =
          StatsCalculator.calculateAttendance(blocks: blocks, sessions: []);
      expect(attendance['2026-06-20']!.completedBlocks, 1);
      expect(attendance['2026-06-21']!.completedBlocks, 0);
    });

    test('block without startTime is skipped', () {
      final blocks = [_block(id: 1)]; // no startTime
      final attendance =
          StatsCalculator.calculateAttendance(blocks: blocks, sessions: []);
      expect(attendance.isEmpty, true);
    });
  });
}
