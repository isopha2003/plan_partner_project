import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/presentation/providers/pomodoro_provider.dart';

/// Pomodoro mode configuration screen.
/// Lets the user toggle pomodoro on/off and set work/break durations.
/// Settings are held in [pomodoroProvider] and apply immediately.
class PomodoroSettingsScreen extends ConsumerWidget {
  const PomodoroSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('뽀모도로 설정')),
      body: ListView(
        children: [
          // ── Enable toggle ─────────────────────────────────────────────
          SwitchListTile(
            title: const Text('뽀모도로 모드'),
            subtitle: Text(
              settings.enabled ? '활성화됨' : '비활성화됨',
              style: TextStyle(
                color: settings.enabled ? Colors.green : Colors.grey,
              ),
            ),
            value: settings.enabled,
            onChanged: (_) => notifier.toggle(),
          ),
          const Divider(),

          // ── Work duration ─────────────────────────────────────────────
          _SectionLabel('집중 시간'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: settings.workMinutes.toDouble(),
                    min: 5,
                    max: 90,
                    divisions: 17,
                    label: '${settings.workMinutes}분',
                    onChanged: settings.enabled
                        ? (v) => notifier.setWorkMinutes(v.round())
                        : null,
                  ),
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    '${settings.workMinutes}분',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: settings.enabled ? null : Colors.grey,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Break duration ────────────────────────────────────────────
          _SectionLabel('휴식 시간'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: settings.breakMinutes.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    label: '${settings.breakMinutes}분',
                    onChanged: settings.enabled
                        ? (v) => notifier.setBreakMinutes(v.round())
                        : null,
                  ),
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    '${settings.breakMinutes}분',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: settings.enabled ? null : Colors.grey,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Summary card ──────────────────────────────────────────────
          if (settings.enabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _SummaryItem(
                        label: '집중',
                        value: '${settings.workMinutes}분',
                        icon: Icons.work_outline,
                      ),
                      const Icon(Icons.arrow_forward, size: 18),
                      _SummaryItem(
                        label: '휴식',
                        value: '${settings.breakMinutes}분',
                        icon: Icons.coffee_outlined,
                      ),
                      const Icon(Icons.arrow_forward, size: 18),
                      _SummaryItem(
                        label: '반복',
                        value: '무제한',
                        icon: Icons.loop,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
            ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
