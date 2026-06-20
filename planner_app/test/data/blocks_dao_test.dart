import 'package:drift/drift.dart' hide isNull, isNotNull, isIn;
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting());
  tearDown(() => db.close());

  group('BlocksDao CRUD', () {
    test('insert and read a block', () async {
      final id = await db.blocksDao.insertBlock(const BlocksCompanion(
        title: Value('운동'),
        color: Value(0xFF4CAF50),
      ));
      final block = await db.blocksDao.getBlockById(id);
      expect(block, isNotNull);
      expect(block!.title, '운동');
      expect(block.isCompleted, false);
    });

    test('update a block', () async {
      final id = await db.blocksDao.insertBlock(const BlocksCompanion(
        title: Value('독서'),
        color: Value(0xFF2196F3),
      ));
      final original = await db.blocksDao.getBlockById(id);
      await db.blocksDao.updateBlock(original!.copyWith(title: '독서 완료'));
      final updated = await db.blocksDao.getBlockById(id);
      expect(updated!.title, '독서 완료');
    });

    test('delete a block', () async {
      final id = await db.blocksDao.insertBlock(const BlocksCompanion(
        title: Value('임시'),
        color: Value(0xFFFF5722),
      ));
      await db.blocksDao.deleteBlock(id);
      final deleted = await db.blocksDao.getBlockById(id);
      expect(deleted, isNull);
    });

    test('get all blocks', () async {
      await db.blocksDao.insertBlock(
          const BlocksCompanion(title: Value('A'), color: Value(0xFFFFFFFF)));
      await db.blocksDao.insertBlock(
          const BlocksCompanion(title: Value('B'), color: Value(0xFFFFFFFF)));
      final all = await db.blocksDao.getAllBlocks();
      expect(all.length, 2);
    });

    test('get child blocks by parentId', () async {
      final parentId = await db.blocksDao.insertBlock(const BlocksCompanion(
        title: Value('부모'),
        color: Value(0xFFFFFFFF),
      ));
      await db.blocksDao.insertBlock(BlocksCompanion(
        title: const Value('자식 1'),
        color: const Value(0xFFFFFFFF),
        parentId: Value(parentId),
      ));
      await db.blocksDao.insertBlock(BlocksCompanion(
        title: const Value('자식 2'),
        color: const Value(0xFFFFFFFF),
        parentId: Value(parentId),
      ));
      final children = await db.blocksDao.getChildBlocks(parentId);
      expect(children.length, 2);
    });
  });
}
