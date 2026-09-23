import 'package:test/test.dart';
import 'package:zeibun_core/zeibun_core.dart';

void main() {
  group('normalizeWidth', () {
    test('converts full-width ASCII and ideographic space', () {
      expect(normalizeWidth('第２２条　ＡＢＣ（ａ）'), '第22条 ABC(a)');
    });
    test('leaves kana and kanji alone', () {
      expect(normalizeWidth('租税特別措置法・ほうじんぜいほう'), '租税特別措置法・ほうじんぜいほう');
    });
  });

  group('parseJapaneseNumber', () {
    test('arabic, full-width, kanji with units, positional kanji', () {
      expect(parseJapaneseNumber('22'), 22);
      expect(parseJapaneseNumber('２２'), 22);
      expect(parseJapaneseNumber('二十二'), 22);
      expect(parseJapaneseNumber('百三'), 103);
      expect(parseJapaneseNumber('三百八十九'), 389);
      expect(parseJapaneseNumber('千'), 1000);
      expect(parseJapaneseNumber('一〇二'), 102);
      expect(parseJapaneseNumber('十'), 10);
      expect(parseJapaneseNumber('六十六'), 66);
    });
    test('rejects non-numbers', () {
      expect(parseJapaneseNumber('条'), isNull);
      expect(parseJapaneseNumber(''), isNull);
    });
  });

  group('parseArticleReference', () {
    test('law + arabic article', () {
      final r = parseArticleReference('法人税法22条')!;
      expect(r.lawQuery, '法人税法');
      expect(r.articleNum, '22');
      expect(r.paragraph, isNull);
    });
    test('abbreviation + full-width digits without 条', () {
      final r = parseArticleReference('法法２２')!;
      expect(r.lawQuery, '法法');
      expect(r.articleNum, '22');
    });
    test('branch numbers (の)', () {
      final r = parseArticleReference('措法42の12の5')!;
      expect(r.lawQuery, '措法');
      expect(r.articleNum, '42_12_5');
      expect(r.display, '第42条の12条の5条'.replaceAll('条の', '条の'));
    });
    test('kanji article and paragraph', () {
      final r = parseArticleReference('所得税法第二十二条第一項')!;
      expect(r.lawQuery, '所得税法');
      expect(r.articleNum, '22');
      expect(r.paragraph, 1);
    });
    test('kanji branch', () {
      final r = parseArticleReference('法人税法第六十六条の四')!;
      expect(r.articleNum, '66_4');
    });
    test('plain law name is not an article reference', () {
      expect(parseArticleReference('法人税法'), isNull);
      expect(parseArticleReference('損金'), isNull);
    });
  });

  group('articleNumFromTitle', () {
    test('converts ArticleTitle to Article@Num form', () {
      expect(articleNumFromTitle('第二十二条'), '22');
      expect(articleNumFromTitle('第六十六条の四'), '66_4');
      expect(articleNumFromTitle('第四十二条の十二の五'), '42_12_5');
      expect(articleNumFromTitle('附　則'), isNull);
    });
  });
}
