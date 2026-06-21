import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/presentation/providers/blocks_provider.dart';
import 'package:planner_app/presentation/providers/calendar_provider.dart';

/// 7-column week view. Each column shows a day's blocks as a mini list.
class WeekView extends ConsumerWidget {
  final DateTime date; // any date within the target week

  const WeekView({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monday = _mondayOf(date);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < 7; i++)
            // ValueKey(date) ensures Flutter creates a fresh element for each
            // date — prevents positional element reuse across weeks or when
            // the selected date changes within the same week.
            _DayColumn(
              key: ValueKey(monday.add(Duration(days: i))),
              date: monday.add(Duration(days: i)),
            ),
        ],
      ),
    );
  }

  static DateTime _mondayOf(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));
}

class _DayColumn extends ConsumerWidget {
  final DateTime date;
  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  static const double _colWidth = 120.0;

  // super.key required so callers can pass ValueKey(date).
  const _DayColumn({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocksAsync = ref.watch(blocksForDayProvider(date));
    final isToday = _isToday(date);
    final notifier = ref.read(calendarProvider.notifier);

    return SizedBox(
      width: _colWidth,
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              notifier.selectDate(date);
              notifier.setViewMode(CalendarViewMode.day);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isToday
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                  right: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _weekdays[date.weekday - 1],
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isToday
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isToday ? Colors.white : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minHeight: 400),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey[200]!)),
            ),
            child: blocksAsync.when(
              data: (pairs) => _BlockList(pairs: pairs),
              loading: () => const SizedBox(
                height: 40,
                child:
                    Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _BlockList extends StatelessWidget {
  final List<(Block, BlockTemplate)> pairs;
  const _BlockList({required this.pairs});

  @override
  Widget build(BuildContext context) {
    if (pairs.isEmpty) return const SizedBox(height: 40);
    return Column(
      children: pairs.map((p) {
        final color = Color(p.$2.color);
        // Key uses block.id (unique per instance), not blockTemplateId
        // (shared across all recurring instances of the same template).
        return Container(
          key: ValueKey(p.$1.id),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Text(
            p.$2.title,
            style: const TextStyle(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }
}
