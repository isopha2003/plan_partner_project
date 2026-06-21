// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tags_dao.dart';

// ignore_for_file: type=lint
mixin _$TagsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TagsTable get tags => attachedDatabase.tags;
  $BlockTemplatesTable get blockTemplates => attachedDatabase.blockTemplates;
  $BlockTagsTable get blockTags => attachedDatabase.blockTags;
  TagsDaoManager get managers => TagsDaoManager(this);
}

class TagsDaoManager {
  final _$TagsDaoMixin _db;
  TagsDaoManager(this._db);
  $$TagsTableTableManager get tags =>
      $$TagsTableTableManager(_db.attachedDatabase, _db.tags);
  $$BlockTemplatesTableTableManager get blockTemplates =>
      $$BlockTemplatesTableTableManager(
        _db.attachedDatabase,
        _db.blockTemplates,
      );
  $$BlockTagsTableTableManager get blockTags =>
      $$BlockTagsTableTableManager(_db.attachedDatabase, _db.blockTags);
}
