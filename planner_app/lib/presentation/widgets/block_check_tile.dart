import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/main.dart';

/// Reusable list tile for a block with an inline completion checkbox.
/// Used by TodayScreen and DayListView (calendar list mode).
class BlockCheckTile extends ConsumerWidget {
  final Block block;
  final BlockTemplate template;

  const BlockCheckTile({
    super.key,
    required this.block,
    required this.template,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(template.color);
    final done = block.isCompleted;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 4,
        height: 48,
        decoration: BoxDecoration(
          color: done ? color.withValues(alpha: 0.3) : color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(
        template.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: done ? Colors.grey[400] : null,
          decoration: done ? TextDecoration.lineThrough : null,
          decorationColor: Colors.grey[400],
        ),
      ),
      subtitle: block.startTime != null && block.endTime != null
          ? Text(
              '${_fmt(block.startTime!)} – ${_fmt(block.endTime!)}',
              style: TextStyle(
                fontSize: 12,
                color: done ? Colors.grey[400] : Colors.grey[600],
              ),
            )
          : null,
      trailing: Checkbox(
        value: done,
        activeColor: color,
        onChanged: (v) => ref
            .read(databaseProvider)
            .blocksDao
            .setBlockCompleted(block.id, v ?? false),
      ),
    );
  }

  static String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
