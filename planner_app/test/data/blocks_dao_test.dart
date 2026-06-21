import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting());
  tearDown(() => db.close());

  Future<int> makeTemplate(String title, {int color = 0xFF4CAF50}) =>
      db.blockTemplatesDao.insertTemplate(
        BlockTemplatesCompanion.insert(title: title, color: color),
      );

  group('BlocksDao CRUD', () {
    test('insert and read a block', () async {
      final tid = await makeTemplate('운동');
      final id = await db.blocksDao.insertBlock(
        BlocksCompanion(blockTemplateId: Value(tid)),
      );
      final block = await db.blocksDao.getBlockById(id);
      expect(block, isNotNull);
      expect(block!.blockTemplateId, tid);
      expect(block.isCompleted, false);
    });

    test('update a block (mark completed)', () async {
      final tid = await makeTemplate('독서');
      final id = await db.blocksDao.insertBlock(
        BlocksCompanion(blockTemplateId: Value(tid)),
      );
      final original = await db.blocksDao.getBlockById(id);
      await db.blocksDao.updateBlock(original!.copyWith(isCompleted: true));
      final updated = await db.blocksDao.getBlockById(id);
      expect(updated!.isCompleted, true);
    });

    test('delete a block', () async {
      final tid = await makeTemplate('임시');
      final id = await db.blocksDao.insertBlock(
        BlocksCompanion(blockTemplateId: Value(tid)),
      );
      await db.blocksDao.deleteBlock(id);
      final deleted = await db.blocksDao.getBlockById(id);
      expect(deleted, isNull);
    });

    test('get all blocks', () async {
      final t1 = await makeTemplate('A');
      final t2 = await makeTemplate('B');
      await db.blocksDao.insertBlock(BlocksCompanion(blockTemplateId: Value(t1)));
      await db.blocksDao.insertBlock(BlocksCompanion(blockTemplateId: Value(t2)));
      final all = await db.blocksDao.getAllBlocks();
      expect(all.length, 2);
    });

    test('get child blocks by parentId', () async {
      final tid = await makeTemplate('공통 템플릿');
      final parentId = await db.blocksDao.insertBlock(
        BlocksCompanion(blockTemplateId: Value(tid)),
      );
      await db.blocksDao.insertBlock(
        BlocksCompanion(
          blockTemplateId: Value(tid),
          parentId: Value(parentId),
        ),
      );
      await db.blocksDao.insertBlock(
        BlocksCompanion(
          blockTemplateId: Value(tid),
          parentId: Value(parentId),
        ),
      );
      final children = await db.blocksDao.getChildBlocks(parentId);
      expect(children.length, 2);
    });
  });
}
