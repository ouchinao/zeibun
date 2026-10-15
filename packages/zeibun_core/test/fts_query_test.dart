import 'package:test/test.dart';
import 'package:zeibun_core/zeibun_core.dart';

void main() {
  test('terms of 3+ characters go to MATCH, shorter ones to LIKE', () {
    final q = FtsQuery.parse('役員給与 損金 の');
    expect(q.matchTerms, ['役員給与']);
    expect(q.likeTerms, ['損金', 'の']);
    expect(q.matchExpression, '"役員給与"');
    expect(q.likePatternGroups, [
      ['%損金%'],
      ['%の%']
    ]);
  });

  test('MATCH terms are quoted so FTS5 operators are not interpreted', () {
    final q = FtsQuery.parse('OR NOT (a"b) col:x');
    expect(q.matchExpression, '"not" AND "(a""b)" AND "col:x"');
    expect(q.likeTerms, ['or']);
  });

  test('LIKE wildcards inside a short term are stripped', () {
    expect(FtsQuery.parse('%_').likePatternGroups, isEmpty);
    expect(FtsQuery.parse('a%').likePatternGroups, [
      ['%a%']
    ]);
  });

  test('blank input is empty and has no MATCH expression', () {
    final q = FtsQuery.parse('　 ');
    expect(q.isEmpty, isTrue);
    expect(q.matchExpression, isNull);
  });

  test('a practitioner word also matches the word the statutes use', () {
    final q = FtsQuery.parse('インボイス 登録');
    expect(q.terms, ['インボイス', '登録']);
    expect(q.matchExpression, '("インボイス" OR "適格請求書")');
    expect(q.likePatternGroups, [
      ['%登録%']
    ]);
    expect(q.highlightTerms, ['インボイス', '適格請求書', '登録']);
  });

  test('a group with a short alternative goes to LIKE as a whole', () {
    final q = FtsQuery.parse('給料');
    expect(q.matchExpression, isNull);
    expect(q.likePatternGroups, [
      ['%給料%', '%給与%']
    ]);
  });
}
