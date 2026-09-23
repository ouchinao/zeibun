import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// e-Gov 法令API v2 への HTTP アクセス。URL の組み立ては `zeibun_core` の
/// `EgovRequests` が行い、ここは取得だけを担当する（テストでは差し替える）。
abstract class EgovApi {
  /// 文字列ではなくバイト列を返すのは、16MB の本文を Isolate 側でデコードして
  /// メインスレッドに巨大な文字列を作らないため。
  Future<Uint8List> getBytes(Uri uri);

  Future<String> getText(Uri uri) async => utf8.decode(await getBytes(uri));

  Future<Map<String, dynamic>> getJson(Uri uri) async =>
      jsonDecode(await getText(uri)) as Map<String, dynamic>;
}

/// 失敗の種類。`statusCode` の有無で判定しないのは、タイムアウトも受信上限超過も
/// 再試行の打ち切りも statusCode が null になり、区別できないため。
enum EgovErrorKind {
  network,
  timeout,
  serverError,
  clientError,
  tooLarge;

  /// serverError を含めないのは、e-Gov 側の障害を「オフライン」と出すと
  /// 利用者が自分の回線を疑うため。
  bool get isOffline => this == network || this == timeout;
}

class EgovApiException implements Exception {
  EgovApiException(this.kind, this.uri, {this.statusCode, this.message = ''});
  final EgovErrorKind kind;
  final Uri uri;
  final int? statusCode;
  final String message;

  @override
  String toString() =>
      'EgovApiException(${kind.name} $statusCode $uri): $message';
}

/// dio 実装。
///
/// - 証明書ピン留めや検証の緩和はしない。政府ドメインの証明書更新で全ユーザーが
///   止まるリスクの方が MITM より大きく、OS の信頼ストアで足りる（設計書 §11 S）
/// - `validateStatus` を常に true にして自前で分岐するのは、5xx とタイムアウトだけ
///   再試行し、4xx は即座に失敗させたいから（dio の既定はどちらも例外になる）
/// - 再試行にジッタを入れるのは、多数の端末が同時刻に起動したときに e-Gov へ
///   再試行が同期して集中しないようにするため
/// - 受信上限は gzip 爆弾でメモリを使い切られないため。`<!DOCTYPE` の拒否は
///   ここではなく XML を解釈する `LawDataEnvelope` が行う（JSON には関係ない）
class DioEgovApi extends EgovApi {
  DioEgovApi({
    Dio? dio,
    this.maxRequestsPerSecond = 5,
    this.maxAttempts = 3,
    this.maxBodyBytes = 64 * 1024 * 1024,
    this.retryBaseDelay = const Duration(seconds: 1),
    this.userAgent = 'zeibun/0.1 (+https://github.com/ouchinao/zeibun)',
    Random? random,
  })  : _random = random ?? Random(),
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
              responseType: ResponseType.bytes,
              headers: const {
                'Accept': 'application/json, application/xml, */*'
              },
              validateStatus: (_) => true,
            ));

  final Dio _dio;
  final int maxRequestsPerSecond;
  final int maxAttempts;
  final int maxBodyBytes;
  final Duration retryBaseDelay;
  final String userAgent;
  final Random _random;
  DateTime _nextSlot = DateTime.fromMillisecondsSinceEpoch(0);

  static const _retryable = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.connectionError,
    DioExceptionType.unknown,
  };

  @override
  Future<Uint8List> getBytes(Uri uri) async {
    late EgovApiException lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (attempt > 1) {
        final base = retryBaseDelay * (1 << (attempt - 2));
        final jitter = 0.75 + _random.nextDouble() * 0.5;
        await Future<void>.delayed(base * jitter);
      }
      await _throttle();
      try {
        return await _getOnce(uri);
      } on EgovApiException catch (e) {
        if (e.kind == EgovErrorKind.clientError ||
            e.kind == EgovErrorKind.tooLarge) {
          rethrow;
        }
        lastError = e;
      }
    }
    throw EgovApiException(lastError.kind, uri,
        statusCode: lastError.statusCode,
        message: 'gave up after $maxAttempts attempts: ${lastError.message}');
  }

  /// 上限は受信中に掛ける。受信し終えてから長さを見る方式だと、小さな gzip が
  /// 展開後に巨大になる場合にメモリを使い切ってから気付くことになる。
  Future<Uint8List> _getOnce(Uri uri) async {
    final cancel = CancelToken();
    final Response<List<int>> res;
    try {
      res = await _dio.getUri<List<int>>(
        uri,
        cancelToken: cancel,
        onReceiveProgress: (received, _) {
          if (received > maxBodyBytes && !cancel.isCancelled) {
            cancel.cancel('response too large ($received bytes)');
          }
        },
        // ブラウザでは UA を上書きできない（無視される）
        options: Options(headers: {'User-Agent': userAgent}),
      );
    } on DioException catch (e) {
      final kind = switch (e.type) {
        DioExceptionType.cancel => EgovErrorKind.tooLarge,
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout =>
          EgovErrorKind.timeout,
        _ when _retryable.contains(e.type) => EgovErrorKind.network,
        _ => EgovErrorKind.clientError,
      };
      throw EgovApiException(kind, uri, message: '${e.message}');
    }
    final status = res.statusCode ?? 0;
    final bytes = res.data ?? const <int>[];
    if (status >= 500) {
      throw EgovApiException(EgovErrorKind.serverError, uri,
          statusCode: status, message: 'server error');
    }
    if (status >= 400) {
      throw EgovApiException(EgovErrorKind.clientError, uri,
          statusCode: status,
          message: utf8.decode(bytes, allowMalformed: true));
    }
    if (bytes.length > maxBodyBytes) {
      throw EgovApiException(EgovErrorKind.tooLarge, uri,
          statusCode: status,
          message: 'response too large (${bytes.length} bytes)');
    }
    return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  }

  /// 5 req/s の自主制限。並列で投げないのは、無認証の公共 API に対して
  /// 自分がアクセス集中の原因にならないため（設計書 §4.6）。
  Future<void> _throttle() async {
    final now = DateTime.now();
    final interval =
        Duration(milliseconds: (1000 / maxRequestsPerSecond).ceil());
    if (_nextSlot.isAfter(now)) {
      final wait = _nextSlot.difference(now);
      _nextSlot = _nextSlot.add(interval);
      await Future<void>.delayed(wait);
    } else {
      _nextSlot = now.add(interval);
    }
  }
}
