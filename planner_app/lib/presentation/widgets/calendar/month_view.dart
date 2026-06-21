import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/presentation/providers/blocks_provider.dart';
import 'package:planner_app/presentation/providers/calendar_provider.dart';

/// Monthly calendar grid. Tapping a day navigates to its day view.
class MonthView extends ConsumerWidget {
  final int year;
  final int month;

  const MonthView({super.key, required this.year, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _WeekdayHeader(),
        Expanded(child: _MonthGrid(year: year, month: month)),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  static const _labels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _labels
          .map(
            (l) => Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Text(
                  l,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  final int year;
  final int month;

  const _MonthGrid({required this.year, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstDay = DateTime(year, month, 1);
    // Offset so grid starts on Monday (weekday 1)
    final startOffset = firstDay.weekday - 1; // 0 = Monday
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.9,
      ),
      itemCount: rowCount * 7,
      itemBuilder: (context, index) {
        final dayNumber = index - startOffset + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }
        final cellDate = DateTime(year, month, dayNumber);
        return _DayCell(date: cellDate, ref: ref);
      },
    );
  }
}

class _DayCell extends ConsumerWidget {
  final DateTime date;
  final WidgetRef ref;

  const _DayCell({required this.date, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocksAsync = ref.watch(blocksForDayProvider(date));
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return GestureDetector(
      onTap: () {
        final notifier = ref.read(calendarProvider.notifier);
        notifier.selectDate(date);
        notifier.setViewMode(CalendarViewMode.day);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[100]!),
          color: isToday
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: isToday
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isToday ? Colors.white : null,
                ),
              ),
            ),
            const SizedBox(height: 2),
            blocksAsync.when(
              data: (blocks) => _BlockDots(blocks: blocks),
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockDots extends StatelessWidget {
  final List<Block> blocks;
  const _BlockDots({required this.blocks});

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) return const SizedBox.shrink();
    final dots = blocks.take(4).toList();
    return Wrap(
      spacing: 2,
      children: dots
          .map(
            (b) => Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Color(b.color),
                shape: BoxShape.circle,
              ),
            ),
          )
          .toList(),
    );
  }
}
