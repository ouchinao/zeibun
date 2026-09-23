import 'package:flutter_test/flutter_test.dart';
import 'package:zeibun/data/db/database.dart';
import 'package:zeibun/data/repositories/law_repository.dart';
import 'package:zeibun/features/law_viewer/in_text_search.dart';
import 'package:zeibun/features/law_viewer/law_text.dart';

Article _article(int seq, String section, String text, {String? amendLawNum}) =>
    Article(
      id: seq,
      lawId: 'L',
      revisionId: 'R',
      seq: seq,
      section: section,
      supplAmendLawNum: amendLawNum,
      path: '$section/$seq',
      articleNum: '$seq',
      plainText: text,
      bodyJson: '{"tag":"Article","attr":{},"children":[]}',
    );

void main() {
  final text = LawText.from(BodyLoadResult(BodyStatus.fresh, [
    _article(1, 'main', '内国法人の所得の金額'),
    _article(2, 'main', '損金の額に算入する'),
    _article(3, 'main', '益金の額に算入する'),
    _article(4, 'suppl', 'この法律は施行する'),
    _article(5, 'suppl', '損金の額の経過措置', amendLawNum: '令和八年法律第一号'),
    _article(6, 'suppl', '損金の額の経過措置 その二', amendLawNum: '令和九年法律第一号'),
  ]));

  test('searches only the main provisions unless asked', () {
    final s = InTextSearch.run(text, '損金', includeSuppl: false);
    expect(s.hits, [(part: TextPart.main, group: 0, index: 1)]);
    expect(s.counter, '1/1');
  });

  test(
      'with supplementary provisions, hits follow the tab order: main first, '
      'then newest amendment group first', () {
    final s = InTextSearch.run(text, '損金', includeSuppl: true);
    expect(s.hits.map((h) => h.part),
        [TextPart.main, TextPart.suppl, TextPart.suppl]);
    // 附則グループは新しい改正が先（令和九年 → 令和八年）
    expect(text.supplGroups[0].amendLawNum, '令和九年法律第一号');
    expect(s.hits[1], (part: TextPart.suppl, group: 0, index: 0));
    expect(s.hits[2], (part: TextPart.suppl, group: 1, index: 0));
    expect(s.counter, '1/3');
  });

  test('every term must appear in the same article', () {
    final s = InTextSearch.run(text, '損金 経過措置', includeSuppl: true);
    expect(s.hits.every((h) => h.part == TextPart.suppl), isTrue);
    expect(s.hits, hasLength(2));
  });

  test('startAt moves the cursor to the first hit at or after that article',
      () {
    final s = InTextSearch.run(text, '算入', includeSuppl: false, startAt: 2);
    expect(s.hits.map((h) => h.index), [1, 2]);
    expect(s.current!.index, 2);
  });

  test('stepping wraps around in both directions', () {
    final s = InTextSearch.run(text, '損金', includeSuppl: true);
    expect(s.step(1).cursor, 1);
    expect(s.step(-1).cursor, 2);
    expect(s.step(3).cursor, 0);
  });

  test('an empty query yields no hits and no counter', () {
    final s = InTextSearch.run(text, '　', includeSuppl: true);
    expect(s.hits, isEmpty);
    expect(s.counter, isNull);
    expect(InTextSearch.run(text, 'ない語', includeSuppl: true).counter, '0 件');
  });
}
