import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/presentation/providers/blocks_provider.dart';
import 'package:planner_app/presentation/widgets/block_check_tile.dart';

/// List-mode body for the calendar screen.
///
/// Queries all top-level blocks in [from, to] with a single stream,
/// then groups them by date and renders one section per day.
/// Works for day / week / month / year tab modes.
class CalendarListView extends ConsumerWidget {
  final DateTime from;
  final DateTime to;

  const CalendarListView({
    super.key,
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocksAsync = ref.watch(blocksInRangeProvider((from, to)));

    return blocksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (pairs) {
        // Group by YYYY-MM-DD string key (preserves sort order).
        final grouped = <String, List<dynamic>>{};
        for (final pair in pairs) {
          final start = pair.$1.startTime;
          if (start == null) continue;
          final key = _dateKey(start);
          (grouped[key] ??= []).add(pair);
        }
        final sortedKeys = grouped.keys.toList()..sort();

        if (sortedKeys.isEmpty) {
          return _EmptyState(from: from, to: to);
        }

        final total = pairs.length;
        final done = pairs.where((p) => p.$1.isCompleted).length;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _ProgressHeader(done: done, total: total),
            ),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            for (final key in sortedKeys) ...[
              SliverToBoxAdapter(
                child: _DateSectionHeader(dateKey: key),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final pair = grouped[key]![i];
                    return BlockCheckTile(
                      // block.id is unique per instance — never use
                      // blockTemplateId here, which is shared across all
                      // recurring occurrences of the same template.
                      key: ValueKey(pair.$1.id),
                      block: pair.$1,
                      template: pair.$2,
                    );
                  },
                  childCount: grouped[key]!.length,
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}

// ── Date section header ───────────────────────────────────────────────────────

class _DateSectionHeader extends StatelessWidget {
  final String dateKey; // 'YYYY-MM-DD'
  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  const _DateSectionHeader({required this.dateKey});

  @override
  Widget build(BuildContext context) {
    final parts = dateKey.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    final label =
        '${date.month}월 ${date.day}일 (${_weekdays[date.weekday - 1]})';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      color: isToday
          ? Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.25)
          : Colors.grey[50],
      child: Row(
        children: [
          if (isToday)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('오늘',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isToday
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[700],
                ),
          ),
        ],
      ),
    );
  }
}

// ── Progress summary ──────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final int done;
  final int total;

  const _ProgressHeader({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : done / total;
    final pct = (ratio * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$done / $total 완료',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '$pct%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.green.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final DateTime from;
  final DateTime to;

  const _EmptyState({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final isSameDay = from.year == to.year &&
        from.month == to.month &&
        from.day == to.day;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            isSameDay
                ? '이 날짜의 블록이 없습니다.'
                : '이 기간의 블록이 없습니다.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
