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

  /// Streams top-level (no parent) blocks whose startTime falls on [date].
  Stream<List<Block>> watchTopLevelBlocksForDay(DateTime date) {
    final s = DateTime(date.year, date.month, date.day);
    final e = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return (select(blocks)
          ..where((b) =>
              b.startTime.isBiggerOrEqualValue(s) &
              b.startTime.isSmallerOrEqualValue(e) &
              b.parentId.isNull())
          ..orderBy([(b) => OrderingTerm.asc(b.startTime)]))
        .watch();
  }

  /// Streams child blocks belonging to [parentId].
  Stream<List<Block>> watchChildBlocks(int parentId) =>
      (select(blocks)
            ..where((b) => b.parentId.equals(parentId))
            ..orderBy([(b) => OrderingTerm.asc(b.startTime)]))
          .watch();

  /// Updates only start/end time of a block (used by drag-and-drop).
  Future<int> updateBlockTimes(int id, DateTime newStart, DateTime newEnd) =>
      (update(blocks)..where((b) => b.id.equals(id))).write(
        BlocksCompanion(
          startTime: Value(newStart),
          endTime: Value(newEnd),
        ),
      );

  /// Updates nextBlockId (habit stacking).
  Future<int> setNextBlock(int id, int? nextId) =>
      (update(blocks)..where((b) => b.id.equals(id))).write(
        BlocksCompanion(nextBlockId: Value(nextId)),
      );
}
