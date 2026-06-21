import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/domain/services/block_validator.dart';
import 'package:planner_app/main.dart';

/// Top-level (no parent) blocks for a given calendar day.
final blocksForDayProvider = StreamProvider.family<List<Block>, DateTime>(
  (ref, date) {
    final db = ref.watch(databaseProvider);
    return db.blocksDao.watchTopLevelBlocksForDay(date);
  },
);

/// Child blocks (by time or index) for a given parent block ID.
final childBlocksProvider = StreamProvider.family<List<Block>, int>(
  (ref, parentId) {
    final db = ref.watch(databaseProvider);
    return db.blocksDao.watchChildBlocks(parentId);
  },
);

/// All tags available in the DB (for the tag picker).
final allTagsProvider = StreamProvider<List<Tag>>(
  (ref) => ref.watch(databaseProvider).tagsDao.watchAllTags(),
);

/// Tags currently attached to a specific block.
final tagsForBlockProvider = FutureProvider.family<List<Tag>, int>(
  (ref, blockId) =>
      ref.watch(databaseProvider).tagsDao.getTagsForBlock(blockId),
);

/// Checklist items for a given block, streamed for live updates.
final checklistItemsProvider =
    StreamProvider.family<List<ChecklistItem>, int>(
  (ref, blockId) =>
      ref.watch(databaseProvider).checklistItemsDao.watchItemsByBlock(blockId),
);

/// Finds all overlapping pairs among [blocks].
List<(Block, Block)> findOverlaps(List<Block> blocks) {
  final result = <(Block, Block)>[];
  for (int i = 0; i < blocks.length; i++) {
    for (int j = i + 1; j < blocks.length; j++) {
      if (BlockValidator.timesOverlap(
        start1: blocks[i].startTime,
        end1: blocks[i].endTime,
        start2: blocks[j].startTime,
        end2: blocks[j].endTime,
      )) {
        result.add((blocks[i], blocks[j]));
      }
    }
  }
  return result;
}
