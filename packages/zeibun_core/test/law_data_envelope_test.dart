import 'dart:io';

import 'package:test/test.dart';
import 'package:zeibun_core/zeibun_core.dart';

void main() {
  final xml = File('test/fixtures/law_data_426AC0000000011_地方法人税法.xml')
      .readAsStringSync();

  test('parses the law_data envelope', () {
    final env = LawDataEnvelope.parse(xml);
    expect(env.law.tag, 'Law');
    expect(env.lawId, '426AC0000000011');
    expect(env.title, '地方法人税法');
    expect(env.revisionId, startsWith('426AC0000000011_'));
    expect(env.enforcedAt, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
  });

  test('verifies the requested revision id', () {
    final env = LawDataEnvelope.parse(xml);
    env.verifyRevision(env.revisionId!);
    expect(() => env.verifyRevision('426AC0000000011_20000101_000000000000000'),
        throwsStateError);
  });

  test('accepts a bare Law element (law_file) without metadata', () {
    final env = LawDataEnvelope.parse(
        File('test/fixtures/law_file_426AC0000000011_地方法人税法.xml')
            .readAsStringSync());
    expect(env.law.tag, 'Law');
    expect(env.revisionId, isNull);
    expect(() => env.verifyRevision('x'), throwsStateError);
  });

  test('rejects DOCTYPE', () {
    expect(
        () => LawDataEnvelope.parse(
            '<!DOCTYPE x [<!ENTITY a "b">]><law_data_response/>'),
        throwsFormatException);
  });

  test('rejects unexpected roots', () {
    expect(() => LawDataEnvelope.parse('<html/>'), throwsFormatException);
  });

  test('parser accepts the envelope and yields the same records as law_file',
      () {
    const parser = LawParser();
    final a = parser.parse(LawDataEnvelope.parse(xml).law);
    final b = parser.parse(LawNode.parseXmlString(
        File('test/fixtures/law_file_426AC0000000011_地方法人税法.xml')
            .readAsStringSync()));
    expect(a.map((r) => r.path), b.map((r) => r.path));
  });
}
