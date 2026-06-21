import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/presentation/providers/calendar_provider.dart';

/// 12-month year overview grid. Tapping a month navigates to its month view.
class YearView extends ConsumerWidget {
  final int year;

  const YearView({super.key, required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final isCurrentMonth =
            year == now.year && month == now.month;
        return _MiniMonth(
          year: year,
          month: month,
          isCurrentMonth: isCurrentMonth,
          onTap: () {
            final notifier = ref.read(calendarProvider.notifier);
            notifier.selectDate(DateTime(year, month, 1));
            notifier.setViewMode(CalendarViewMode.month);
          },
        );
      },
    );
  }
}

class _MiniMonth extends StatelessWidget {
  final int year;
  final int month;
  final bool isCurrentMonth;
  final VoidCallback onTap;

  const _MiniMonth({
    required this.year,
    required this.month,
    required this.isCurrentMonth,
    required this.onTap,
  });

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  static const _monthNames = [
    '1월', '2월', '3월', '4월', '5월', '6월',
    '7월', '8월', '9월', '10월', '11월', '12월',
  ];

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final offset = firstDay.weekday - 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isCurrentMonth
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[200]!,
            width: isCurrentMonth ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _monthNames[month - 1],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isCurrentMonth
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            // Weekday header row
            Row(
              children: _weekdays
                  .map(
                    (d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 2),
            // Day grid
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                ),
                itemCount: offset + daysInMonth,
                itemBuilder: (_, i) {
                  if (i < offset) return const SizedBox.shrink();
                  final day = i - offset + 1;
                  final d = DateTime(year, month, day);
                  final isToday = d.year == now.year &&
                      d.month == now.month &&
                      d.day == now.day;
                  return Center(
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: isToday
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 8,
                            color: isToday ? Colors.white : null,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
