import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/main.dart';
import 'package:planner_app/presentation/providers/blocks_provider.dart';
import 'package:planner_app/presentation/screens/block_template_edit_screen.dart';
import 'package:planner_app/presentation/widgets/calendar/block_tile.dart';
import 'package:planner_app/presentation/widgets/calendar/overlap_banner.dart';

/// 24-hour day timeline with drag-and-drop support and template palette.
class DayView extends ConsumerWidget {
  final DateTime date;
  static const double hourHeight = 60.0;
  static const double labelWidth = 52.0;

  const DayView({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocksAsync = ref.watch(blocksForDayProvider(date));
    return blocksAsync.when(
      data: (pairs) => _DayViewContent(date: date, pairs: pairs),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('불러오기 실패: $e')),
    );
  }
}

// ── Main layout ───────────────────────────────────────────────────────────────

/// Collapsed height fraction (drag handle ~24px + chip row ~40px + padding ~20px
/// ≈ 84px; 84/800 ≈ 0.105 — use 0.13 for breathing room on small screens).
const double _kCollapsedSize = 0.13;
const double _kExpandedSize = 0.45;

class _DayViewContent extends ConsumerStatefulWidget {
  final DateTime date;
  final List<(Block, BlockTemplate)> pairs;

  const _DayViewContent({required this.date, required this.pairs});

  @override
  ConsumerState<_DayViewContent> createState() => _DayViewContentState();
}

class _DayViewContentState extends ConsumerState<_DayViewContent> {
  final ScrollController _scrollController = ScrollController();
  bool _isResizing = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onResizeStateChanged(bool resizing) {
    setState(() => _isResizing = resizing);
  }

