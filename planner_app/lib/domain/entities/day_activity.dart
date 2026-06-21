/// Aggregated activity data for a single calendar day — used for 잔디 view.
class DayActivity {
  final String date; // 'YYYY-MM-DD'
  final int completedBlocks;
  final int totalBlocks;
  final Duration totalFocusTime;

  const DayActivity({
    required this.date,
    this.completedBlocks = 0,
    this.totalBlocks = 0,
    this.totalFocusTime = Duration.zero,
  });

  bool get hasActivity =>
      completedBlocks > 0 || totalFocusTime > Duration.zero;

  DayActivity copyWith({
    int? completedBlocks,
    int? totalBlocks,
    Duration? totalFocusTime,
  }) =>
      DayActivity(
        date: date,
        completedBlocks: completedBlocks ?? this.completedBlocks,
        totalBlocks: totalBlocks ?? this.totalBlocks,
        totalFocusTime: totalFocusTime ?? this.totalFocusTime,
      );
}
