import 'package:test/test.dart';
import 'package:zeibun_core/zeibun_core.dart';

void main() {
  test('each term keeps what was typed first, then the statute words', () {
    expect(expandSearchTerms('ボーナス 源泉'), [
      ['ボーナス', '賞与'],
      ['源泉'],
    ]);
  });

  test('full-width input is normalized before looking up', () {
    expect(expandSearchTerms('マイナンバー')[0], ['マイナンバー', '個人番号']);
  });

  test('a word that only contains a known word is not expanded', () {
    expect(expandSearchTerms('給料日'), [
      ['給料日']
    ]);
  });
}
