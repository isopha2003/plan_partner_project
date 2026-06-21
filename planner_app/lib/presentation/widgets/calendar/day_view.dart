import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/main.dart';
import 'package:planner_app/presentation/providers/blocks_provider.dart';
import 'package:planner_app/presentation/widgets/calendar/block_tile.dart';
import 'package:planner_app/presentation/widgets/calendar/overlap_banner.dart';

/// 24-hour day timeline showing scheduled blocks with drag-and-drop support.
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
    final overlaps = findOverlaps(blocks);
    return Column(
      children: [
        if (overlaps.isNotEmpty)
          OverlapWarningBanner(overlappingPairs: overlaps),
        Expanded(child: _timelineScroll()),
      ],
    );
  }

  Widget _timelineScroll() {
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

/// Timeline grid with drag-and-drop support. Blocks are long-press-draggable;
/// dropping anywhere on the grid snaps to the nearest 15-minute slot.
class _TimelineGrid extends ConsumerStatefulWidget {
  final DateTime date;
  final List<Block> blocks;

  const _TimelineGrid({required this.date, required this.blocks});

  @override
  ConsumerState<_TimelineGrid> createState() => _TimelineGridState();
}

class _TimelineGridState extends ConsumerState<_TimelineGrid> {
  final _gridKey = GlobalKey();
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final scheduled = widget.blocks
        .where((b) => b.startTime != null && b.endTime != null)
        .toList();

    return DragTarget<Block>(
      key: _gridKey,
      onWillAcceptWithDetails: (_) {
        setState(() => _isDragOver = true);
        return true;
      },
      onLeave: (_) => setState(() => _isDragOver = false),
      onAcceptWithDetails: (details) {
        setState(() => _isDragOver = false);
        _handleDrop(details);
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          children: [
            // Drag-over highlight
            if (_isDragOver)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.06),
                  ),
                ),
              ),
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
            // Draggable block tiles (fixed height; Task 3 makes height proportional)
            for (final b in scheduled) _draggableBlock(b),
          ],
        );
      },
    );
  }

  Widget _draggableBlock(Block b) {
    final topMinutes = b.startTime!.hour * 60 + b.startTime!.minute;
    final top = topMinutes * DayView.hourHeight / 60.0;
    // Height is proportional to duration: 1 minute = 1 px (hourHeight = 60 px/hr)
    final durationMin = b.endTime!.difference(b.startTime!).inMinutes;
    final height = (durationMin * DayView.hourHeight / 60.0).clamp(22.0, double.infinity);

    final tile = BlockTile(block: b);
    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: height,
      child: LongPressDraggable<Block>(
        data: b,
        delay: const Duration(milliseconds: 400),
        feedback: SizedBox(
          width: 160,
          height: height.clamp(48.0, 120.0),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(6),
            child: tile,
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: tile),
        child: tile,
      ),
    );
  }

  void _handleDrop(DragTargetDetails<Block> details) {
    final renderBox =
        _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localY = renderBox.globalToLocal(details.offset).dy;
    final rawMinutes = (localY / DayView.hourHeight * 60).round();
    // Snap to nearest 15 minutes, clamped to valid day range
    final snappedMinutes = ((rawMinutes / 15).round() * 15).clamp(0, 23 * 60);

    final block = details.data;
    final duration = block.endTime!.difference(block.startTime!);
    final newStart = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      snappedMinutes ~/ 60,
      snappedMinutes % 60,
    );
    final newEnd = newStart.add(duration);

    ref
        .read(databaseProvider)
        .blocksDao
        .updateBlockTimes(block.id, newStart, newEnd);
  }
}
