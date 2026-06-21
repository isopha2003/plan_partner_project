import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/presentation/providers/blocks_provider.dart';
import 'package:planner_app/presentation/widgets/calendar/block_tile.dart';

/// 24-hour day timeline showing scheduled blocks.
class DayView extends ConsumerWidget {
  final DateTime date;
  static const double hourHeight = 60.0; // 1 px per minute
  static const double labelWidth = 52.0;

  const DayView({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocksAsync = ref.watch(blocksForDayProvider(date));
    return blocksAsync.when(
      data: (blocks) => _Timeline(date: date, blocks: blocks),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('불러오기 실패: $e')),
    );
  }
}

class _Timeline extends StatelessWidget {
  final DateTime date;
  final List<Block> blocks;

  const _Timeline({required this.date, required this.blocks});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        height: DayView.hourHeight * 24 + 16,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TimeLabels(),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: _TimelineGrid(date: date, blocks: blocks)),
          ],
        ),
      ),
    );
  }
}

class _TimeLabels extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: DayView.labelWidth,
      height: DayView.hourHeight * 24,
      child: Stack(
        children: [
          for (int h = 0; h < 24; h++)
            Positioned(
              top: h * DayView.hourHeight - 7,
              right: 6,
              child: Text(
                '${h.toString().padLeft(2, '0')}:00',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineGrid extends StatelessWidget {
  final DateTime date;
  final List<Block> blocks;

  const _TimelineGrid({required this.date, required this.blocks});

  @override
  Widget build(BuildContext context) {
    final scheduled = blocks
        .where((b) => b.startTime != null && b.endTime != null)
        .toList();

    return Stack(
      children: [
        // Hour grid lines
        for (int h = 0; h <= 24; h++)
          Positioned(
            top: h * DayView.hourHeight,
            left: 0,
            right: 0,
            child: Container(height: 1, color: Colors.grey[200]),
          ),
        // Half-hour tick lines
        for (int h = 0; h < 24; h++)
          Positioned(
            top: h * DayView.hourHeight + DayView.hourHeight / 2,
            left: 0,
            right: 0,
            child: Container(height: 1, color: Colors.grey[100]),
          ),
        // Block tiles — fixed height (48 px) in Task 1; Task 3 makes this proportional
        for (final b in scheduled) _positionedBlock(b),
      ],
    );
  }

  Widget _positionedBlock(Block b) {
    final topMinutes = b.startTime!.hour * 60 + b.startTime!.minute;
    final top = topMinutes * DayView.hourHeight / 60.0;
    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: 48, // fixed placeholder; Task 3 makes this proportional to duration
      child: BlockTile(block: b),
    );
  }
}
