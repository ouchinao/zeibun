import 'package:test/test.dart';
import 'package:zeibun_core/zeibun_core.dart';

void main() {
  test('terms of 3+ characters go to MATCH, shorter ones to LIKE', () {
    final q = FtsQuery.parse('役員給与 損金 の');
    expect(q.matchTerms, ['役員給与']);
    expect(q.likeTerms, ['損金', 'の']);
    expect(q.matchExpression, '"役員給与"');
    expect(q.likePatterns, ['%損金%', '%の%']);
  });

  test('MATCH terms are quoted so FTS5 operators are not interpreted', () {
    final q = FtsQuery.parse('OR NOT (a"b) col:x');
    expect(q.matchExpression, '"not" AND "(a""b)" AND "col:x"');
    expect(q.likeTerms, ['or']);
  });

  test('LIKE wildcards inside a short term are stripped', () {
    expect(FtsQuery.parse('%_').likePatterns, isEmpty);
    expect(FtsQuery.parse('a%').likePatterns, ['%a%']);
  });

  test('blank input is empty and has no MATCH expression', () {
    final q = FtsQuery.parse('　 ');
    expect(q.isEmpty, isTrue);
    expect(q.matchExpression, isNull);
  });
}
