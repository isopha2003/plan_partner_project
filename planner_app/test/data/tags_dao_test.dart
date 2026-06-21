import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting());
  tearDown(() => db.close());

  Future<int> makeTemplate(String title) =>
      db.blockTemplatesDao.insertTemplate(
        BlockTemplatesCompanion.insert(title: title, color: 0xFF4CAF50),
      );

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

    test('attach tag to template and query', () async {
      final templateId = await makeTemplate('블록 템플릿');
      final tagId = await db.tagsDao.insertTag(
          const TagsCompanion(name: Value('중요'), color: Value(0xFFF44336)));

      await db.tagsDao.attachTagToTemplate(templateId, tagId);

      final tagsForTemplate =
          await db.tagsDao.getTagsForTemplate(templateId);
      expect(tagsForTemplate.length, 1);
      expect(tagsForTemplate.first.name, '중요');
    });

    test('template with no tags returns empty list', () async {
      final templateId = await makeTemplate('태그없는템플릿');
      final tags = await db.tagsDao.getTagsForTemplate(templateId);
      expect(tags, isEmpty);
    });

    test('detach tag from template', () async {
      final templateId = await makeTemplate('태그 떼기 테스트');
      final tagId = await db.tagsDao.insertTag(
          const TagsCompanion(name: Value('임시'), color: Value(0xFF9E9E9E)));
      await db.tagsDao.attachTagToTemplate(templateId, tagId);
      await db.tagsDao.detachTagFromTemplate(templateId, tagId);
      final tags = await db.tagsDao.getTagsForTemplate(templateId);
      expect(tags, isEmpty);
    });
  });
}
