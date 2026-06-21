import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/domain/services/deadline_calculator.dart';
import 'package:planner_app/main.dart';
import 'package:planner_app/presentation/providers/blocks_provider.dart';

// Reactive stream of today's due / overdue incomplete deadline tasks.
final _todayDeadlineProvider = StreamProvider<List<DeadlineTask>>((ref) {
  final now = DateTime.now();
  final endOfToday =
      DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  return ref
      .watch(databaseProvider)
      .deadlineTasksDao
      .watchDueTasks(endOfToday);
});

/// First tab: today's agenda — blocks with completion checkboxes + due tasks.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final todayStart =
        DateTime(today.year, today.month, today.day);
    final blocksAsync = ref.watch(blocksForDayProvider(todayStart));
    final deadlinesAsync = ref.watch(_todayDeadlineProvider);

    final dateLabel =
        '${today.year}년 ${today.month}월 ${today.day}일'
        ' (${_weekdays[today.weekday - 1]})';

    return Scaffold(
      appBar: AppBar(
        title: Text('오늘 · $dateLabel',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          // ── 오늘의 블록 ─────────────────────────────────────────────
          _SliverHeader('오늘의 블록'),
          blocksAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('오류: $e'),
            )),
            data: (pairs) {
              if (pairs.isEmpty) {
                return const SliverToBoxAdapter(child: _EmptyBlocks());
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _BlockCheckItem(
                    block: pairs[i].$1,
                    template: pairs[i].$2,
                  ),
                  childCount: pairs.length,
                ),
              );
            },
          ),

          // ── 마감 작업 ────────────────────────────────────────────────
          deadlinesAsync.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (e, st) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (tasks) {
              if (tasks.isEmpty) return const SliverToBoxAdapter(child: SizedBox(height: 24));
              return SliverMainAxisGroup(
                slivers: [
                  _SliverHeader('마감 작업'),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _DeadlineTaskItem(task: tasks[i]),
                      childCount: tasks.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SliverHeader extends StatelessWidget {
  final String title;
  const _SliverHeader(this.title);

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyBlocks extends StatelessWidget {
  const _EmptyBlocks();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 20, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              '오늘 계획된 블록이 없습니다.',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
}

// ── Block item with completion checkbox ───────────────────────────────────────

class _BlockCheckItem extends ConsumerWidget {
  final Block block;
  final BlockTemplate template;

  const _BlockCheckItem({required this.block, required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(template.color);
    final done = block.isCompleted;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 4,
        height: 48,
        decoration: BoxDecoration(
          color: done ? color.withValues(alpha: 0.3) : color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(
        template.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: done ? Colors.grey[400] : null,
          decoration: done ? TextDecoration.lineThrough : null,
          decorationColor: Colors.grey[400],
        ),
      ),
      subtitle: block.startTime != null && block.endTime != null
          ? Text(
              '${_fmt(block.startTime!)} – ${_fmt(block.endTime!)}',
              style: TextStyle(
                  fontSize: 12,
                  color: done ? Colors.grey[400] : Colors.grey[600]),
            )
          : null,
      trailing: Checkbox(
        value: done,
        activeColor: color,
        onChanged: (v) => ref
            .read(databaseProvider)
            .blocksDao
            .setBlockCompleted(block.id, v ?? false),
      ),
    );
  }

  static String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── Deadline task item ────────────────────────────────────────────────────────

class _DeadlineTaskItem extends ConsumerWidget {
  final DeadlineTask task;
  const _DeadlineTaskItem({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = DeadlineCalculator.calculateStatus(task);
    final isOverdue = status == DeadlineTaskStatus.overdue;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(
        isOverdue ? Icons.warning_amber_rounded : Icons.flag_outlined,
        color: isOverdue ? Colors.red : Colors.orange,
        size: 20,
      ),
      title: Text(task.title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isOverdue
                  ? Colors.red.shade100
                  : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isOverdue
                  ? '마감 지남 · ${_fmtDate(task.deadlineDate)}'
                  : '오늘 마감 · ${_fmtDate(task.deadlineDate)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    isOverdue ? Colors.red.shade800 : Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
      trailing: Checkbox(
        value: false,
        onChanged: (_) => ref
            .read(databaseProvider)
            .deadlineTasksDao
            .completeTask(task.id),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.month}/${d.day}';
}
