import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/checklist_items_table.dart';

part 'checklist_items_dao.g.dart';

@DriftAccessor(tables: [ChecklistItems])
class ChecklistItemsDao extends DatabaseAccessor<AppDatabase>
    with _$ChecklistItemsDaoMixin {
  ChecklistItemsDao(super.db);

  Future<int> insertItem(ChecklistItemsCompanion item) =>
      into(checklistItems).insert(item);

  Future<List<ChecklistItem>> getItemsByBlock(int blockId) =>
      (select(checklistItems)
            ..where((i) => i.blockId.equals(blockId))
            ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
          .get();

  Future<List<ChecklistItem>> getChildItems(int parentItemId) =>
      (select(checklistItems)
            ..where((i) => i.parentItemId.equals(parentItemId))
            ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
          .get();

  Future<bool> updateItem(ChecklistItem item) =>
      update(checklistItems).replace(item);

  Stream<List<ChecklistItem>> watchItemsByBlock(int blockId) =>
      (select(checklistItems)
            ..where((i) => i.blockId.equals(blockId))
            ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
          .watch();

  Future<int> deleteItem(int id) =>
      (delete(checklistItems)..where((i) => i.id.equals(id))).go();
}
