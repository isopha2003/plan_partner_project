import 'package:flutter/material.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/presentation/screens/block_edit_screen.dart';
import 'package:planner_app/presentation/screens/children_screen.dart';

/// Compact block display. Title and color come from [template]; timing from [block].
/// Tap → edit (BlockEditScreen). Long-press → manage children (ChildrenScreen).
class BlockTile extends StatelessWidget {
  final Block block;
  final BlockTemplate template;

  const BlockTile({super.key, required this.block, required this.template});

  @override
  Widget build(BuildContext context) {
    final color = Color(template.color);
    final textColor =
        color.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlockEditScreen(block: block, template: template),
        ),
      ),
      onLongPress: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ChildrenScreen(parent: block, parentTemplate: template),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (block.startTime != null && block.endTime != null)
              Text(
                '${_fmt(block.startTime!)} – ${_fmt(block.endTime!)}',
                style: TextStyle(
                    color: textColor.withValues(alpha: 0.8), fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
