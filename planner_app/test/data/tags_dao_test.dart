import 'package:drift/drift.dart' hide isNull, isNotNull, isIn;
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting());
  tearDown(() => db.close());

  group('TagsDao - 태그 추가/조회', () {
    test('insert and retrieve tags', () async {
      await db.tagsDao.insertTag(
          const TagsCompanion(name: Value('공부'), color: Value(0xFF2196F3)));
      await db.tagsDao.insertTag(
          const TagsCompanion(name: Value('운동'), color: Value(0xFF4CAF50)));
      final all = await db.tagsDao.getAllTags();
      expect(all.length, 2);
      expect(all.map((t) => t.name), containsAll(['공부', '운동']));
    });

    test('attach tag to block and query', () async {
      final blockId = await db.blocksDao.insertBlock(const BlocksCompanion(
        title: Value('블록'),
        color: Value(0xFFFFFFFF),
      ));
      final tagId = await db.tagsDao.insertTag(
          const TagsCompanion(name: Value('중요'), color: Value(0xFFF44336)));

      await db.tagsDao.attachTagToBlock(blockId, tagId);

      final tagsForBlock = await db.tagsDao.getTagsForBlock(blockId);
      expect(tagsForBlock.length, 1);
      expect(tagsForBlock.first.name, '중요');
    });

    test('block with no tags returns empty list', () async {
      final blockId = await db.blocksDao.insertBlock(const BlocksCompanion(
        title: Value('태그없는블록'),
        color: Value(0xFFFFFFFF),
      ));
      final tags = await db.tagsDao.getTagsForBlock(blockId);
      expect(tags, isEmpty);
    });
  });
}
