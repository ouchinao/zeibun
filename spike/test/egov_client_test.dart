import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zeibun_spike/zeibun_spike.dart';

/// 実 API の代わりに、gzip 応答・5xx→200 の再試行・4xx を再現するローカルサーバ。
void main() {
  late HttpServer server;
  late EgovClient client;
  var flakyHits = 0;
  final log = <String>[];

  setUp(() async {
    flakyHits = 0;
    log.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final path = req.uri.path;
      final res = req.response;
      final wantsGzip = req.headers
              .value(HttpHeaders.acceptEncodingHeader)
              ?.contains('gzip') ==
          true;
      void send(int status, Object body, {String type = 'application/json'}) {
        final bytes = utf8.encode(body is String ? body : jsonEncode(body));
        res.statusCode = status;
        res.headers.contentType = ContentType.parse(type);
        if (wantsGzip && status == 200) {
          res.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
          res.add(gzip.encode(bytes));
        } else {
          res.add(bytes);
        }
        res.close();
      }

      if (path == '/api/2/laws') {
        final cd = req.uri.queryParameters['category_cd'];
        send(200, {
          'total_count': 1,
          'count': 1,
          'next_offset': null,
          'laws': [
            {
              'law_info': {
                'law_id': '340AC0000000034',
                'law_num': '昭和四十年法律第三十四号',
                'law_type': 'Act',
                'promulgation_date': '1965-03-31',
              },
              'revision_info': {
                'law_revision_id': '340AC0000000034_20260723_508AC0000000064',
                'law_title': '法人税法',
                'category': cd == '013' ? '国税' : '国債',
                'updated': '2026-07-23T10:12:00+09:00',
                'amendment_enforcement_date': '2026-07-23',
                'repeal_status': 'None',
                'current_revision_status': 'CurrentEnforced',
              },
            }
          ],
        });
      } else if (path.startsWith('/api/2/law_file/xml/')) {
        send(200, SyntheticLaw(articles: 3).toXmlString(),
            type: 'application/xml');
      } else if (path == '/api/2/flaky') {
        flakyHits++;
        if (flakyHits < 3) {
          send(503, {'code': '500001', 'message': 'busy'});
        } else {
          send(200, {'ok': true});
        }
      } else {
        send(400, {'code': '400004', 'message': '日付（asof等）が誤っています。'});
      }
    });
    client = EgovClient(
      baseUrl: Uri.parse('http://127.0.0.1:${server.port}/api/2'),
      maxRequestsPerSecond: 50,
      retryBaseDelay: const Duration(milliseconds: 10),
      onLog: log.add,
    );
  });

  tearDown(() async {
    client.close();
    await server.close(force: true);
  });

  test('decodes gzip and reports wire vs. body bytes', () async {
    final r = await client.laws({'category_cd': '013', 'limit': '1000'});
    expect(r.statusCode, 200);
    expect(r.headers[HttpHeaders.contentEncodingHeader], 'gzip');
    expect(r.wireBytes, lessThan(r.bytes.length));
    final laws = (r.json as Map)['laws'] as List;
    final law =
        LawSummary.fromApiRow((laws.first as Map).cast<String, dynamic>());
    expect(law.title, '法人税法');
    expect(law.category, '国税');
    expect(LawScope.tax.reasonFor(law), 'category:013');
  });

  test('retries 5xx with backoff and succeeds', () async {
    final r = await client.get('flaky');
    expect(r.statusCode, 200);
    expect(r.attempts, 3);
    expect(log.where((l) => l.startsWith('retry')), hasLength(2));
  });

  test('does not retry 4xx', () async {
    await expectLater(
      client.get('nope'),
      throwsA(isA<EgovHttpException>()
          .having((e) => e.statusCode, 'status', 400)
          .having((e) => e.body, 'body', contains('400004'))),
    );
    expect(log, isEmpty);
  });

  test('law_file xml round-trips through LawNode and LawParser', () async {
    final r =
        await client.lawFile('xml', '340AC0000000034_20260723_508AC0000000064');
    final law = LawNode.parseXmlString(r.bodyText);
    final records = const LawParser().parse(law);
    expect(records.where((x) => x.section == 'main'), hasLength(3));
  });

  test('throttles to maxRequestsPerSecond', () async {
    final slow = EgovClient(
      baseUrl: Uri.parse('http://127.0.0.1:${server.port}/api/2'),
      maxRequestsPerSecond: 10,
    );
    final sw = Stopwatch()..start();
    for (var i = 0; i < 5; i++) {
      await slow.laws(const {'limit': '1'});
    }
    slow.close();
    // 5 リクエスト → 4 間隔 × 100ms 以上
    expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(380));
  });
}
