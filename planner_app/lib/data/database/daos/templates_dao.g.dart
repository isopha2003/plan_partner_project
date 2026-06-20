// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'templates_dao.dart';

// ignore_for_file: type=lint
mixin _$TemplatesDaoMixin on DatabaseAccessor<AppDatabase> {
  $TemplatesTable get templates => attachedDatabase.templates;
  $TemplateBlocksTable get templateBlocks => attachedDatabase.templateBlocks;
  TemplatesDaoManager get managers => TemplatesDaoManager(this);
}

class TemplatesDaoManager {
  final _$TemplatesDaoMixin _db;
  TemplatesDaoManager(this._db);
  $$TemplatesTableTableManager get templates =>
      $$TemplatesTableTableManager(_db.attachedDatabase, _db.templates);
  $$TemplateBlocksTableTableManager get templateBlocks =>
      $$TemplateBlocksTableTableManager(
        _db.attachedDatabase,
        _db.templateBlocks,
      );
}
