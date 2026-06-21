import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:planner_app/data/database/app_database.dart';

/// Pushed route. Pops with [RecurrenceRulesCompanion] when saved,
/// or null when the user selects "반복 없음".
class RecurrenceEditScreen extends StatefulWidget {
  final DateTime startDate;
  const RecurrenceEditScreen({super.key, required this.startDate});

  @override
  State<RecurrenceEditScreen> createState() => _RecurrenceEditScreenState();
}

class _RecurrenceEditScreenState extends State<RecurrenceEditScreen> {
  String _type = 'weekly';
  int _interval = 1;
  final Set<int> _days = {}; // 1=Mon … 7=Sun
  DateTime? _endDate;

  static const _weekLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    _days.add(widget.startDate.weekday);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('반복 설정'),
        actions: [TextButton(onPressed: _save, child: const Text('저장'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Label('반복 유형'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'daily', label: Text('매일')),
              ButtonSegment(value: 'weekly', label: Text('매주')),
              ButtonSegment(value: 'monthly', label: Text('매월')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 20),
          _Label(_intervalTitle),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _interval.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$_interval',
                  onChanged: (v) => setState(() => _interval = v.round()),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '$_interval$_unit',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (_type == 'weekly') ...[
            const SizedBox(height: 8),
            _Label('반복 요일'),
            Wrap(
              spacing: 6,
              children: [
                for (int i = 1; i <= 7; i++)
                  FilterChip(
                    label: Text(_weekLabels[i - 1]),
                    selected: _days.contains(i),
                    onSelected: (v) =>
                        setState(() => v ? _days.add(i) : _days.remove(i)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('종료일'),
            subtitle: Text(
                _endDate == null ? '없음 (무기한)' : _fmtDate(_endDate!)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_endDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() => _endDate = null),
                  ),
                TextButton(
                  onPressed: _pickEndDate,
                  child: const Text('선택'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('반복 없음으로 저장'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  String get _intervalTitle => switch (_type) {
        'daily' => '간격 (N일마다)',
        'weekly' => '간격 (N주마다)',
        'monthly' => '간격 (N개월마다)',
        _ => '간격',
      };

  String get _unit => switch (_type) {
        'daily' => '일',
        'weekly' => '주',
        'monthly' => '달',
        _ => '',
      };

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _endDate ?? widget.startDate.add(const Duration(days: 30)),
      firstDate: widget.startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _save() {
    if (_type == 'weekly' && _days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('반복 요일을 하나 이상 선택하세요.')),
      );
      return;
    }
    Navigator.pop<RecurrenceRulesCompanion>(
      context,
      RecurrenceRulesCompanion.insert(
        type: _type,
        startDate: widget.startDate,
        interval: Value(_interval),
        daysOfWeek: Value(
          _type == 'weekly'
              ? jsonEncode(_days.toList()..sort())
              : null,
        ),
        endDate: Value(_endDate),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );
}
