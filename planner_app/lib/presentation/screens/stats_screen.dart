import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/domain/entities/day_activity.dart';
import 'package:planner_app/domain/services/stats_calculator.dart';
import 'package:planner_app/presentation/providers/blocks_provider.dart';

/// Statistics screen — built up incrementally:
///   Task 3: 출석 잔디 뷰 (_GrassSection)
///   Task 4: 오늘의 통계 (_TodayStatsSection)
///   Task 5: 미완료 작업 (_UnfinishedSection)
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: ListView(
        children: const [
          _GrassSection(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Grass (attendance) section ────────────────────────────────────────────────

class _GrassSection extends ConsumerWidget {
  const _GrassSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocksAsync = ref.watch(allBlocksProvider);
    final sessionsAsync = ref.watch(allSessionsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('출석 잔디',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            '최근 1년  ·  색이 진할수록 완료 블록 수가 많음',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          blocksAsync.when(
            loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('오류: $e'),
            data: (blockList) => sessionsAsync.when(
              loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('오류: $e'),
              data: (sessionList) {
                final activity = StatsCalculator.calculateAttendance(
                  blocks: blockList,
                  sessions: sessionList,
                );
                return _GrassGrid(activity: activity);
              },
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('적음', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              for (final color in [
                Colors.grey.shade200,
                Colors.green.shade200,
                Colors.green.shade400,
                Colors.green.shade600,
                Colors.green.shade800,
              ])
                Container(
                  width: 13,
                  height: 13,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              const SizedBox(width: 4),
              const Text('많음', style: TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrassGrid extends StatelessWidget {
  final Map<String, DayActivity> activity;
  const _GrassGrid({required this.activity});

  @override
  Widget build(BuildContext context) {
    // Start from Monday of the week 52 weeks ago.
    final today = DateTime.now();
    final rawStart = today.subtract(const Duration(days: 364));
    final monday = rawStart.subtract(Duration(days: rawStart.weekday - 1));

    const weeks = 53;
    const cellSize = 13.0;
    const gap = 2.0;

    return SizedBox(
      height: 7 * (cellSize + gap),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true, // most-recent week on the right
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int w = 0; w < weeks; w++)
              Column(
                children: [
                  for (int d = 0; d < 7; d++)
                    _GrassCell(
                      date: monday.add(Duration(days: w * 7 + d)),
                      activity: activity,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _GrassCell extends StatelessWidget {
  final DateTime date;
  final Map<String, DayActivity> activity;

  const _GrassCell({required this.date, required this.activity});

  static const _cellSize = 13.0;
  static const _gap = 2.0;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isFuture = date.isAfter(today);
    final key =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final act = isFuture ? null : activity[key];
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    return GestureDetector(
      onTap: () => _showDetail(context, date, act),
      child: Container(
        width: _cellSize,
        height: _cellSize,
        margin: const EdgeInsets.all(_gap / 2),
        decoration: BoxDecoration(
          color: _color(act),
          borderRadius: BorderRadius.circular(2),
          border: isToday
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 1.5)
              : null,
        ),
      ),
    );
  }

  Color _color(DayActivity? act) {
    if (act == null || !act.hasActivity) return Colors.grey.shade200;
    final n = act.completedBlocks;
    if (n >= 6) return Colors.green.shade800;
    if (n >= 4) return Colors.green.shade600;
    if (n >= 2) return Colors.green.shade400;
    return Colors.green.shade200;
  }

  void _showDetail(BuildContext context, DateTime date, DayActivity? act) {
    final label = '${date.year}년 ${date.month}월 ${date.day}일';
    final blocks = act?.completedBlocks ?? 0;
    final focus = act?.totalFocusTime ?? Duration.zero;
    final focusStr = focus == Duration.zero
        ? '없음'
        : '${focus.inHours > 0 ? '${focus.inHours}시간 ' : ''}'
            '${focus.inMinutes % 60}분';

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('완료 블록: $blocks개'),
            const SizedBox(height: 4),
            Text('집중 시간: $focusStr'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기')),
        ],
      ),
    );
  }
}
