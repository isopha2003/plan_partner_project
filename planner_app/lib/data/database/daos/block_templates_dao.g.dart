// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_templates_dao.dart';

// ignore_for_file: type=lint
mixin _$BlockTemplatesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BlockTemplatesTable get blockTemplates => attachedDatabase.blockTemplates;
  BlockTemplatesDaoManager get managers => BlockTemplatesDaoManager(this);
}

class BlockTemplatesDaoManager {
  final _$BlockTemplatesDaoMixin _db;
  BlockTemplatesDaoManager(this._db);
  $$BlockTemplatesTableTableManager get blockTemplates =>
      $$BlockTemplatesTableTableManager(
        _db.attachedDatabase,
        _db.blockTemplates,
      );
}
