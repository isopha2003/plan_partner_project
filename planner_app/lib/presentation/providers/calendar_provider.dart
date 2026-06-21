import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CalendarViewMode { day, week, month, year }

class CalendarState {
  final DateTime selectedDate;
  final CalendarViewMode viewMode;
  final bool isListView;

  const CalendarState({
    required this.selectedDate,
    required this.viewMode,
    this.isListView = false,
  });

  CalendarState copyWith({
    DateTime? selectedDate,
    CalendarViewMode? viewMode,
    bool? isListView,
  }) =>
      CalendarState(
        selectedDate: selectedDate ?? this.selectedDate,
        viewMode: viewMode ?? this.viewMode,
        isListView: isListView ?? this.isListView,
      );
}

class CalendarNotifier extends Notifier<CalendarState> {
  @override
  CalendarState build() {
    final now = DateTime.now();
    return CalendarState(
      selectedDate: DateTime(now.year, now.month, now.day),
      viewMode: CalendarViewMode.day,
    );
  }

  void selectDate(DateTime date) =>
      state = state.copyWith(
        selectedDate: DateTime(date.year, date.month, date.day),
      );

  void setViewMode(CalendarViewMode mode) =>
      state = state.copyWith(viewMode: mode);

  void toggleListView() =>
      state = state.copyWith(isListView: !state.isListView);

  void goToToday() {
    final now = DateTime.now();
    state = state.copyWith(
      selectedDate: DateTime(now.year, now.month, now.day),
    );
  }

  void goToPrevious() {
    final d = state.selectedDate;
    state = state.copyWith(
      selectedDate: switch (state.viewMode) {
        CalendarViewMode.day => d.subtract(const Duration(days: 1)),
        CalendarViewMode.week => d.subtract(const Duration(days: 7)),
        CalendarViewMode.month => DateTime(d.year, d.month - 1, 1),
        CalendarViewMode.year => DateTime(d.year - 1, 1, 1),
      },
    );
  }

  void goToNext() {
    final d = state.selectedDate;
    state = state.copyWith(
      selectedDate: switch (state.viewMode) {
        CalendarViewMode.day => d.add(const Duration(days: 1)),
        CalendarViewMode.week => d.add(const Duration(days: 7)),
        CalendarViewMode.month => DateTime(d.year, d.month + 1, 1),
        CalendarViewMode.year => DateTime(d.year + 1, 1, 1),
      },
    );
  }
}

final calendarProvider =
    NotifierProvider<CalendarNotifier, CalendarState>(CalendarNotifier.new);
