import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/domain/timer/timer_status.dart';
import 'package:planner_app/presentation/providers/pomodoro_provider.dart';
import 'package:planner_app/presentation/providers/timer_provider.dart';
import 'package:planner_app/presentation/screens/pomodoro_settings_screen.dart';

/// Timer screen: shows elapsed time and lets the user start/stop/reset.
/// Wires directly to [timerProvider] from Phase 2.
class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(timerProvider);
    final notifier = ref.read(timerProvider.notifier);
    // pomo is used for the AppBar icon color; keep below snap/notifier

    final pomo = ref.watch(pomodoroProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('타이머'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.timer_outlined,
              color: pomo.enabled
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: '뽀모도로 설정',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PomodoroSettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatusChip(status: snap.status),
            const SizedBox(height: 28),
            // Elapsed time display
            Text(
              _fmt(snap.elapsed),
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w200,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 48),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (snap.status != TimerStatus.running)
                  _ActionButton(
                    label: '시작',
                    icon: Icons.play_arrow,
                    color: Colors.green,
                    onPressed: notifier.start,
                    wide: true,
                  )
                else
                  _ActionButton(
                    label: '정지',
                    icon: Icons.stop,
                    color: Colors.red,
                    onPressed: notifier.manualStop,
                    wide: true,
                  ),
                const SizedBox(width: 16),
                _ActionButton(
                  label: '초기화',
                  icon: Icons.refresh,
                  color: Colors.grey,
                  onPressed: notifier.reset,
                ),
              ],
            ),
            // Auto-pause hint
            if (snap.status == TimerStatus.autoPaused)
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 28, 40, 0),
                child: Text(
                  '앱이 백그라운드로 이동하여 자동 일시정지되었습니다.\n'
                  '앱으로 돌아오면 자동으로 재시작됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final TimerStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TimerStatus.running => ('실행 중', Colors.green),
      TimerStatus.autoPaused => ('자동 일시정지', Colors.orange),
      TimerStatus.manuallyPaused => ('정지됨', Colors.grey),
    };
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      backgroundColor: color,
      side: BorderSide.none,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool wide;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        minimumSize: wide ? const Size(130, 52) : const Size(110, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
