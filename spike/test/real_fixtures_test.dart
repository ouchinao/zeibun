import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zeibun_spike/zeibun_spike.dart';

/// 実 API（2026-09-23 取得）のレスポンスに対するテスト。
void main() {
  const parser = LawParser();

  group('地方法人税法 (426AC0000000011)', () {
    final fromLawFile = LawNode.parseXmlString(
        File('fixtures/real/law_file_426AC0000000011_地方法人税法.xml')
            .readAsStringSync());
    final fromLawData = LawNode.parseXmlString(
        File('fixtures/real/law_data_426AC0000000011_地方法人税法.xml')
            .readAsStringSync());

    test('law_file returns the Law element directly', () {
      expect(fromLawFile.tag, 'Law');
      final h = parser.header(fromLawFile);
      expect(h.title, '地方法人税法');
      expect(h.lawNum, '平成二十六年法律第十一号');
    });

    test('law_data wraps the same Law in law_data_response', () {
      expect(fromLawData.tag, 'law_data_response');
      final rev = fromLawData.firstChild('revision_info')!;
      expect(rev.firstChild('law_revision_id')!.text,
          startsWith('426AC0000000011_'));
      final law = LawParser.unwrapLaw(fromLawData);
      expect(law.tag, 'Law');
      expect(parser.header(fromLawData).title, '地方法人税法');
    });

    test('both sources produce identical article records', () {
      final a = parser.parse(fromLawFile);
      final b = parser.parse(fromLawData);
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].path, b[i].path);
        expect(a[i].plainText, b[i].plainText);
      }
    });

    test('article records look like a real tax law', () {
      final records = parser.parse(fromLawFile);
      final main = records.where((r) => r.section == 'main').toList();
      expect(main.length, greaterThanOrEqualTo(20));
      expect(main.first.articleTitle, '第一条');
      expect(main.first.caption, '（趣旨）');
      expect(main.first.breadcrumb, startsWith('第一章'));
      expect(main.first.plainText, contains('地方法人税'));
      // 附則は複数の改正法令分がある
      final suppl = records.where((r) => r.section == 'suppl');
      expect(
          suppl.map((r) => r.supplAmendLawNum).toSet().length, greaterThan(3));
      // ルビの読みは平文に混ざらない
      expect(records.any((r) => r.plainText.contains('<Rt>')), isFalse);
      // 条番号は API の Num 形式
      for (final r in main) {
        expect(r.articleNum, matches(RegExp(r'^\d+(_\d+)*$')), reason: r.path);
      }
    });
  });

  group('/laws with asof=2099-12-31 (excerpt of category_cd=013)', () {
    final body = jsonDecode(
        File('fixtures/real/laws_category_cd_013_asof_excerpt.json')
            .readAsStringSync()) as Map<String, dynamic>;

    test('every row has current_revision_info alongside revision_info', () {
      final rows = (body['laws'] as List).cast<Map<dynamic, dynamic>>();
      expect(rows, isNotEmpty);
      for (final row in rows) {
        expect(row['current_revision_info'], isA<Map<dynamic, dynamic>>());
        final cur = (row['current_revision_info'] as Map);
        // current_revision_info.law_revision_id は asof 無しの一覧の現行と一致する
        // （252 件で確認）。一方 current_revision_status は asof 基準で評価される
        // らしく PreviousEnforced が混ざる（252 件中 13 件）ので、判定には使わない。
        expect(cur['law_revision_id'],
            startsWith(row['law_info']['law_id'] as String));
        expect(cur['current_revision_status'],
            anyOf('CurrentEnforced', 'PreviousEnforced'));
        expect(
            (cur['amendment_enforcement_date'] as String)
                .compareTo('2026-09-23'),
            lessThanOrEqualTo(0));
      }
    });

    test('pending amendments are detected by comparing the two revision ids',
        () {
      final rows = (body['laws'] as List).cast<Map<dynamic, dynamic>>();
      final pending = rows.where((row) =>
          (row['revision_info'] as Map)['law_revision_id'] !=
          (row['current_revision_info'] as Map)['law_revision_id']);
      expect(pending.length, greaterThanOrEqualTo(10));
      final sample = pending.first;
      expect((sample['revision_info'] as Map)['current_revision_status'],
          'UnEnforced');
      // 現行側を LawSummary に取り込める
      final law = LawSummary.fromApi({
        'law_info': sample['law_info'],
        'revision_info': sample['current_revision_info'],
      });
      expect(LawScope.tax.reasonFor(law), 'category:013');
      expect(law.currentRevisionStatus, 'CurrentEnforced');
    });
  });

  test('/laws?category_cd=023 is 国債, not 国税', () {
    final body = jsonDecode(
        File('fixtures/real/laws_category_cd_023_limit1.json')
            .readAsStringSync()) as Map<String, dynamic>;
    final law = LawSummary.fromApi(
        ((body['laws'] as List).first as Map).cast<String, dynamic>());
    expect(law.category, '国債');
    expect(LawScope.tax.reasonFor(law), isNull);
  });

  test('/laws?law_id=<explicit id> returns exactly that law', () {
    final body = jsonDecode(
        File('fixtures/real/laws_law_id_329AC0000000036_asof.json')
            .readAsStringSync()) as Map<String, dynamic>;
    expect(body['total_count'], 1);
    final row = ((body['laws'] as List).first as Map).cast<String, dynamic>();
    final law = LawSummary.fromApi({
      'law_info': row['law_info'],
      'revision_info': row['current_revision_info'],
    });
    expect(law.title, '国税収納金整理資金に関する法律');
    expect(LawScope.tax.reasonFor(law), 'explicit');
  });

  test('/keyword returns highlighted sentences with elm-style positions', () {
    final body = jsonDecode(
            File('fixtures/real/keyword_役員給与_013_036.json').readAsStringSync())
        as Map<String, dynamic>;
    expect(body['total_count'], greaterThan(0));
    final item = ((body['items'] as List).first as Map).cast<String, dynamic>();
    final sentence =
        ((item['sentences'] as List).first as Map).cast<String, dynamic>();
    expect(sentence['text'], contains('<span>役員給与</span>'));
    expect(sentence['position'], isA<String>());
  });

  test('/law_revisions lists past, current and unenforced revisions', () {
    final body = jsonDecode(
        File('fixtures/real/law_revisions_340AC0000000034_法人税法.json')
            .readAsStringSync()) as Map<String, dynamic>;
    final revs = (body['revisions'] as List).cast<Map<dynamic, dynamic>>();
    final statuses = revs.map((r) => r['current_revision_status']).toSet();
    expect(statuses,
        containsAll(['CurrentEnforced', 'PreviousEnforced', 'UnEnforced']));
    expect(revs.where((r) => r['current_revision_status'] == 'CurrentEnforced'),
        hasLength(1));
  });
}
