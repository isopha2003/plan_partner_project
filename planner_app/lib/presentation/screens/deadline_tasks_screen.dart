import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/domain/services/deadline_calculator.dart';
import 'package:planner_app/main.dart';

final _deadlineTasksProvider = StreamProvider<List<DeadlineTask>>(
  (ref) => ref
      .watch(databaseProvider)
      .deadlineTasksDao
      .watchAllTasksSortedByDeadline(),
);

/// Deadline task management screen — create, complete, delete, and (Task 6)
/// convert to a time block.
class DeadlineTasksScreen extends ConsumerWidget {
  const DeadlineTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(_deadlineTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('마감 작업'),
        centerTitle: true,
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (tasks) => tasks.isEmpty
            ? _emptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: tasks.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (_, i) => _TaskTile(task: tasks[i]),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'deadline_fab',
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  static Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              '등록된 마감 작업이 없습니다.\n+ 버튼으로 추가해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );

  Future<void> _showCreateDialog(
      BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    DateTime? deadline;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('마감 작업 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '작업 이름'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      deadline == null
                          ? '마감일 미설정'
                          : '마감일: ${_fmtDate(deadline!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 365)),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => deadline = picked);
                    },
                    child: const Text('날짜 선택'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소')),
            TextButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty || deadline == null) return;
                ref.read(databaseProvider).deadlineTasksDao.insertTask(
                      DeadlineTasksCompanion.insert(
                        title: titleCtrl.text.trim(),
                        deadlineDate: deadline!,
                      ),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

// ── Task tile ─────────────────────────────────────────────────────────────────

class _TaskTile extends ConsumerWidget {
  final DeadlineTask task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = DeadlineCalculator.calculateStatus(task);
    final isOverdue =
        !task.isCompleted && status == DeadlineTaskStatus.overdue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (_) => _toggleComplete(ref),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration:
                  task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : null,
            ),
          ),
          subtitle: Row(
            children: [
              Text(_fmtDate(task.deadlineDate),
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              if (!task.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? Colors.red.shade100
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOverdue ? '마감 지남' : '진행 중',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOverdue
                          ? Colors.red.shade800
                          : Colors.blue.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!task.isCompleted)
                IconButton(
                  icon: const Icon(Icons.arrow_forward,
                      color: Colors.indigo, size: 20),
                  tooltip: '타임블록으로 변환',
                  onPressed: () => _convertToBlock(context, ref),
                ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Colors.red.shade300, size: 20),
                tooltip: '삭제',
                onPressed: () => _delete(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleComplete(WidgetRef ref) {
    final db = ref.read(databaseProvider);
    if (task.isCompleted) {
      db.deadlineTasksDao
          .updateTask(task.copyWith(isCompleted: false));
    } else {
      db.deadlineTasksDao.completeTask(task.id);
    }
  }

  Future<void> _convertToBlock(BuildContext context, WidgetRef ref) async {
    // Pick a date (default: task's deadline)
    final date = await showDatePicker(
      context: context,
      initialDate: task.deadlineDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;

    // Pick start time
    final timeOfDay = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (timeOfDay == null || !context.mounted) return;

    final db = ref.read(databaseProvider);

    // Find or create a BlockTemplate matching the task title
    BlockTemplate? tmpl =
        await db.blockTemplatesDao.getTemplateByTitle(task.title);
    if (tmpl == null) {
      const defaultColor = 0xFF2196F3; // Material blue
      final newId = await db.blockTemplatesDao.insertTemplate(
        BlockTemplatesCompanion.insert(
            title: task.title, color: defaultColor),
      );
      tmpl = await db.blockTemplatesDao.getTemplateById(newId);
    }
    if (tmpl == null) return;

    final start = DateTime(
        date.year, date.month, date.day, timeOfDay.hour, timeOfDay.minute);
    final end = start.add(const Duration(hours: 1));

    await db.blocksDao.insertBlock(
      BlocksCompanion.insert(
        blockTemplateId: tmpl.id,
        startTime: Value(start),
        endTime: Value(end),
        memo: Value('마감: ${_fmtDate(task.deadlineDate)}'),
      ),
    );

    // Mark deadline task as completed after conversion
    await db.deadlineTasksDao.completeTask(task.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${task.title}" 블록이 '
            '${date.year}.${date.month}.${date.day} ${timeOfDay.format(context)}에 추가되었습니다.',
          ),
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('작업 삭제'),
        content: Text('"${task.title}"을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      ref.read(databaseProvider).deadlineTasksDao.deleteTask(task.id);
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}
