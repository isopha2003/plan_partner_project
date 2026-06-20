import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/template_blocks_table.dart';
import '../tables/templates_table.dart';

part 'templates_dao.g.dart';

@DriftAccessor(tables: [Templates, TemplateBlocks])
class TemplatesDao extends DatabaseAccessor<AppDatabase>
    with _$TemplatesDaoMixin {
  TemplatesDao(super.db);

  Future<int> insertTemplate(TemplatesCompanion template) =>
      into(templates).insert(template);

  Future<Template?> getTemplateById(int id) =>
      (select(templates)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertTemplateBlock(TemplateBlocksCompanion block) =>
      into(templateBlocks).insert(block);

  Future<List<TemplateBlock>> getTemplateBlocks(int templateId) =>
      (select(templateBlocks)
            ..where((b) => b.templateId.equals(templateId))
            ..orderBy([(b) => OrderingTerm.asc(b.sortOrder)]))
          .get();
}
