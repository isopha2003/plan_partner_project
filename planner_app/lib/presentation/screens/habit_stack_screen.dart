import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/main.dart';
import 'package:planner_app/presentation/providers/blocks_provider.dart';
import 'package:planner_app/presentation/providers/calendar_provider.dart';
import 'package:planner_app/presentation/screens/block_edit_screen.dart';

/// Screen for viewing and editing the "next block" chain (habit stacking).
class HabitStackScreen extends ConsumerWidget {
  final Block root;
  final BlockTemplate rootTemplate;

  const HabitStackScreen({
    super.key,
    required this.root,
    required this.rootTemplate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(calendarProvider).selectedDate;
    final blocksAsync = ref.watch(blocksForDayProvider(date));

    return Scaffold(
      appBar: AppBar(title: Text('습관 스태킹 — ${rootTemplate.title}')),
      body: blocksAsync.when(
        data: (allPairs) {
          final byId = {for (final p in allPairs) p.$1.id: p};
          final chain = _buildChain(root, byId);
          final chainIds = chain.map((p) => p.$1.id).toSet();
          final available =
              allPairs.where((p) => !chainIds.contains(p.$1.id)).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  '연결 순서',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: chain.isEmpty
                    ? const Center(child: Text('연결된 블록이 없습니다.'))
                    : ReorderableListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: chain.length,
                        itemBuilder: (_, i) => _ChainTile(
                          key: ValueKey(chain[i].$1.id),
                          block: chain[i].$1,
                          template: chain[i].$2,
                          index: i,
                          isRoot: chain[i].$1.id == root.id,
                          onRemoveLink: i > 0
                              ? () => _removeLink(ref, chain, i)
                              : null,
                        ),
                        onReorder: (oldI, newI) =>
                            _reorder(ref, chain, oldI, newI),
                      ),
              ),
              if (available.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '다음 블록으로 연결',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: available.map((p) {
                          return ActionChip(
                            avatar: CircleAvatar(
                              backgroundColor: Color(p.$2.color),
                              radius: 8,
                            ),
                            label: Text(p.$2.title,
                                style: const TextStyle(fontSize: 12)),
                            onPressed: () =>
                                _appendBlock(ref, chain, p.$1),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
    );
  }

  List<(Block, BlockTemplate)> _buildChain(
      Block start, Map<int, (Block, BlockTemplate)> byId) {
    final chain = <(Block, BlockTemplate)>[];
    Block? current = start;
    final seen = <int>{};
    while (current != null && !seen.contains(current.id)) {
      final pair = byId[current.id];
      if (pair == null) break;
      chain.add(pair);
      seen.add(current.id);
      final nextId = current.nextBlockId;
      current = nextId != null ? byId[nextId]?.$1 : null;
    }
    return chain;
  }

  Future<void> _appendBlock(
      WidgetRef ref, List<(Block, BlockTemplate)> chain, Block next) async {
    await ref.read(databaseProvider).blocksDao.setNextBlock(chain.last.$1.id, next.id);
  }

  Future<void> _removeLink(
      WidgetRef ref, List<(Block, BlockTemplate)> chain, int index) async {
    await ref
        .read(databaseProvider)
        .blocksDao
        .setNextBlock(chain[index - 1].$1.id, null);
  }

  Future<void> _reorder(WidgetRef ref, List<(Block, BlockTemplate)> chain,
      int oldIndex, int newIndex) async {
    if (oldIndex == newIndex || oldIndex == 0 || newIndex == 0) return;
    final db = ref.read(databaseProvider);
    final reordered = [...chain];
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex < oldIndex ? newIndex : newIndex - 1, item);

    for (int i = 0; i < reordered.length - 1; i++) {
      await db.blocksDao
          .setNextBlock(reordered[i].$1.id, reordered[i + 1].$1.id);
    }
    await db.blocksDao.setNextBlock(reordered.last.$1.id, null);
  }
}

class _ChainTile extends StatelessWidget {
  final Block block;
  final BlockTemplate template;
  final int index;
  final bool isRoot;
  final VoidCallback? onRemoveLink;

  const _ChainTile({
    super.key,
    required this.block,
    required this.template,
    required this.index,
    required this.isRoot,
    this.onRemoveLink,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(template.color);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (index > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Icon(Icons.arrow_downward,
                size: 18, color: Colors.grey[400]),
          ),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color,
              radius: 16,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: color.computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(template.title),
            subtitle: block.startTime != null
                ? Text(_fmt(block.startTime!))
                : null,
            trailing: isRoot
                ? const Chip(
                    label: Text('시작', style: TextStyle(fontSize: 11)))
                : onRemoveLink != null
                    ? IconButton(
                        icon: const Icon(Icons.link_off, size: 20),
                        tooltip: '연결 해제',
                        onPressed: onRemoveLink,
                      )
                    : null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    BlockEditScreen(block: block, template: template),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
