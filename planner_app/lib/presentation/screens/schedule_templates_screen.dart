import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/main.dart';

/// Provides a reactive list of all schedule templates.
final _scheduleTemplatesProvider = StreamProvider<List<Template>>(
  (ref) => ref.watch(databaseProvider).templatesDao.watchAllTemplates(),
);

/// Screen for saving the current day's blocks as a reusable template
/// and applying saved templates to any chosen date.
class ScheduleTemplatesScreen extends ConsumerWidget {
  final DateTime date;
  const ScheduleTemplatesScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(_scheduleTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 템플릿'),
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (list) => list.isEmpty
            ? _empty(context)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _TemplateTile(
                  template: list[i],
                  targetDate: date,
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'save_template',
        icon: const Icon(Icons.save_outlined),
        label: const Text('현재 날짜 저장'),
        onPressed: () => _saveCurrentDay(context, ref),
      ),
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_view_day_outlined,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              '저장된 템플릿이 없습니다.\n아래 버튼으로 현재 날짜 일정을 저장해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );

  Future<void> _saveCurrentDay(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    // Snapshot the current day's top-level blocks
    final pairs = await db.blocksDao
        .watchTopLevelBlocksForDay(date)
        .first;
    if (!context.mounted) return;

    if (pairs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장할 블록이 없습니다.')),
      );
      return;
    }

    // Ask for a template name
    final name = await _promptName(context);
    if (name == null || name.isEmpty) return;
    if (!context.mounted) return;

    // Create Template header
    final templateId = await db.templatesDao.insertTemplate(
      TemplatesCompanion.insert(name: name, type: 'day'),
    );

    // Create TemplateBlocks
    for (int i = 0; i < pairs.length; i++) {
      final (block, tmpl) = pairs[i];
      final startOffset = block.startTime != null
          ? block.startTime!.hour * 60 + block.startTime!.minute
          : null;
      final duration = (block.startTime != null && block.endTime != null)
          ? block.endTime!.difference(block.startTime!).inMinutes
          : null;
      await db.templatesDao.insertTemplateBlock(
        TemplateBlocksCompanion.insert(
          templateId: templateId,
          title: tmpl.title,
          color: tmpl.color,
          sortOrder: Value(i),
          startOffsetMinutes: Value(startOffset),
          durationMinutes: Value(duration),
        ),
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$name" 템플릿으로 저장되었습니다.')),
      );
    }
  }

  Future<String?> _promptName(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('템플릿 이름'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '예: 루틴 하루'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('저장')),
        ],
      ),
    );
  }
}

// ── Template tile ─────────────────────────────────────────────────────────────

class _TemplateTile extends ConsumerWidget {
  final Template template;
  final DateTime targetDate;

  const _TemplateTile({required this.template, required this.targetDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule),
        title: Text(template.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle:
            Text('생성: ${_fmtDate(template.createdAt)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow_outlined,
                  color: Colors.blue),
              tooltip: '적용',
              onPressed: () => _apply(context, ref),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
              tooltip: '삭제',
              onPressed: () => _delete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _apply(BuildContext context, WidgetRef ref) async {
    final date = await showDatePicker(
      context: context,
      initialDate: targetDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final db = ref.read(databaseProvider);
    final tblocks = await db.templatesDao.getTemplateBlocks(template.id);

    for (final tb in tblocks) {
      // Find or create the matching BlockTemplate
      BlockTemplate? bt = await db.blockTemplatesDao
          .getTemplateByTitle(tb.title);
      if (bt == null) {
        final newId = await db.blockTemplatesDao.insertTemplate(
          BlockTemplatesCompanion.insert(title: tb.title, color: tb.color),
        );
        bt = await db.blockTemplatesDao.getTemplateById(newId);
      }
      if (bt == null) continue;

      final dayBase = DateTime(date.year, date.month, date.day);
      final startTime = tb.startOffsetMinutes != null
          ? dayBase.add(Duration(minutes: tb.startOffsetMinutes!))
          : null;
      final endTime = (startTime != null && tb.durationMinutes != null)
          ? startTime.add(Duration(minutes: tb.durationMinutes!))
          : null;

      await db.blocksDao.insertBlock(
        BlocksCompanion.insert(
          blockTemplateId: bt.id,
          startTime: Value(startTime),
          endTime: Value(endTime),
        ),
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${template.name}" 템플릿이 '
            '${date.year}.${date.month}.${date.day}에 적용되었습니다.',
          ),
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('템플릿 삭제'),
        content: Text('"${template.name}" 템플릿을 삭제할까요?'),
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
      ref.read(databaseProvider).templatesDao.deleteTemplate(template.id);
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}
