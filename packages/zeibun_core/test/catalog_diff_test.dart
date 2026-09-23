import 'package:test/test.dart';
import 'package:zeibun_core/zeibun_core.dart';

LawSummary law(String id, String rev, String updated, {String? pending}) =>
    LawSummary(
      lawId: id,
      lawNum: '',
      lawType: 'Act',
      title: id,
      currentRevisionId: rev,
      updated: updated,
      pendingRevisionId: pending,
    );

void main() {
  test('classifies added / revised / corrected / unchanged / missing', () {
    final remote = [
      law('A', 'A_1', 't1'),
      law('B', 'B_2', 't2'),
      law('C', 'C_1', 't3'),
      law('D', 'D_1', 't1', pending: 'D_9'),
    ];
    final local = [
      const LocalLawState(
          lawId: 'B', currentRevisionId: 'B_1', catalogUpdated: 't1'),
      const LocalLawState(
          lawId: 'C', currentRevisionId: 'C_1', catalogUpdated: 't1'),
      const LocalLawState(
          lawId: 'D', currentRevisionId: 'D_1', catalogUpdated: 't1'),
      const LocalLawState(
          lawId: 'Z', currentRevisionId: 'Z_1', catalogUpdated: 't1'),
    ];
    final diff = diffCatalog(remote: remote, local: local);
    final kinds = {for (final c in diff.changes) c.lawId: c.kind};
    expect(kinds, {
      'A': CatalogChangeKind.added,
      'B': CatalogChangeKind.revised,
      'C': CatalogChangeKind.corrected,
      'D': CatalogChangeKind.unchanged,
      'Z': CatalogChangeKind.missing,
    });
    expect(diff.added, 1);
    expect(diff.revised, 1);
    expect(diff.corrected, 1);
    expect(diff.missing, 1);
    expect(diff.pending, 1);
    expect(diff.needsRefetch.map((c) => c.lawId), ['B', 'C']);
    expect(
        diff.ofKind(CatalogChangeKind.revised).first.previousRevisionId, 'B_1');
  });

  test('a pending amendment alone is not a change', () {
    final diff = diffCatalog(
      remote: [law('D', 'D_1', 't1', pending: 'D_9')],
      local: [
        const LocalLawState(
            lawId: 'D', currentRevisionId: 'D_1', catalogUpdated: 't1'),
      ],
    );
    expect(diff.changes.single.kind, CatalogChangeKind.unchanged);
    expect(diff.pending, 1);
  });
}
