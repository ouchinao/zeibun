import 'dart:io';

import 'package:test/test.dart';
import 'package:zeibun_spike/zeibun_spike.dart';

void main() {
  const parser = LawParser();

  group('LawParser on the spec example (国旗及び国歌に関する法律)', () {
    final law = LawNode.parseXmlString(
        File('fixtures/spec_example_kokki_kokka.xml').readAsStringSync());
    final records = parser.parse(law);

    test('header', () {
      final h = parser.header(law);
      expect(h.lawNum, '平成十一年法律第百二十七号');
      expect(h.title, '国旗及び国歌に関する法律');
    });

    test('main provision articles become one record each', () {
      final main = records.where((r) => r.section == 'main').toList();
      expect(main.map((r) => r.articleNum), ['1', '2']);
      expect(main[0].articleTitle, '第一条');
      expect(main[0].caption, '（国旗）');
      expect(main[0].path, 'main/Article_1');
      expect(
          main[0].plainText, '（国旗）\n第一条\n国旗は、日章旗とする。\n２　日章旗の制式は、別記第一のとおりとする。');
    });

    test('supplementary provision without articles becomes one virtual record',
        () {
      final suppl = records.where((r) => r.section == 'suppl').toList();
      expect(suppl, hasLength(1));
      expect(suppl[0].articleNum, isNull);
      expect(suppl[0].path, 'suppl/Paragraphs');
      expect(suppl[0].plainText, contains('（施行期日）\n１　この法律は、公布の日から施行する。'));
      expect(suppl[0].plainText, contains('３　日章旗の制式については'));
      expect(suppl[0].plainText, isNot(contains('ざお')));
    });

    test('appendix notes become appdx records with table cells tab-separated',
        () {
      final appdx = records.where((r) => r.section == 'appdx').toList();
      expect(appdx, hasLength(2));
      expect(appdx[0].articleTitle, '別記第一');
      expect(appdx[0].caption, '（第一条関係）');
      expect(appdx[0].plainText, contains('一　寸法の割合及び日章の位置'));
      expect(appdx[1].articleTitle, '別記第二');
    });

    test('seq is contiguous and in document order', () {
      expect(
          records.map((r) => r.seq), List.generate(records.length, (i) => i));
      expect(records.map((r) => r.section),
          ['main', 'main', 'suppl', 'appdx', 'appdx']);
    });
  });

  group('LawParser on tax-law-like structures', () {
    final law = SyntheticLaw(articles: 120, supplProvisions: 2).build();
    final records = parser.parse(law);

    test('breadcrumb carries Part > Chapter titles', () {
      final first = records.first;
      expect(first.breadcrumb, '第一編　総則 > 第1章　各事業年度の所得の金額の計算');
      // 第 51 条は枝番（51_4）になるので 52 条で見る
      final art52 = records.firstWhere((r) => r.articleNum == '52');
      expect(art52.breadcrumb, endsWith('第2章　各事業年度の所得の金額の計算'));
    });

    test('branch article numbers (第N条の4) keep the API Num form', () {
      final branch = records.where((r) => r.articleNum?.contains('_') == true);
      expect(branch, isNotEmpty);
      expect(branch.first.articleNum, '1_4');
      expect(branch.first.articleTitle, '第1条の4');
      expect(branch.first.path, 'main/Article_1_4');
    });

    test('OldNum paragraphs get their number from the Num attribute', () {
      final suppl = records.where((r) => r.section == 'suppl').toList();
      // 2 附則 × (仮想条 + 第三条)
      expect(suppl, hasLength(4));
      expect(suppl[0].supplAmendLawNum, '令和1年法律第10号');
      expect(suppl[0].path, 'suppl[令和1年法律第10号]/Paragraphs');
      expect(suppl[0].plainText, contains('\n2　内国法人'));
      expect(suppl[1].articleNum, '3');
      expect(suppl[1].path, 'suppl[令和1年法律第10号]/Article_3');
    });

    test('items and table cells are line / tab separated in plain text', () {
      final a = records.first;
      final lines = a.plainText.split('\n');
      expect(lines, contains('一　当該事業年度の収益の額で第1号に掲げるもの'));
      expect(lines.any((l) => l == '区分0-0\t区分0-1\t区分0-2'), isTrue,
          reason: a.plainText);
    });

    test('appendix table at the end is an appdx record', () {
      expect(records.last.section, 'appdx');
      expect(records.last.articleTitle, '別表第一');
      expect(records.last.path, 'appdx/AppdxTable_1');
    });

    test('record count = articles + suppl records + appdx', () {
      expect(records.where((r) => r.section == 'main').length, 120);
      expect(records.length, 120 + 4 + 1);
    });
  });
}