  @override
  Widget build(BuildContext context) {
    final overlaps = findOverlaps(widget.pairs);
    final templatesAsync = ref.watch(blockTemplatesProvider);
    final paletteH = MediaQuery.of(context).size.height * _kCollapsedSize;

    return Stack(
      children: [
        // ── Timeline ─────────────────────────────────────────────────────
        Column(
          children: [
            if (overlaps.isNotEmpty)
              OverlapWarningBanner(overlappingPairs: overlaps),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                // Lock scrolling while resizing so the scroll view
                // cannot steal the vertical drag gesture.
                physics: _isResizing
                    ? const NeverScrollableScrollPhysics()
                    : null,
                // Reserve space at the bottom equal to the collapsed
                // palette height so 24:00 is fully reachable by scroll.
                padding: EdgeInsets.only(bottom: paletteH),
                child: SizedBox(
                  height: DayView.hourHeight * 24 + 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TimeLabels(),
                      const VerticalDivider(width: 1, thickness: 1),
                      Expanded(
                        child: _TimelineGrid(
                          date: widget.date,
                          pairs: widget.pairs,
                          onResizeStateChanged: _onResizeStateChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // ── Palette overlay ──────────────────────────────────────────────
        // Hidden while resizing so the block is not obscured by the sheet.
        IgnorePointer(
          ignoring: _isResizing,
          child: AnimatedOpacity(
            opacity: _isResizing ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 180),
            child: _TemplatePaletteSheet(templatesAsync: templatesAsync),
          ),
        ),
      ],
    );
  }
}

// ── Hour labels ───────────────────────────────────────────────────────────────

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

// ── Timeline grid ─────────────────────────────────────────────────────────────

class _TimelineGrid extends ConsumerStatefulWidget {
  final DateTime date;
  final List<(Block, BlockTemplate)> pairs;
  final ValueChanged<bool> onResizeStateChanged;

  const _TimelineGrid({
    required this.date,
    required this.pairs,
    required this.onResizeStateChanged,
  });

  @override
  ConsumerState<_TimelineGrid> createState() => _TimelineGridState();
}

class _TimelineGridState extends ConsumerState<_TimelineGrid> {
  final _gridKey = GlobalKey();
  bool _isDragOver = false;

  // Resize state
  Block? _resizingBlock;
  bool _resizingTop = false;
  DateTime _resizeOrigStart = DateTime(0);
  DateTime _resizeOrigEnd = DateTime(0);
  double _resizeDragStartY = 0; // global Y at drag start
  double _resizeTotalDelta = 0; // = currentGlobalY − _resizeDragStartY

  @override
  Widget build(BuildContext context) {
    final scheduled = widget.pairs
        .where((p) => p.$1.startTime != null && p.$1.endTime != null)
        .toList();

    return DragTarget<Object>(
      key: _gridKey,
      onWillAcceptWithDetails: (details) {
        final ok =
            details.data is Block || details.data is BlockTemplate;
        if (ok) setState(() => _isDragOver = true);
        return ok;
      },
      onLeave: (_) => setState(() => _isDragOver = false),
      onAcceptWithDetails: (details) {
        setState(() => _isDragOver = false);
        final data = details.data;
        if (data is Block) _handleBlockMove(data, details.offset);
        if (data is BlockTemplate) _handleTemplateDrop(data, details.offset);
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          children: [
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
            for (int h = 0; h <= 24; h++)
              Positioned(
                top: h * DayView.hourHeight,
                left: 0,
                right: 0,
                child: Container(height: 1, color: Colors.grey[200]),
              ),
            for (int h = 0; h < 24; h++)
              Positioned(
                top: h * DayView.hourHeight + DayView.hourHeight / 2,
                left: 0,
                right: 0,
                child: Container(height: 1, color: Colors.grey[100]),
              ),
            for (final pair in scheduled) _positionedBlock(pair),
          ],
        );
      },
    );
  }

  // ── Block rendering ──────────────────────────────────────────────────────

  Widget _positionedBlock((Block, BlockTemplate) pair) {
    final (block, template) = pair;
    final isResizing = _resizingBlock?.id == block.id;

    DateTime displayStart = block.startTime!;
    DateTime displayEnd = block.endTime!;

    if (isResizing) {
      final deltaMin =
          (_resizeTotalDelta / DayView.hourHeight * 60).round();
      final snapped = (deltaMin / 15).round() * 15;
      if (_resizingTop) {
        final candidate =
            _resizeOrigStart.add(Duration(minutes: snapped));
        if (candidate.isBefore(
            displayEnd.subtract(const Duration(minutes: 15)))) {
          displayStart = candidate;
        }
      } else {
        final candidate =
            _resizeOrigEnd.add(Duration(minutes: snapped));
        if (candidate
            .isAfter(displayStart.add(const Duration(minutes: 15)))) {
          displayEnd = candidate;
        }
      }
    }

    final topMin = displayStart.hour * 60 + displayStart.minute;
    final top = topMin * DayView.hourHeight / 60.0;
    final durationMin = displayEnd.difference(displayStart).inMinutes;
    final height =
        (durationMin * DayView.hourHeight / 60.0).clamp(22.0, double.infinity);

    final tile = BlockTile(block: block, template: template);

    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: height,
      child: Stack(
        children: [
          LongPressDraggable<Block>(
            data: block,
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
          // Top resize handle
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 12,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (d) =>
                  _startResize(block, true, d.globalPosition.dy),
              // Use absolute globalY so scroll-view gesture competition
              // cannot corrupt the accumulated delta.
              onVerticalDragUpdate: (d) =>
                  _updateResize(d.globalPosition.dy),
              onVerticalDragEnd: (_) => _commitResize(block),
              child: _ResizeHandle(top: true),
            ),
          ),
          // Bottom resize handle
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 12,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (d) =>
                  _startResize(block, false, d.globalPosition.dy),
              onVerticalDragUpdate: (d) =>
                  _updateResize(d.globalPosition.dy),
              onVerticalDragEnd: (_) => _commitResize(block),
              child: _ResizeHandle(top: false),
            ),
          ),
        ],
      ),
    );
  }

  // ── Resize helpers ───────────────────────────────────────────────────────

  void _startResize(Block block, bool top, double globalStartY) {
    widget.onResizeStateChanged(true);
    setState(() {
      _resizingBlock = block;
      _resizingTop = top;
      _resizeOrigStart = block.startTime!;
      _resizeOrigEnd = block.endTime!;
      _resizeDragStartY = globalStartY;
      _resizeTotalDelta = 0;
    });
  }

  // Recompute total delta as absolute distance from drag-start (not cumulative).
  void _updateResize(double globalCurrentY) {
    setState(() => _resizeTotalDelta = globalCurrentY - _resizeDragStartY);
  }

  void _commitResize(Block block) {
    widget.onResizeStateChanged(false);
    if (_resizingBlock == null) return;

    final deltaMin =
        (_resizeTotalDelta / DayView.hourHeight * 60).round();
    final snapped = (deltaMin / 15).round() * 15;

    DateTime newStart = _resizeOrigStart;
    DateTime newEnd = _resizeOrigEnd;

    if (_resizingTop) {
      final candidate =
          _resizeOrigStart.add(Duration(minutes: snapped));
      if (candidate
          .isBefore(newEnd.subtract(const Duration(minutes: 15)))) {
        newStart = candidate;
      }
    } else {
      final candidate =
          _resizeOrigEnd.add(Duration(minutes: snapped));
      if (candidate
          .isAfter(newStart.add(const Duration(minutes: 15)))) {
        newEnd = candidate;
      }
    }

    ref
        .read(databaseProvider)
        .blocksDao
        .updateBlockTimes(block.id, newStart, newEnd);

    setState(() {
      _resizingBlock = null;
      _resizeTotalDelta = 0;
      _resizeDragStartY = 0;
    });
  }

  // ── Drop handlers ────────────────────────────────────────────────────────

  void _handleBlockMove(Block block, Offset globalOffset) {
    final renderBox =
        _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localY = renderBox.globalToLocal(globalOffset).dy;
    final rawMin = (localY / DayView.hourHeight * 60).round();
    final snapped = ((rawMin / 15).round() * 15).clamp(0, 23 * 60);

    final duration = block.endTime!.difference(block.startTime!);
    final newStart = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      snapped ~/ 60,
      snapped % 60,
    );
    ref
        .read(databaseProvider)
        .blocksDao
        .updateBlockTimes(block.id, newStart, newStart.add(duration));
  }

  void _handleTemplateDrop(BlockTemplate template, Offset globalOffset) {
    final renderBox =
        _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localY = renderBox.globalToLocal(globalOffset).dy;
    final rawMin = (localY / DayView.hourHeight * 60).round();
    final snapped = ((rawMin / 15).round() * 15).clamp(0, 22 * 60);

    final newStart = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      snapped ~/ 60,
      snapped % 60,
    );

    ref.read(databaseProvider).blocksDao.insertBlock(
          BlocksCompanion.insert(
            blockTemplateId: template.id,
            startTime: Value(newStart),
            endTime: Value(newStart.add(const Duration(hours: 1))),
          ),
        );
  }
}

