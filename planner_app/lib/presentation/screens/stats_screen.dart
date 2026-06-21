import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/domain/entities/day_activity.dart';
import 'package:planner_app/domain/services/stats_calculator.dart';
import 'package:planner_app/main.dart';
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
          Divider(height: 32),
          _TodayStatsSection(),
          Divider(height: 32),
          _UnfinishedSection(),
          SizedBox(height: 32),
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

// ── Today's stats section ─────────────────────────────────────────────────────

class _TodayStatsSection extends ConsumerWidget {
  const _TodayStatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final blocksAsync = ref.watch(blocksForDayProvider(today));
    final sessionsAsync = ref.watch(sessionsForDayProvider(today));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘의 통계',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          blocksAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('오류: $e'),
            data: (pairs) {
              final total = pairs.length;
              final completed = pairs.where((p) => p.$1.isCompleted).length;
              final ratio = total == 0 ? 0.0 : completed / total;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: '계획 블록',
                          value: '$total개',
                          icon: Icons.calendar_today_outlined,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: '완료 블록',
                          value: '$completed개',
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _CompletionBar(ratio: ratio, label: '오늘 완료율'),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          sessionsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
            data: (sessions) {
              final focus = sessions
                  .where((s) => s.endedAt != null)
                  .fold<Duration>(
                    Duration.zero,
                    (sum, s) => sum + s.endedAt!.difference(s.startedAt),
                  );
              return _StatCard(
                label: '오늘 집중 시간',
                value: _fmtDuration(focus),
                icon: Icons.access_time_outlined,
                color: Colors.indigo,
              );
            },
          ),
        ],
      ),
    );
  }

  static String _fmtDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}시간 ${d.inMinutes % 60}분';
    if (d.inMinutes > 0) return '${d.inMinutes}분';
    return '${d.inSeconds}초';
  }
}

// ── Shared stat widgets ───────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletionBar extends StatelessWidget {
  final double ratio;
  final String label;

  const _CompletionBar({required this.ratio, required this.label});

  @override
  Widget build(BuildContext context) {
    final pct = (ratio * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text('$pct%',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor:
                AlwaysStoppedAnimation<Color>(Colors.green.shade400),
          ),
        ),
      ],
    );
  }
}

// ── Unfinished work section ───────────────────────────────────────────────────

class _UnfinishedSection extends ConsumerWidget {
  const _UnfinishedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(incompletePastBlocksProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '아직 끝내지 못한 일',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          itemsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('오류: $e'),
            data: (pairs) {
              if (pairs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.green.shade400, size: 20),
                      const SizedBox(width: 8),
                      Text('미완료 항목이 없어요!',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 14)),
                    ],
                  ),
                );
              }
              return Column(
                children: pairs
                    .map((p) =>
                        _UnfinishedTile(block: p.$1, template: p.$2))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UnfinishedTile extends ConsumerWidget {
  final Block block;
  final BlockTemplate template;

  const _UnfinishedTile({required this.block, required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(template.color);
    final start = block.startTime;
    final dateStr = start == null
        ? ''
        : '${start.year}.${start.month.toString().padLeft(2, '0')}.${start.day.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(template.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: dateStr.isNotEmpty
            ? Text(dateStr, style: const TextStyle(fontSize: 12))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.check_circle_outline,
                  color: Colors.green.shade600, size: 22),
              tooltip: '완료 처리',
              onPressed: () => ref
                  .read(databaseProvider)
                  .blocksDao
                  .updateBlock(block.copyWith(isCompleted: true)),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Colors.red.shade300, size: 22),
              tooltip: '삭제',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('블록 삭제'),
        content: Text('\'${template.title}\' 블록을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      ref.read(databaseProvider).blocksDao.deleteBlock(block.id);
    }
  }
}
