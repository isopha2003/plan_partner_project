import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/main.dart';
import 'package:planner_app/presentation/providers/blocks_provider.dart';
import 'package:planner_app/presentation/screens/habit_stack_screen.dart';

/// Create or edit a block instance (and its underlying template).
///
/// - New block: pass [initialDate] only — creates a new template + instance.
/// - Edit existing: pass both [block] and [template].
class BlockEditScreen extends ConsumerStatefulWidget {
  final Block? block;
  final BlockTemplate? template;
  final DateTime? initialDate;

  const BlockEditScreen({
    super.key,
    this.block,
    this.template,
    this.initialDate,
  });

  @override
  ConsumerState<BlockEditScreen> createState() => _BlockEditScreenState();
}

class _BlockEditScreenState extends ConsumerState<BlockEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late Color _color;
  late DateTime _start;
  late DateTime _end;
  final Set<int> _selectedTagIds = {};

  bool get _isEditing => widget.block != null && widget.template != null;

  @override
  void initState() {
    super.initState();
    final base = widget.initialDate ?? DateTime.now();
    final defaultStart = DateTime(base.year, base.month, base.day, 9, 0);

    _titleCtrl = TextEditingController(text: widget.template?.title ?? '');
    _color = Color(widget.template?.color ?? 0xFF4CAF50);
    _start = widget.block?.startTime ?? defaultStart;
    _end = widget.block?.endTime ?? defaultStart.add(const Duration(hours: 1));

    if (_isEditing) {
      ref
          .read(databaseProvider)
          .tagsDao
          .getTagsForTemplate(widget.block!.blockTemplateId)
          .then((tags) {
        if (mounted) {
          setState(() => _selectedTagIds.addAll(tags.map((t) => t.id)));
        }
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTagsAsync = ref.watch(allTagsProvider);
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
          TextButton(
            onPressed: _save,
            child: const Text('저장'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '제목을 입력하세요' : null,
            ),
            const SizedBox(height: 16),

            _SectionLabel('색상'),
            GestureDetector(
              onTap: _pickColor,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Text(
                    '색상 선택',
                    style: TextStyle(
                      color: _color.computeLuminance() > 0.5
                          ? Colors.black87
                          : Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

            _SectionLabel('태그'),
            allTagsAsync.when(
              data: (tags) {
                if (tags.isEmpty) {
                  return const Text('등록된 태그가 없습니다.',
                      style: TextStyle(color: Colors.grey));
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: tags.map((tag) {
                    final selected = _selectedTagIds.contains(tag.id);
                    return FilterChip(
                      label: Text(tag.name),
                      selected: selected,
                      selectedColor:
                          Color(tag.color).withValues(alpha: 0.3),
                      onSelected: (on) => setState(() {
                        on
                            ? _selectedTagIds.add(tag.id)
                            : _selectedTagIds.remove(tag.id);
                      }),
                    );
                  }).toList(),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickColor() async {
    Color picked = _color;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('색상 선택'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _color,
            onColorChanged: (c) => picked = c,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    setState(() => _color = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_end.isBefore(_start) || _end.isAtSameMomentAs(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료 시간이 시작 시간보다 앞에 있습니다.')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    final int blockId;
    final int templateId;

    if (_isEditing) {
      templateId = widget.block!.blockTemplateId;
      await db.blockTemplatesDao.updateTemplate(
        widget.template!.copyWith(
          title: _titleCtrl.text.trim(),
          color: _color.toARGB32(),
        ),
      );
      await db.blocksDao.updateBlockTimes(widget.block!.id, _start, _end);
      blockId = widget.block!.id;
    } else {
      templateId = await db.blockTemplatesDao.insertTemplate(
        BlockTemplatesCompanion.insert(
          title: _titleCtrl.text.trim(),
          color: _color.toARGB32(),
        ),
      );
      blockId = await db.blocksDao.insertBlock(
        BlocksCompanion.insert(
          blockTemplateId: templateId,
          startTime: Value(_start),
          endTime: Value(_end),
        ),
      );
    }

    // Sync tags at the template level
    final existingTags = await db.tagsDao.getTagsForTemplate(templateId);
    final existingIds = existingTags.map((t) => t.id).toSet();
    for (final id in _selectedTagIds.difference(existingIds)) {
      await db.tagsDao.attachTagToTemplate(templateId, id);
    }
    for (final id in existingIds.difference(_selectedTagIds)) {
      await db.tagsDao.detachTagFromTemplate(templateId, id);
    }

    // blockId used to satisfy the variable-must-be-used lint
    assert(blockId > 0);
    if (mounted) Navigator.pop(context);
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
