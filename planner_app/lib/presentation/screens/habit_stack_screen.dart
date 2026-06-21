import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/main.dart';
import 'package:planner_app/presentation/providers/blocks_provider.dart';
import 'package:planner_app/presentation/providers/calendar_provider.dart';

/// Screen for setting the "next block" chain (habit stacking).
/// Shows the full ordered chain starting from [root], and lets the user
/// append, remove, or re-order the chain via setNextBlock().
class HabitStackScreen extends ConsumerWidget {
  final Block root;

  const HabitStackScreen({super.key, required this.root});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(calendarProvider).selectedDate;
    final blocksAsync = ref.watch(blocksForDayProvider(date));

    return Scaffold(
      appBar: AppBar(title: Text('습관 스태킹 — ${root.title}')),
      body: blocksAsync.when(
        data: (allBlocks) {
          final chain = _buildChain(root, allBlocks);
          final available = allBlocks
              .where((b) => b.id != root.id && !chain.contains(b))
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Chain display ──────────────────────────────────────
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: chain.length,
                        itemBuilder: (_, i) => _ChainTile(
                          key: ValueKey(chain[i].id),
                          block: chain[i],
                          index: i,
                          isRoot: chain[i].id == root.id,
                          onRemoveLink: i > 0
                              ? () => _removeLink(ref, chain, i)
                              : null,
                        ),
                        onReorder: (oldI, newI) =>
                            _reorder(ref, chain, oldI, newI),
                      ),
              ),

              // ── Append block picker ────────────────────────────────
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
                        children: available.map((b) {
                          return ActionChip(
                            avatar: CircleAvatar(
                              backgroundColor: Color(b.color),
                              radius: 8,
                            ),
                            label: Text(b.title,
                                style: const TextStyle(fontSize: 12)),
                            onPressed: () => _appendBlock(ref, chain, b),
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

  /// Follows nextBlockId links from [root] to build the ordered chain.
  List<Block> _buildChain(Block start, List<Block> all) {
    final byId = {for (final b in all) b.id: b};
    final chain = <Block>[];
    Block? current = start;
    final seen = <int>{};
    while (current != null && !seen.contains(current.id)) {
      chain.add(current);
      seen.add(current.id);
      final nextId = current.nextBlockId;
      current = nextId != null ? byId[nextId] : null;
    }
    return chain;
  }

  /// Appends [next] to the end of the chain.
  Future<void> _appendBlock(
      WidgetRef ref, List<Block> chain, Block next) async {
    final db = ref.read(databaseProvider);
    final tail = chain.last;
    await db.blocksDao.setNextBlock(tail.id, next.id);
  }

  /// Removes the link FROM chain[index-1] TO chain[index] (detaches chain[index]).
  Future<void> _removeLink(
      WidgetRef ref, List<Block> chain, int index) async {
    final db = ref.read(databaseProvider);
    // The predecessor points to null (breaks chain at [index])
    await db.blocksDao.setNextBlock(chain[index - 1].id, null);
  }

  /// Rebuilds the nextBlockId pointers after a ReorderableListView drag.
  Future<void> _reorder(
      WidgetRef ref, List<Block> chain, int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    // Root block (index 0) cannot be moved
    if (oldIndex == 0 || newIndex == 0) return;

    final db = ref.read(databaseProvider);
    final reordered = [...chain];
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex < oldIndex ? newIndex : newIndex - 1, item);

    // Re-wire the chain in the new order
    for (int i = 0; i < reordered.length - 1; i++) {
      await db.blocksDao.setNextBlock(reordered[i].id, reordered[i + 1].id);
    }
    await db.blocksDao.setNextBlock(reordered.last.id, null);
  }
}

class _ChainTile extends StatelessWidget {
  final Block block;
  final int index;
  final bool isRoot;
  final VoidCallback? onRemoveLink;

  const _ChainTile({
    super.key,
    required this.block,
    required this.index,
    required this.isRoot,
    this.onRemoveLink,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(block.color);
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
            title: Text(block.title),
            subtitle: block.startTime != null
                ? Text(_fmt(block.startTime!))
                : null,
            trailing: isRoot
                ? const Chip(label: Text('시작', style: TextStyle(fontSize: 11)))
                : onRemoveLink != null
                    ? IconButton(
                        icon: const Icon(Icons.link_off, size: 20),
                        tooltip: '연결 해제',
                        onPressed: onRemoveLink,
                      )
                    : null,
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
