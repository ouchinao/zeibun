import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeibun/data/egov/egov_api.dart';
import 'package:zeibun/data/repositories/law_repository.dart';

/// 決まった状態コードと本文を返し、呼ばれた回数を数える。
class _FixedAdapter implements HttpClientAdapter {
  _FixedAdapter(this.status, this.body);
  final int status;
  final String body;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls++;
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: ['text/html; charset=utf-8']
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final uri = Uri.parse('https://laws.e-gov.go.jp/api/2/laws');

  DioEgovApi apiWith(_FixedAdapter adapter) => DioEgovApi(
      dio: Dio(BaseOptions(
          responseType: ResponseType.bytes, validateStatus: (_) => true))
        ..httpClientAdapter = adapter,
      retryBaseDelay: Duration.zero);

  test('the 403 maintenance page is reported as maintenance without retrying',
      () async {
    final adapter =
        _FixedAdapter(403, '<title>ただいまシステムメンテナンス中です｜e-Gov 法令検索</title>');
    await expectLater(
        apiWith(adapter).getBytes(uri),
        throwsA(isA<EgovApiException>()
            .having((e) => e.kind, 'kind', EgovErrorKind.maintenance)));
    expect(adapter.calls, 1);
  });

  test('any other 403 stays a client error', () async {
    await expectLater(
        apiWith(_FixedAdapter(403, 'Forbidden')).getBytes(uri),
        throwsA(isA<EgovApiException>()
            .having((e) => e.kind, 'kind', EgovErrorKind.clientError)));
  });

  test('opening a law during maintenance is told apart from other failures',
      () {
    expect(classifyFetchError(EgovApiException(EgovErrorKind.maintenance, uri)),
        FetchFailure.maintenance);
    expect(classifyFetchError(EgovApiException(EgovErrorKind.serverError, uri)),
        FetchFailure.server);
  });
}
