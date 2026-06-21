import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/domain/services/block_validator.dart';

void main() {
  group('BlockValidator - 중첩 깊이 검증', () {
    test('root-level block (parentParentId == null) is always valid', () {
      expect(BlockValidator.validateTimeblocNesting(null), isNull);
    });

    test('depth-1 child (parent has no parent) is valid', () {
      // Parent is a root block, so its parentId is null
      expect(BlockValidator.validateTimeblocNesting(null), isNull);
    });

    test('depth-2 child is rejected with an error message', () {
      // Parent already has parentId != null → would create depth 2
      final error = BlockValidator.validateTimeblocNesting(42);
      expect(error, isNotNull);
      expect(error, contains('one level deep'));
    });
  });

  group('BlockValidator - 시간 겹침 검사', () {
    DateTime t(int h, int m) => DateTime(2026, 6, 21, h, m);

    test('non-overlapping blocks return false', () {
      expect(
        BlockValidator.timesOverlap(
          start1: t(9, 0), end1: t(10, 0),
          start2: t(10, 0), end2: t(11, 0),
        ),
        false,
      );
    });

    test('overlapping blocks return true', () {
      expect(
        BlockValidator.timesOverlap(
          start1: t(9, 0), end1: t(10, 30),
          start2: t(10, 0), end2: t(11, 0),
        ),
        true,
      );
    });

    test('one block fully inside another overlaps', () {
      expect(
        BlockValidator.timesOverlap(
          start1: t(9, 0), end1: t(12, 0),
          start2: t(10, 0), end2: t(11, 0),
        ),
        true,
      );
    });

    test('adjacent blocks (end == start) do not overlap', () {
      expect(
        BlockValidator.timesOverlap(
          start1: t(9, 0), end1: t(10, 0),
          start2: t(10, 0), end2: t(11, 0),
        ),
        false,
      );
    });

    test('null times never overlap', () {
      expect(
        BlockValidator.timesOverlap(
          start1: null, end1: t(10, 0),
          start2: t(9, 0), end2: t(11, 0),
        ),
        false,
      );
    });

    test('two blocks with same start and end overlap', () {
      expect(
        BlockValidator.timesOverlap(
          start1: t(9, 0), end1: t(10, 0),
          start2: t(9, 0), end2: t(10, 0),
        ),
        true,
      );
    });
  });
}
