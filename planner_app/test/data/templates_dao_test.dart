import 'package:drift/drift.dart' hide isNull, isNotNull, isIn;
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting());
  tearDown(() => db.close());

  group('TemplatesDao - 템플릿 저장/조회', () {
    test('save template with blocks and retrieve', () async {
      final templateId = await db.templatesDao.insertTemplate(
          const TemplatesCompanion(name: Value('평일 루틴'), type: Value('day')));

      await db.templatesDao.insertTemplateBlock(TemplateBlocksCompanion(
        templateId: Value(templateId),
        title: const Value('아침 운동'),
        color: const Value(0xFF4CAF50),
        startOffsetMinutes: const Value(360),
        durationMinutes: const Value(60),
        sortOrder: const Value(0),
      ));
      await db.templatesDao.insertTemplateBlock(TemplateBlocksCompanion(
        templateId: Value(templateId),
        title: const Value('공부'),
        color: const Value(0xFF2196F3),
        startOffsetMinutes: const Value(540),
        durationMinutes: const Value(120),
        sortOrder: const Value(1),
      ));

      final template = await db.templatesDao.getTemplateById(templateId);
      expect(template, isNotNull);
      expect(template!.name, '평일 루틴');
      expect(template.type, 'day');

      final tBlocks = await db.templatesDao.getTemplateBlocks(templateId);
      expect(tBlocks.length, 2);
      expect(tBlocks.first.title, '아침 운동');
      expect(tBlocks.last.title, '공부');
    });

    test('template blocks are sorted by sortOrder', () async {
      final tid = await db.templatesDao.insertTemplate(
          const TemplatesCompanion(name: Value('주간'), type: Value('week')));
      await db.templatesDao.insertTemplateBlock(TemplateBlocksCompanion(
          templateId: Value(tid),
          title: const Value('C'),
          color: const Value(0xFF000000),
          sortOrder: const Value(2)));
      await db.templatesDao.insertTemplateBlock(TemplateBlocksCompanion(
          templateId: Value(tid),
          title: const Value('A'),
          color: const Value(0xFF000000),
          sortOrder: const Value(0)));
      await db.templatesDao.insertTemplateBlock(TemplateBlocksCompanion(
          templateId: Value(tid),
          title: const Value('B'),
          color: const Value(0xFF000000),
          sortOrder: const Value(1)));

      final tBlocks = await db.templatesDao.getTemplateBlocks(tid);
      expect(tBlocks.map((b) => b.title).toList(), ['A', 'B', 'C']);
    });
  });
}
