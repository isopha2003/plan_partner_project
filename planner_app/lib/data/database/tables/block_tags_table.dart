import 'package:drift/drift.dart';

import 'blocks_table.dart';
import 'tags_table.dart';

class BlockTags extends Table {
  IntColumn get blockId => integer().references(Blocks, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {blockId, tagId};
}
