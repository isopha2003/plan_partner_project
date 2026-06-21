import 'package:flutter/material.dart';
import 'package:planner_app/data/database/app_database.dart';

/// Warning banner shown at the top of DayView when overlapping blocks exist.
class OverlapWarningBanner extends StatelessWidget {
  final List<(Block, Block)> overlappingPairs;

  const OverlapWarningBanner({super.key, required this.overlappingPairs});

  @override
  Widget build(BuildContext context) {
    final count = overlappingPairs.length;
    final detail = overlappingPairs.first;

    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                count == 1
                    ? '블록 겹침: "${detail.$1.title}"와 "${detail.$2.title}"'
                    : '블록 겹침 $count쌍 감지됨',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
