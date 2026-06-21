import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/main.dart';
import 'package:planner_app/presentation/providers/blocks_provider.dart';
import 'package:planner_app/presentation/screens/block_edit_screen.dart';

/// Screen for managing a block's children: child time-blocks and checklist items.
class ChildrenScreen extends ConsumerWidget {
  final Block parent;
  final BlockTemplate parentTemplate;

  const ChildrenScreen({
    super.key,
    required this.parent,
    required this.parentTemplate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childBlocksAsync = ref.watch(childBlocksProvider(parent.id));
    final checklistAsync = ref.watch(checklistItemsProvider(parent.id));

    return Scaffold(
      appBar: AppBar(title: Text('${parentTemplate.title} — 자식 블록')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ── Child time-blocks ─────────────────────────────────────
          _SectionHeader(
            title: '자식 타임블록',
            onAdd: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    BlockEditScreen(initialDate: parent.startTime),
              ),
            ),
          ),
          childBlocksAsync.when(
            data: (pairs) => pairs.isEmpty
                ? const _EmptyHint('자식 타임블록이 없습니다.')
                : Column(
                    children: pairs
                        .map((p) => _ChildBlockTile(block: p.$1, template: p.$2))
                        .toList(),
                  ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('오류: $e'),
          ),
          const Divider(height: 32),

          // ── Checklist items ───────────────────────────────────────
          _SectionHeader(
            title: '체크리스트',
            onAdd: () => _addChecklistItem(context, ref),
          ),
          checklistAsync.when(
            data: (items) => items.isEmpty
                ? const _EmptyHint('체크리스트 항목이 없습니다.')
                : Column(
                    children: items
                        .map((item) => _ChecklistItemTile(item: item))
                        .toList(),
                  ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('오류: $e'),
          ),
        ],
      ),
    );
  }

  Future<void> _addChecklistItem(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('체크리스트 항목 추가'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: '항목 이름'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (confirmed != true || ctrl.text.trim().isEmpty) return;

    final existing = await ref
        .read(databaseProvider)
        .checklistItemsDao
        .getItemsByBlock(parent.id);
    await ref.read(databaseProvider).checklistItemsDao.insertItem(
          ChecklistItemsCompanion.insert(
            title: ctrl.text.trim(),
            blockId: Value(parent.id),
            sortOrder: Value(existing.length),
          ),
        );
  }
}

// ─── Child block tile ────────────────────────────────────────────────────────

class _ChildBlockTile extends ConsumerWidget {
  final Block block;
  final BlockTemplate template;

  const _ChildBlockTile({required this.block, required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(template.color);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(template.title),
        subtitle: block.startTime != null
            ? Text(_formatTime(block.startTime!, block.endTime))
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () =>
              ref.read(databaseProvider).blocksDao.deleteBlock(block.id),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                BlockEditScreen(block: block, template: template),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime start, DateTime? end) {
    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return end == null ? fmt(start) : '${fmt(start)} – ${fmt(end)}';
  }
}

// ─── Checklist item tile ─────────────────────────────────────────────────────

class _ChecklistItemTile extends ConsumerWidget {
  final ChecklistItem item;

  const _ChecklistItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      value: item.isCompleted,
      title: Text(
        item.title,
        style: item.isCompleted
            ? const TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey,
              )
            : null,
      ),
      onChanged: (v) {
        ref.read(databaseProvider).checklistItemsDao.updateItem(
              item.copyWith(isCompleted: v ?? false),
            );
      },
      secondary: IconButton(
        icon: const Icon(Icons.close, size: 18),
        onPressed: () => ref
            .read(databaseProvider)
            .checklistItemsDao
            .deleteItem(item.id),
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;

  const _SectionHeader({required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const Spacer(),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('추가'),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[500], fontSize: 13),
      ),
    );
  }
}
