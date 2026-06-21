import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/presentation/providers/calendar_provider.dart';
import 'package:planner_app/presentation/screens/block_edit_screen.dart';
import 'package:planner_app/presentation/widgets/calendar/day_view.dart';
import 'package:planner_app/presentation/widgets/calendar/week_view.dart';
import 'package:planner_app/presentation/widgets/calendar/month_view.dart';
import 'package:planner_app/presentation/widgets/calendar/year_view.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarProvider);
    final notifier = ref.read(calendarProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title(state),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: notifier.goToPrevious,
          tooltip: '이전',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: notifier.goToToday,
            tooltip: '오늘',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: notifier.goToNext,
            tooltip: '다음',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SegmentedButton<CalendarViewMode>(
              segments: const [
                ButtonSegment(value: CalendarViewMode.day, label: Text('일')),
                ButtonSegment(value: CalendarViewMode.week, label: Text('주')),
                ButtonSegment(value: CalendarViewMode.month, label: Text('월')),
                ButtonSegment(value: CalendarViewMode.year, label: Text('년')),
              ],
              selected: {state.viewMode},
              onSelectionChanged: (s) => notifier.setViewMode(s.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey('${state.viewMode}-${state.selectedDate}'),
          child: _buildBody(state),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'cal_fab',
        onPressed: () => _openCreateBlock(context, state.selectedDate),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(CalendarState state) {
    final d = state.selectedDate;
    return switch (state.viewMode) {
      CalendarViewMode.day => DayView(date: d),
      CalendarViewMode.week => WeekView(date: d),
      CalendarViewMode.month => MonthView(year: d.year, month: d.month),
      CalendarViewMode.year => YearView(year: d.year),
    };
  }

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  String _title(CalendarState state) {
    final d = state.selectedDate;
    return switch (state.viewMode) {
      CalendarViewMode.day =>
        '${d.year}년 ${d.month}월 ${d.day}일 (${_weekdays[d.weekday - 1]})',
      CalendarViewMode.week => () {
          final mon = d.subtract(Duration(days: d.weekday - 1));
          final sun = mon.add(const Duration(days: 6));
          return '${mon.month}/${mon.day} – ${sun.month}/${sun.day}';
        }(),
      CalendarViewMode.month => '${d.year}년 ${d.month}월',
      CalendarViewMode.year => '${d.year}년',
    };
  }

  void _openCreateBlock(BuildContext context, DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlockEditScreen(initialDate: date),
      ),
    );
  }
}
