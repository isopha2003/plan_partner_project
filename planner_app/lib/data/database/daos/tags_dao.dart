import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/block_tags_table.dart';
import '../tables/tags_table.dart';

part 'tags_dao.g.dart';

@DriftAccessor(tables: [Tags, BlockTags])
class TagsDao extends DatabaseAccessor<AppDatabase> with _$TagsDaoMixin {
  TagsDao(super.db);

  Future<List<Tag>> getAllTags() => select(tags).get();

  Stream<List<Tag>> watchAllTags() =>
      (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  Future<void> detachTagFromBlock(int blockId, int tagId) =>
      (delete(blockTags)
            ..where((bt) =>
                bt.blockId.equals(blockId) & bt.tagId.equals(tagId)))
          .go();

  Future<int> insertTag(TagsCompanion tag) => into(tags).insert(tag);

  Future<void> attachTagToBlock(int blockId, int tagId) =>
      into(blockTags).insert(BlockTagsCompanion(
        blockId: Value(blockId),
        tagId: Value(tagId),
      ));

  Future<List<Tag>> getTagsForBlock(int blockId) {
    final query = select(tags).join([
      innerJoin(blockTags, blockTags.tagId.equalsExp(tags.id)),
    ])..where(blockTags.blockId.equals(blockId));
    return query.map((row) => row.readTable(tags)).get();
  }
}
