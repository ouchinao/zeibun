import 'package:test/test.dart';
import 'package:zeibun_core/zeibun_core.dart';

void main() {
  final req = EgovRequests();

  test('catalog queries carry asof far-future and json format', () {
    final uris = req.catalog(LawScope.tax);
    expect(uris.length, 2 + LawScope.tax.explicitLawIds.length);
    final first = uris.first;
    expect(first.host, 'laws.e-gov.go.jp');
    expect(first.path, '/api/2/laws');
    expect(first.queryParameters['category_cd'], '013');
    expect(first.queryParameters['asof'], '2099-12-31');
    expect(first.queryParameters['response_format'], 'json');
    expect(first.queryParameters.containsKey('repeal_status'), isFalse);
    expect(uris.last.queryParameters['law_id'], isNotNull);
  });

  test('law_data XML omits amendment suppl provisions by default', () {
    final u = req.lawDataXml('340AC0000000034_20260812_508AC0000000064');
    expect(u.path, '/api/2/law_data/340AC0000000034_20260812_508AC0000000064');
    expect(u.queryParameters, {
      'response_format': 'xml',
      'law_full_text_format': 'xml',
      'omit_amendment_suppl_provision': 'true',
    });
    final full = req.lawDataXml('340AC0000000034_20260812_508AC0000000064',
        includeAmendmentSuppl: true);
    expect(full.queryParameters.containsKey('omit_amendment_suppl_provision'),
        isFalse);
  });

  test('rejects malformed ids before building a URL', () {
    expect(() => req.lawDataXml('../etc/passwd'), throwsArgumentError);
    expect(() => req.lawDataXml('340AC0000000034'), throwsArgumentError);
    expect(() => req.lawRevisions('340ac0000000034'), throwsArgumentError);
    expect(() => req.laws({'law_id': '1; DROP TABLE'}), throwsArgumentError);
    expect(() => EgovRequests.egovLawPage('x'), throwsArgumentError);
    expect(EgovRequests.egovLawPage('340AC0000000034').toString(),
        'https://laws.e-gov.go.jp/law/340AC0000000034');
  });

  test('id patterns', () {
    expect(EgovRequests.isValidLawId('321CONSTITUTION'), isTrue);
    expect(
        EgovRequests.isValidRevisionId(
            '332AC0000000026_20300101_505AC0000000003'),
        isTrue);
    expect(EgovRequests.isValidArticleNum('42_12_5'), isTrue);
    expect(EgovRequests.isValidArticleNum('42_'), isFalse);
  });

  test('keyword search is scoped to the tax categories', () {
    final u = req.keyword('役員給与');
    expect(u.queryParameters['category_cd'], '013,036');
    expect(u.queryParameters['keyword'], '役員給与');
  });
}
