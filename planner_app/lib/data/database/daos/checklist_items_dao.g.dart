// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_items_dao.dart';

// ignore_for_file: type=lint
mixin _$ChecklistItemsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BlockTemplatesTable get blockTemplates => attachedDatabase.blockTemplates;
  $RecurrenceRulesTable get recurrenceRules => attachedDatabase.recurrenceRules;
  $BlocksTable get blocks => attachedDatabase.blocks;
  $ChecklistItemsTable get checklistItems => attachedDatabase.checklistItems;
  ChecklistItemsDaoManager get managers => ChecklistItemsDaoManager(this);
}

class ChecklistItemsDaoManager {
  final _$ChecklistItemsDaoMixin _db;
  ChecklistItemsDaoManager(this._db);
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
  $$ChecklistItemsTableTableManager get checklistItems =>
      $$ChecklistItemsTableTableManager(
        _db.attachedDatabase,
        _db.checklistItems,
      );
}
