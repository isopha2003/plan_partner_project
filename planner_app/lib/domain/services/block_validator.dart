/// Domain rules for timeblock constraints.
class BlockValidator {
  BlockValidator._();

  /// Returns an error message if adding a child timeblock to [parentParentId]
  /// would exceed the 1-level nesting limit, or null if valid.
  ///
  /// [parentParentId] is the `parentId` of the proposed parent block.
  /// If it is non-null, the proposed parent already has a parent, meaning
  /// any child would be at depth 2 — which is forbidden.
  static String? validateTimeblocNesting(int? parentParentId) {
    if (parentParentId != null) {
      return 'Timeblocks can only be nested one level deep. '
          'The selected parent already has a parent.';
    }
    return null;
  }

  /// Returns true if two time ranges overlap.
  ///
  /// Null times (unscheduled blocks) never overlap.
  /// Uses half-open interval semantics: [start, end).
  static bool timesOverlap({
    required DateTime? start1,
    required DateTime? end1,
    required DateTime? start2,
    required DateTime? end2,
  }) {
    if (start1 == null || end1 == null || start2 == null || end2 == null) {
      return false;
    }
    return start1.isBefore(end2) && start2.isBefore(end1);
  }
}
