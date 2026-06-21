import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting());
  tearDown(() => db.close());

  Future<int> makeBlock(String title, {int color = 0xFF9C27B0}) async {
    final tid = await db.blockTemplatesDao.insertTemplate(
      BlockTemplatesCompanion.insert(title: title, color: color),
    );
    return db.blocksDao.insertBlock(BlocksCompanion(blockTemplateId: Value(tid)));
  }

  group('ChecklistItemsDao - 3단계 중첩', () {
    test('create and query 3-level nested checklist items', () async {
      final blockId = await makeBlock('공부');

      final level1Id = await db.checklistItemsDao.insertItem(
          ChecklistItemsCompanion(
              title: const Value('1단계'), blockId: Value(blockId)));

      final level2Id = await db.checklistItemsDao.insertItem(
          ChecklistItemsCompanion(
              title: const Value('2단계'),
              parentItemId: Value(level1Id)));

      final level3Id = await db.checklistItemsDao.insertItem(
          ChecklistItemsCompanion(
              title: const Value('3단계'),
              parentItemId: Value(level2Id)));

      final rootItems = await db.checklistItemsDao.getItemsByBlock(blockId);
      expect(rootItems.length, 1);
      expect(rootItems.first.title, '1단계');

      final level2Items = await db.checklistItemsDao.getChildItems(level1Id);
      expect(level2Items.length, 1);
      expect(level2Items.first.title, '2단계');

      final level3Items = await db.checklistItemsDao.getChildItems(level2Id);
      expect(level3Items.length, 1);
      expect(level3Items.first.id, level3Id);
      expect(level3Items.first.title, '3단계');
    });

    test('update item completion', () async {
      final blockId = await makeBlock('할일', color: 0xFFFFFFFF);
      await db.checklistItemsDao.insertItem(ChecklistItemsCompanion(
          title: const Value('항목'), blockId: Value(blockId)));
      final item =
          (await db.checklistItemsDao.getItemsByBlock(blockId)).first;
      await db.checklistItemsDao.updateItem(item.copyWith(isCompleted: true));
      final updated =
          (await db.checklistItemsDao.getItemsByBlock(blockId)).first;
      expect(updated.isCompleted, true);
    });
  });
}
