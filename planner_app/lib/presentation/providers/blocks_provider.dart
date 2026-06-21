import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_app/data/database/app_database.dart';
import 'package:planner_app/domain/services/block_validator.dart';
import 'package:planner_app/main.dart';

/// Top-level blocks with their templates for a given calendar day.
final blocksForDayProvider =
    StreamProvider.family<List<(Block, BlockTemplate)>, DateTime>(
  (ref, date) {
    final db = ref.watch(databaseProvider);
    return db.blocksDao.watchTopLevelBlocksForDay(date);
  },
);

/// Child blocks with their templates for a given parent block ID.
final childBlocksProvider =
    StreamProvider.family<List<(Block, BlockTemplate)>, int>(
  (ref, parentId) {
    final db = ref.watch(databaseProvider);
    return db.blocksDao.watchChildBlocks(parentId);
  },
);

/// All block templates (ordered by title).
final blockTemplatesProvider = StreamProvider<List<BlockTemplate>>(
  (ref) =>
      ref.watch(databaseProvider).blockTemplatesDao.watchAllTemplates(),
);

/// All tags available in the DB (for the tag picker).
final allTagsProvider = StreamProvider<List<Tag>>(
  (ref) => ref.watch(databaseProvider).tagsDao.watchAllTags(),
);

/// Tags currently attached to a specific template.
final tagsForTemplateProvider = FutureProvider.family<List<Tag>, int>(
  (ref, templateId) =>
      ref.watch(databaseProvider).tagsDao.getTagsForTemplate(templateId),
);

/// Checklist items for a given block, streamed for live updates.
final checklistItemsProvider =
    StreamProvider.family<List<ChecklistItem>, int>(
  (ref, blockId) =>
      ref.watch(databaseProvider).checklistItemsDao.watchItemsByBlock(blockId),
);

/// Finds all overlapping pairs among block+template pairs.
List<((Block, BlockTemplate), (Block, BlockTemplate))> findOverlaps(
    List<(Block, BlockTemplate)> pairs) {
  final result = <((Block, BlockTemplate), (Block, BlockTemplate))>[];
  for (int i = 0; i < pairs.length; i++) {
    for (int j = i + 1; j < pairs.length; j++) {
      if (BlockValidator.timesOverlap(
        start1: pairs[i].$1.startTime,
        end1: pairs[i].$1.endTime,
        start2: pairs[j].$1.startTime,
        end2: pairs[j].$1.endTime,
      )) {
        result.add((pairs[i], pairs[j]));
      }
    }
  }
  return result;
}
