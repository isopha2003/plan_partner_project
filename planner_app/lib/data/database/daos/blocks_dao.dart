import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/block_templates_table.dart';
import '../tables/blocks_table.dart';

part 'blocks_dao.g.dart';

@DriftAccessor(tables: [Blocks, BlockTemplates])
class BlocksDao extends DatabaseAccessor<AppDatabase> with _$BlocksDaoMixin {
  BlocksDao(super.db);

  Future<List<Block>> getAllBlocks() => select(blocks).get();

  /// Reactive stream of all blocks (for grass / stats).
  Stream<List<Block>> watchAllBlocks() => select(blocks).watch();

  /// Batch-inserts generated recurring instances.
  Future<void> insertBlocks(List<BlocksCompanion> companions) =>
      batch((b) => b.insertAll(blocks, companions));

  /// Marks a block as completed or uncompleted, recording the exact time.
  Future<int> setBlockCompleted(int id, bool isCompleted) =>
      (update(blocks)..where((b) => b.id.equals(id))).write(
        BlocksCompanion(
          isCompleted: Value(isCompleted),
          completedAt: Value(isCompleted ? DateTime.now() : null),
        ),
      );

  Future<Block?> getBlockById(int id) =>
      (select(blocks)..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<List<Block>> getChildBlocks(int parentId) =>
      (select(blocks)..where((b) => b.parentId.equals(parentId))).get();

  Future<int> insertBlock(BlocksCompanion block) =>
      into(blocks).insert(block);

  Future<bool> updateBlock(Block block) => update(blocks).replace(block);

  Future<int> deleteBlock(int id) =>
      (delete(blocks)..where((b) => b.id.equals(id))).go();

  /// Streams top-level blocks with their template for a given day.
  Stream<List<(Block, BlockTemplate)>> watchTopLevelBlocksForDay(
      DateTime date) {
    final s = DateTime(date.year, date.month, date.day);
    final e = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    final query = select(blocks).join([
      innerJoin(blockTemplates,
          blockTemplates.id.equalsExp(blocks.blockTemplateId)),
    ])
      ..where(blocks.startTime.isBiggerOrEqualValue(s) &
          blocks.startTime.isSmallerOrEqualValue(e) &
          blocks.parentId.isNull())
      ..orderBy([OrderingTerm.asc(blocks.startTime)]);
    return query.watch().map((rows) => rows
        .map((r) => (r.readTable(blocks), r.readTable(blockTemplates)))
        .toList());
  }

  /// Streams child blocks with their template for a given parent.
  Stream<List<(Block, BlockTemplate)>> watchChildBlocks(int parentId) {
    final query = select(blocks).join([
      innerJoin(blockTemplates,
          blockTemplates.id.equalsExp(blocks.blockTemplateId)),
    ])
      ..where(blocks.parentId.equals(parentId))
      ..orderBy([OrderingTerm.asc(blocks.startTime)]);
    return query.watch().map((rows) => rows
        .map((r) => (r.readTable(blocks), r.readTable(blockTemplates)))
        .toList());
  }

  /// Updates only start/end time of a block (used by drag-and-drop and resize).
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

  /// Incomplete top-level blocks whose startTime is before [before].
  /// Used for the "아직 끝내지 못한 일" section.
  Stream<List<(Block, BlockTemplate)>> watchIncompletePastBlocks(
      DateTime before) {
    final query = select(blocks).join([
      innerJoin(
          blockTemplates, blockTemplates.id.equalsExp(blocks.blockTemplateId)),
    ])
      ..where(
        blocks.isCompleted.equals(false) &
            blocks.startTime.isSmallerThanValue(before) &
            blocks.startTime.isNotNull() &
            blocks.parentId.isNull(),
      )
      ..orderBy([OrderingTerm.desc(blocks.startTime)]);
    return query.watch().map((rows) => rows
        .map((r) => (r.readTable(blocks), r.readTable(blockTemplates)))
        .toList());
  }
}
