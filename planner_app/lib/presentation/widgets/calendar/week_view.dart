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
            _DayColumn(date: monday.add(Duration(days: i))),
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

  const _DayColumn({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocksAsync = ref.watch(blocksForDayProvider(date));
    final isToday = _isToday(date);
    final notifier = ref.read(calendarProvider.notifier);

    return SizedBox(
      width: _colWidth,
      child: Column(
        children: [
          // Day header
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
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
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
          // Block list
          Container(
            constraints: const BoxConstraints(minHeight: 400),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey[200]!)),
            ),
            child: blocksAsync.when(
              data: (blocks) => _BlockList(blocks: blocks),
              loading: () => const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
  final List<Block> blocks;
  const _BlockList({required this.blocks});

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return const SizedBox(height: 40);
    }
    return Column(
      children: blocks.map((b) {
        final color = Color(b.color);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Text(
            b.title,
            style: const TextStyle(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }
}
