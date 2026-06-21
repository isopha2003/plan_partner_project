import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/block_templates_table.dart';

part 'block_templates_dao.g.dart';

@DriftAccessor(tables: [BlockTemplates])
class BlockTemplatesDao extends DatabaseAccessor<AppDatabase>
    with _$BlockTemplatesDaoMixin {
  BlockTemplatesDao(super.db);

  Stream<List<BlockTemplate>> watchAllTemplates() =>
      (select(blockTemplates)
            ..orderBy([(t) => OrderingTerm.asc(t.title)]))
          .watch();

  Future<BlockTemplate?> getTemplateById(int id) =>
      (select(blockTemplates)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<BlockTemplate?> getTemplateByTitle(String title) =>
      (select(blockTemplates)..where((t) => t.title.equals(title)))
          .getSingleOrNull();

  Future<int> insertTemplate(BlockTemplatesCompanion template) =>
      into(blockTemplates).insert(template);

  Future<bool> updateTemplate(BlockTemplate template) =>
      update(blockTemplates).replace(template);

  Future<int> deleteTemplate(int id) =>
      (delete(blockTemplates)..where((t) => t.id.equals(id))).go();
}
