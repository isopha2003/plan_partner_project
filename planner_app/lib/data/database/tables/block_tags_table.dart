import 'package:drift/drift.dart';

import 'block_templates_table.dart';
import 'tags_table.dart';

/// Many-to-many join between block templates and tags.
/// Tags are attached at the template level, not the instance level.
class BlockTags extends Table {
  IntColumn get blockTemplateId =>
      integer().references(BlockTemplates, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {blockTemplateId, tagId};
}
