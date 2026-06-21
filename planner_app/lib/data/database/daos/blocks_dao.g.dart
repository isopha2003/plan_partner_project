// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blocks_dao.dart';

// ignore_for_file: type=lint
mixin _$BlocksDaoMixin on DatabaseAccessor<AppDatabase> {
  $BlockTemplatesTable get blockTemplates => attachedDatabase.blockTemplates;
  $RecurrenceRulesTable get recurrenceRules => attachedDatabase.recurrenceRules;
  $BlocksTable get blocks => attachedDatabase.blocks;
  BlocksDaoManager get managers => BlocksDaoManager(this);
}

class BlocksDaoManager {
  final _$BlocksDaoMixin _db;
  BlocksDaoManager(this._db);
  $$BlockTemplatesTableTableManager get blockTemplates =>
      $$BlockTemplatesTableTableManager(
        _db.attachedDatabase,
        _db.blockTemplates,
      );
  $$RecurrenceRulesTableTableManager get recurrenceRules =>
      $$RecurrenceRulesTableTableManager(
        _db.attachedDatabase,
        _db.recurrenceRules,
      );
  $$BlocksTableTableManager get blocks =>
      $$BlocksTableTableManager(_db.attachedDatabase, _db.blocks);
}
