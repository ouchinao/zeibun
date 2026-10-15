import 'package:test/test.dart';
import 'package:zeibun_core/zeibun_core.dart';

void main() {
  test('a parenthetical becomes a group without the brackets', () {
    expect(splitParenGroups('内国法人（公益法人等を除く。）は'), const [
      PlainSegment('内国法人'),
      ParenGroup([PlainSegment('公益法人等を除く。')]),
      PlainSegment('は'),
    ]);
  });

  test('nested parentheticals stay nested', () {
    expect(splitParenGroups('A（B（C）D）E'), const [
      PlainSegment('A'),
      ParenGroup([
        PlainSegment('B'),
        ParenGroup([PlainSegment('C')]),
        PlainSegment('D'),
      ]),
      PlainSegment('E'),
    ]);
  });

  test('an unclosed bracket and what follows it stay plain text', () {
    expect(splitParenGroups('A（B）C（D（E）F'), const [
      PlainSegment('A'),
      ParenGroup([PlainSegment('B')]),
      PlainSegment('C（D（E）F'),
    ]);
  });

  test('a closing bracket without its pair stays plain text', () {
    expect(splitParenGroups('A）B'), const [PlainSegment('A）B')]);
  });

  test('half-width brackets used for item numbers are not groups', () {
    expect(splitParenGroups('(1) 前号'), const [PlainSegment('(1) 前号')]);
  });
}
