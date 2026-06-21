import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/main.dart';
import 'package:planner_app/presentation/providers/blocks_provider.dart';

/// Create or edit a block template (title + color + tags only — no date/time).
class BlockTemplateEditScreen extends ConsumerStatefulWidget {
  final BlockTemplate? template;

  const BlockTemplateEditScreen({super.key, this.template});

  @override
  ConsumerState<BlockTemplateEditScreen> createState() =>
      _BlockTemplateEditScreenState();
}

class _BlockTemplateEditScreenState
    extends ConsumerState<BlockTemplateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late Color _color;
  final Set<int> _selectedTagIds = {};

  bool get _isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.template?.title ?? '');
    _color = Color(widget.template?.color ?? 0xFF4CAF50);

    if (_isEditing) {
      ref
          .read(databaseProvider)
          .tagsDao
          .getTagsForTemplate(widget.template!.id)
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
        title: Text(_isEditing ? '템플릿 편집' : '템플릿 생성'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '템플릿 삭제',
              onPressed: _confirmDelete,
            ),
          TextButton(onPressed: _save, child: const Text('저장')),
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
    final db = ref.read(databaseProvider);
    final int templateId;

    if (_isEditing) {
      templateId = widget.template!.id;
      await db.blockTemplatesDao.updateTemplate(
        widget.template!.copyWith(
          title: _titleCtrl.text.trim(),
          color: _color.toARGB32(),
        ),
      );
    } else {
      templateId = await db.blockTemplatesDao.insertTemplate(
        BlockTemplatesCompanion.insert(
          title: _titleCtrl.text.trim(),
          color: _color.toARGB32(),
        ),
      );
    }

    final existingTags = await db.tagsDao.getTagsForTemplate(templateId);
    final existingIds = existingTags.map((t) => t.id).toSet();
    for (final id in _selectedTagIds.difference(existingIds)) {
      await db.tagsDao.attachTagToTemplate(templateId, id);
    }
    for (final id in existingIds.difference(_selectedTagIds)) {
      await db.tagsDao.detachTagFromTemplate(templateId, id);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('템플릿 삭제'),
        content: const Text('이 템플릿과 연결된 모든 블록이 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(databaseProvider)
        .blockTemplatesDao
        .deleteTemplate(widget.template!.id);
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
