import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zeibun_core/zeibun_core.dart';

void main() {
  group('LawSummary.fromApiRow on a real asof response', () {
    final body = jsonDecode(
        File('test/fixtures/laws_category_cd_013_asof_excerpt.json')
            .readAsStringSync()) as Map<String, dynamic>;
    final rows = (body['laws'] as List)
        .map((r) => LawSummary.fromApiRow((r as Map).cast<String, dynamic>()))
        .toList();

    test('uses current_revision_info as the current revision', () {
      for (final l in rows) {
        expect(l.currentRevisionId, startsWith('${l.lawId}_'));
        expect(l.category, '国税');
        expect(LawScope.tax.reasonFor(l), 'category:013');
        expect(l.isReference, isFalse);
      }
    });

    test('detects pending amendments from the asof-side revision id', () {
      final pending = rows.where((l) => l.hasPendingAmendment).toList();
      expect(pending.length, greaterThanOrEqualTo(10));
      final sotoku = rows.firstWhere((l) => l.title == '租税特別措置法');
      expect(sotoku.hasPendingAmendment, isTrue);
      expect(sotoku.pendingRevisionId, isNot(sotoku.currentRevisionId));
      expect(sotoku.abbrevs, contains('租特法'));
    });
  });

  test('reference (repealed) laws are flagged, not excluded', () {
    final row = {
      'law_info': {
        'law_id': '133AC0000000067',
        'law_num': '明治三十三年法律第六十七号',
        'law_type': 'Act'
      },
      'revision_info': {
        'law_revision_id': '133AC0000000067_20180401_429AC0000000004',
        'law_title': '国税犯則取締法',
        'category': '国税',
        'repeal_status': 'Repeal',
        'repeal_date': '2018-04-01',
      },
    };
    final l = LawSummary.fromApiRow(row);
    expect(l.isReference, isTrue);
    expect(l.repealDate, '2018-04-01');
    expect(LawScope.tax.reasonFor(l), 'category:013');
  });

  test('category codes match the catalog names', () {
    expect(categoryCodeOf('国税'), '013');
    expect(categoryCodeOf('地方財政'), '036');
    expect(categoryCodes['023'], '国債');
    expect(categoryCodeOf(null), isNull);
  });

  test('scope rules against the catalog snapshot', () {
    final snapshot = jsonDecode(
            File('test/fixtures/catalog_tax_snapshot.json').readAsStringSync())
        as Map<String, dynamic>;
    var byReason = <String, int>{};
    for (final r in (snapshot['rows'] as List)) {
      final m = (r as Map).cast<String, dynamic>();
      final law = LawSummary(
        lawId: m['law_id'] as String,
        lawNum: m['law_num'] as String? ?? '',
        lawType: m['law_type'] as String? ?? '',
        title: m['title'] as String,
        category: m['category'] as String?,
      );
      final reason = LawScope.tax.reasonFor(law);
      if (reason != null) byReason[reason] = (byReason[reason] ?? 0) + 1;
    }
    expect(byReason['category:013'], 252);
    expect(byReason['title:036'], 46);
    expect(byReason['explicit'], LawScope.tax.explicitLawIds.length);
  });
}
