import 'package:flutter_riverpod/flutter_riverpod.dart';

class PomodoroSettings {
  final bool enabled;
  final int workMinutes;  // 1–90
  final int breakMinutes; // 1–60

  const PomodoroSettings({
    this.enabled = false,
    this.workMinutes = 25,
    this.breakMinutes = 5,
  });

  PomodoroSettings copyWith({
    bool? enabled,
    int? workMinutes,
    int? breakMinutes,
  }) =>
      PomodoroSettings(
        enabled: enabled ?? this.enabled,
        workMinutes: workMinutes ?? this.workMinutes,
        breakMinutes: breakMinutes ?? this.breakMinutes,
      );
}

class PomodoroNotifier extends Notifier<PomodoroSettings> {
  @override
  PomodoroSettings build() => const PomodoroSettings();

  void toggle() => state = state.copyWith(enabled: !state.enabled);

  void setWorkMinutes(int minutes) =>
      state = state.copyWith(workMinutes: minutes.clamp(1, 90));

  void setBreakMinutes(int minutes) =>
      state = state.copyWith(breakMinutes: minutes.clamp(1, 60));
}

final pomodoroProvider =
    NotifierProvider<PomodoroNotifier, PomodoroSettings>(PomodoroNotifier.new);