// ── Template palette sheet (expandable) ──────────────────────────────────────

class _TemplatePaletteSheet extends StatelessWidget {
  final AsyncValue<List<BlockTemplate>> templatesAsync;

  const _TemplatePaletteSheet({required this.templatesAsync});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return DraggableScrollableSheet(
      initialChildSize: _kCollapsedSize,
      minChildSize: _kCollapsedSize,
      maxChildSize: _kExpandedSize,
      snap: true,
      snapSizes: const [_kCollapsedSize, _kExpandedSize],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: _PaletteHeader(templatesAsync: templatesAsync),
              ),
              SliverToBoxAdapter(
                child: templatesAsync.when(
                  data: (templates) => Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: templates
                          .map((t) => _TemplateDraggableChip(template: t))
                          .toList(),
                    ),
                  ),
                  loading: () => const SizedBox(
                    height: 40,
                    child: Center(child: LinearProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('오류: $e'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaletteHeader extends StatelessWidget {
  final AsyncValue<List<BlockTemplate>> templatesAsync;
  const _PaletteHeader({required this.templatesAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 4, 8),
          child: Row(
            children: [
              Text(
                '템플릿',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 22),
                tooltip: '템플릿 추가',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BlockTemplateEditScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TemplateDraggableChip extends StatelessWidget {
  final BlockTemplate template;
  const _TemplateDraggableChip({required this.template});

  @override
  Widget build(BuildContext context) {
    final chip = _TemplateChip(template: template);
    return LongPressDraggable<BlockTemplate>(
      data: template,
      delay: const Duration(milliseconds: 300),
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(20),
        child: chip,
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: chip),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlockTemplateEditScreen(template: template),
          ),
        ),
        child: chip,
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final BlockTemplate template;
  const _TemplateChip({required this.template});

  @override
  Widget build(BuildContext context) {
    final color = Color(template.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        template.title,
        style: TextStyle(
          color: color.computeLuminance() > 0.5
              ? Colors.black87
              : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Resize handle visual ──────────────────────────────────────────────────────

class _ResizeHandle extends StatelessWidget {
  final bool top;
  const _ResizeHandle({required this.top});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
      child: Container(
        width: 32,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
