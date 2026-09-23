import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zeibun_spike/zeibun_spike.dart';

/// 実カタログのスナップショット（2026-09、分類=国税/地方財政 or 題名に「税」）に
/// 対して、設計書 §2 のスコープルールが期待どおりの集合を切り出すことを確認する。
void main() {
  final snapshot =
      jsonDecode(File('fixtures/catalog_tax_snapshot.json').readAsStringSync())
          as Map<String, dynamic>;
  final rows = (snapshot['rows'] as List)
      .map((r) => LawSummary.fromSnapshot((r as Map).cast<String, dynamic>()))
      .toList();

  test('official category codes resolve the names used in the catalog', () {
    expect(categoryCodeOf('国税'), '013');
    expect(categoryCodeOf('地方財政'), '036');
    expect(categoryCodeOf('財務通則'), '003');
    expect(categoryCodeOf('行政組織'), '011');
    expect(categoryCodes['023'], '国債'); // 調査メモ v0.1 の推定は誤り
    expect(categoryCodes['008'], '国有財産');
    expect(categoryCodes['021'], '行政手続');
    // カタログに現れる分類名はすべてコード表にある
    final names = rows.map((r) => r.category).whereType<String>().toSet();
    for (final n in names) {
      expect(categoryCodeOf(n), isNotNull, reason: n);
    }
  });

  test('tax scope selects 国税 whole + 地方財政 by title + explicit ids', () {
    final byReason = <String, List<LawSummary>>{};
    for (final r in rows) {
      final reason = LawScope.tax.reasonFor(r);
      if (reason != null) byReason.putIfAbsent(reason, () => []).add(r);
    }
    expect(byReason['category:013']!.length, 252);
    expect(byReason['title:036']!.length, 46);
    expect(byReason['explicit']!.length, LawScope.tax.explicitLawIds.length,
        reason: 'explicit ids must all exist in the catalog snapshot');
    final total = byReason.values.fold<int>(0, (n, l) => n + l.length);
    expect(total, inInclusiveRange(300, 320));

    final titles = byReason.values.expand((l) => l).map((r) => r.title).toSet();
    for (final t in [
      '所得税法',
      '法人税法',
      '消費税法',
      '相続税法',
      '租税特別措置法',
      '国税通則法',
      '国税徴収法',
      '地方税法',
      '地方税法施行令',
      '地方税法施行規則',
      '地方法人税法',
      '国税収納金整理資金に関する法律',
      '国税不服審判所組織令',
    ]) {
      expect(titles, contains(t));
    }
    // 地方交付税法は「税」を含むので入る（設計書 §2 のとおり）
    expect(titles, contains('地方交付税法'));
  });

  test('major tax laws are all in scope and have a current revision', () {
    final byId = {for (final r in rows) r.lawId: r};
    for (final id in majorTaxLaws.keys) {
      final law = byId[id];
      expect(law, isNotNull, reason: '$id ${majorTaxLaws[id]}');
      expect(law!.title, majorTaxLaws[id]);
      expect(LawScope.tax.reasonFor(law), isNotNull);
      expect(law.currentRevisionId, startsWith('${id}_'));
    }
    for (final id in benchmarkLawIds) {
      expect(majorTaxLaws.containsKey(id), isTrue);
    }
  });

  test('catalogQueries covers every rule with limit within the API default set',
      () {
    final q = LawScope.tax.catalogQueries();
    expect(q.first, {'category_cd': '013', 'limit': '1000'});
    expect(q[1], {'category_cd': '036', 'limit': '1000'});
    expect(q.length, 2 + LawScope.tax.explicitLawIds.length);
  });
}
