import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/blocks_table.dart';

part 'blocks_dao.g.dart';

@DriftAccessor(tables: [Blocks])
class BlocksDao extends DatabaseAccessor<AppDatabase> with _$BlocksDaoMixin {
  BlocksDao(super.db);

  Future<List<Block>> getAllBlocks() => select(blocks).get();

  Future<Block?> getBlockById(int id) =>
      (select(blocks)..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<List<Block>> getChildBlocks(int parentId) =>
      (select(blocks)..where((b) => b.parentId.equals(parentId))).get();

  Future<int> insertBlock(BlocksCompanion block) =>
      into(blocks).insert(block);

  Future<bool> updateBlock(Block block) => update(blocks).replace(block);

  Future<int> deleteBlock(int id) =>
      (delete(blocks)..where((b) => b.id.equals(id))).go();
}
