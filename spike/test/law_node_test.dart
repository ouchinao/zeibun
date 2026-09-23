import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zeibun_spike/zeibun_spike.dart';

void main() {
  group('LawNode.fromJson', () {
    test('parses the {tag, attr, children} shape from the spec', () {
      final node = LawNode.parseJsonString(jsonEncode({
        'tag': 'Sentence',
        'attr': {'Num': '1', 'WritingMode': 'vertical'},
        'children': ['この法律は、処分、行政指導及び届出に関する手続並びに命令等を定める手続に関し、'],
      }));
      expect(node.tag, 'Sentence');
      expect(node.attr, {'Num': '1', 'WritingMode': 'vertical'});
      expect(node.text, startsWith('この法律は'));
    });

    test(
        'treats attr "" (empty string, as in the spec example) as no attributes',
        () {
      final node = LawNode.parseJsonString(
          '{"tag":"LawBody","attr":"","children":[{"tag":"LawTitle","attr":"","children":["保管金規則"]}]}');
      expect(node.attr, isEmpty);
      expect(node.firstChild('LawTitle')!.text, '保管金規則');
    });

    test('excludes Rt (ruby reading) from text', () {
      final node = LawNode('Sentence', const {}, [
        '旗',
        LawNode('Ruby', const {}, [
          '竿',
          LawNode('Rt', const {}, ['ざお']),
        ]),
        '側',
      ]);
      expect(node.text, '旗竿側');
    });
  });

  group('LawNode.fromXml', () {
    final xml =
        File('fixtures/spec_example_kokki_kokka.xml').readAsStringSync();
    final law = LawNode.parseXmlString(xml);

    test('drops whitespace-only text nodes and keeps full-width spaces', () {
      expect(law.tag, 'Law');
      expect(law.attr['LawType'], 'Act');
      final body = law.firstChild('LawBody')!;
      expect(body.firstChild('LawTitle')!.text, '国旗及び国歌に関する法律');
      final suppl = body.firstChild('SupplProvision')!;
      expect(suppl.firstChild('SupplProvisionLabel')!.text, '附　則');
      // 整形用の改行やインデントが children に残っていないこと
      expect(body.children.whereType<String>(), isEmpty);
    });

    test('mixed content with Ruby keeps text order', () {
      final suppl = law.firstChild('LawBody')!.firstChild('SupplProvision')!;
      final p3 = suppl.childrenNamed('Paragraph').elementAt(2);
      final sentence =
          p3.firstChild('ParagraphSentence')!.firstChild('Sentence')!;
      expect(sentence.text, contains('旗竿側に横の長さの百分の一偏した位置'));
      expect(sentence.text, isNot(contains('ざお')));
    });

    test('XML and JSON of the same law produce the same tree', () {
      final synth = SyntheticLaw(articles: 30);
      final fromXml = LawNode.parseXmlString(synth.toXmlString());
      final fromJson = LawNode.parseJsonString(synth.toJsonString());
      expect(jsonEncode(fromXml.toJson()), jsonEncode(fromJson.toJson()));
      expect(fromXml.elementCount, fromJson.elementCount);
    });
  });
}
