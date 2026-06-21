import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/domain/services/recurrence_generator.dart';
import 'package:planner_app/main.dart';
import 'package:planner_app/presentation/providers/blocks_provider.dart';
import 'package:planner_app/presentation/screens/block_template_edit_screen.dart';
import 'package:planner_app/presentation/screens/habit_stack_screen.dart';
import 'package:planner_app/presentation/screens/recurrence_edit_screen.dart';

/// Schedule or reschedule a block instance.
///
/// - Edit existing: pass [block] + [template] — only times are editable here.
///   Template metadata (title/color/tags) is edited via [BlockTemplateEditScreen].
/// - Create new: pass [template] (pre-selected) or leave null to pick one.
///   Pass [parentId] to create a child block.
class BlockEditScreen extends ConsumerStatefulWidget {
  final Block? block;
  final BlockTemplate? template;
  final DateTime? initialDate;
  final int? parentId;

  const BlockEditScreen({
    super.key,
    this.block,
    this.template,
    this.initialDate,
    this.parentId,
  });

  @override
  ConsumerState<BlockEditScreen> createState() => _BlockEditScreenState();
}

class _BlockEditScreenState extends ConsumerState<BlockEditScreen> {
  BlockTemplate? _selectedTemplate;
  late DateTime _start;
  late DateTime _end;
  RecurrenceRulesCompanion? _pendingRecurrence;
  late TextEditingController _memoController;

  bool get _isEditing => widget.block != null;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.template;

    final base = widget.initialDate ?? DateTime.now();
    final defaultStart = DateTime(base.year, base.month, base.day, 9, 0);
    _start = widget.block?.startTime ?? defaultStart;
    _end = widget.block?.endTime ?? defaultStart.add(const Duration(hours: 1));
    _memoController =
        TextEditingController(text: widget.block?.memo ?? '');
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(blockTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '블록 편집' : '블록 생성'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.link),
              tooltip: '습관 스태킹',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HabitStackScreen(
                    root: widget.block!,
                    rootTemplate: widget.template!,
                  ),
                ),
              ),
            ),
          if (_selectedTemplate != null)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: '템플릿 편집',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlockTemplateEditScreen(
                      template: _selectedTemplate),
                ),
              ),
            ),
          TextButton(onPressed: _save, child: const Text('저장')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Template header / picker ───────────────────────────────
          if (_isEditing && widget.template != null)
            _TemplateHeader(template: widget.template!)
          else
            templatesAsync.when(
              data: (templates) => _TemplatePicker(
                templates: templates,
                selected: _selectedTemplate,
                onChanged: (t) => setState(() => _selectedTemplate = t),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('템플릿 로딩 실패: $e'),
            ),
          const SizedBox(height: 20),

          // ── Time pickers ──────────────────────────────────────────
          _SectionLabel('시작 시간'),
          _TimePicker(
            dateTime: _start,
            onChanged: (dt) => setState(() {
              final dur = _end.difference(_start);
              _start = dt;
              _end = dt.add(dur);
            }),
          ),
          const SizedBox(height: 12),
          _SectionLabel('종료 시간'),
          _TimePicker(
            dateTime: _end,
            onChanged: (dt) => setState(() => _end = dt),
          ),

          // Recurrence — only for new blocks
          if (!_isEditing) ...[
            const SizedBox(height: 20),
            _SectionLabel('반복'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.repeat),
              title: Text(
                _pendingRecurrence == null ? '반복 없음' : _recurrenceLabel(),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openRecurrenceEdit,
            ),
          ],

          // Memo
          const SizedBox(height: 20),
          _SectionLabel('메모'),
          TextField(
            controller: _memoController,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: '블록에 대한 메모를 남겨 두세요',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRecurrenceEdit() async {
    final result = await Navigator.push<RecurrenceRulesCompanion>(
      context,
      MaterialPageRoute(
        builder: (_) => RecurrenceEditScreen(startDate: _start),
      ),
    );
    setState(() => _pendingRecurrence = result);
  }

  String _recurrenceLabel() {
    final r = _pendingRecurrence!;
    final interval = r.interval.present ? r.interval.value : 1;
    return switch (r.type.value) {
      'daily' => '매일 ($interval일 간격)',
      'weekly' => '매주 ($interval주 간격)',
      'monthly' => '매월 ($interval개월 간격)',
      _ => '반복 설정됨',
    };
  }

  Future<void> _save() async {
    if (_selectedTemplate == null && !_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('템플릿을 선택하세요.')),
      );
      return;
    }
    if (_end.isBefore(_start) || _end.isAtSameMomentAs(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료 시간이 시작 시간보다 앞에 있습니다.')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    final memo =
        _memoController.text.trim().isEmpty ? null : _memoController.text.trim();

    if (_isEditing) {
      await db.blocksDao.updateBlockDetails(
          widget.block!.id, start: _start, end: _end, memo: memo);
    } else {
      // Insert recurrence rule first if configured
      int? ruleId;
      if (_pendingRecurrence != null) {
        ruleId =
            await db.recurrenceRulesDao.insertRule(_pendingRecurrence!);
      }

      final blockId = await db.blocksDao.insertBlock(
        BlocksCompanion.insert(
          blockTemplateId: _selectedTemplate!.id,
          startTime: Value(_start),
          endTime: Value(_end),
          parentId: Value(widget.parentId),
          recurrenceRuleId: Value(ruleId),
          memo: Value(memo),
        ),
      );

      // Generate recurring instances for the next 90 days
      if (ruleId != null) {
        final rule = await db.recurrenceRulesDao.getRuleById(ruleId);
        final source = await db.blocksDao.getBlockById(blockId);
        if (rule != null && source != null) {
          final instances = RecurrenceGenerator.generate(
            rule: rule,
            sourceBlock: source,
            from: _start.add(const Duration(days: 1)),
            daysAhead: 90,
          );
          if (instances.isNotEmpty) {
            await db.blocksDao.insertBlocks(instances);
          }
        }
      }
    }

    if (mounted) Navigator.pop(context);
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _TemplateHeader extends StatelessWidget {
  final BlockTemplate template;
  const _TemplateHeader({required this.template});

  @override
  Widget build(BuildContext context) {
    final color = Color(template.color);
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          template.title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text('템플릿',
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }
}

class _TemplatePicker extends StatelessWidget {
  final List<BlockTemplate> templates;
  final BlockTemplate? selected;
  final ValueChanged<BlockTemplate> onChanged;

  const _TemplatePicker({
    required this.templates,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return const Text(
        '사용 가능한 템플릿이 없습니다. 먼저 템플릿을 생성하세요.',
        style: TextStyle(color: Colors.grey),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('템플릿 선택',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: templates.map((t) {
            final isSelected = selected?.id == t.id;
            return GestureDetector(
              onTap: () => onChanged(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color(t.color)
                      : Color(t.color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(t.color),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  t.title,
                  style: TextStyle(
                    color: isSelected
                        ? (Color(t.color).computeLuminance() > 0.5
                            ? Colors.black87
                            : Colors.white)
                        : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final DateTime dateTime;
  final ValueChanged<DateTime> onChanged;

  const _TimePicker({required this.dateTime, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return OutlinedButton.icon(
      icon: const Icon(Icons.access_time, size: 18),
      label: Text(
        '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}  $h:$m',
      ),
      onPressed: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: dateTime,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime:
              TimeOfDay(hour: dateTime.hour, minute: dateTime.minute),
        );
        if (time == null) return;
        onChanged(DateTime(
            date.year, date.month, date.day, time.hour, time.minute));
      },
    );
  }
}
