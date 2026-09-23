import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

/// e-Gov 法令API v2 への HTTP アクセス。URL の組み立ては `zeibun_core` の
/// `EgovRequests` が行い、ここは取得だけを担当する（テストでは差し替える）。
abstract class EgovApi {
  /// レスポンス本文をテキストで返す。4xx は [EgovApiException]。
  Future<String> getText(Uri uri);

  /// JSON をデコードして返す。
  Future<Map<String, dynamic>> getJson(Uri uri) async =>
      jsonDecode(await getText(uri)) as Map<String, dynamic>;
}

class EgovApiException implements Exception {
  EgovApiException(this.uri, this.statusCode, this.message);
  final Uri uri;
  final int? statusCode;
  final String message;

  bool get isClientError =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;

  @override
  String toString() => 'EgovApiException($statusCode $uri): $message';
}

/// dio 実装。
///
/// - 証明書ピン留めや検証の緩和はしない。政府ドメインの証明書更新で全ユーザーが
///   止まるリスクの方が MITM より大きく、OS の信頼ストアで足りる（設計書 §11 S）
/// - `validateStatus` を常に true にして自前で分岐するのは、5xx とタイムアウトだけ
///   再試行し、4xx は即座に失敗させたいから（dio の既定はどちらも例外になる）
/// - 再試行にジッタを入れるのは、多数の端末が同時刻に起動したときに e-Gov へ
///   再試行が同期して集中しないようにするため
/// - 受信上限と `<!DOCTYPE` 拒否は、gzip 爆弾と実体展開でメモリを使い切られないため
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
              // 4xx/5xx を例外にせず自分で扱う
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

  @override
  Future<String> getText(Uri uri) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (attempt > 1) {
        final base = retryBaseDelay * (1 << (attempt - 2));
        final jitter = 0.75 + _random.nextDouble() * 0.5;
        await Future<void>.delayed(base * jitter);
      }
      await _throttle();
      try {
        final res = await _dio.getUri<List<int>>(
          uri,
          options: Options(
            headers: {
              // ブラウザでは UA を上書きできない（無視される）
              'User-Agent': userAgent,
            },
          ),
        );
        final status = res.statusCode ?? 0;
        final bytes = res.data ?? const <int>[];
        if (status >= 500) {
          lastError = EgovApiException(uri, status, 'server error');
          continue;
        }
        if (status >= 400) {
          throw EgovApiException(
              uri, status, utf8.decode(bytes, allowMalformed: true));
        }
        if (bytes.length > maxBodyBytes) {
          throw EgovApiException(
              uri, status, 'response too large (${bytes.length} bytes)');
        }
        final text = utf8.decode(bytes);
        if (text.contains('<!DOCTYPE')) {
          throw EgovApiException(uri, status, 'DOCTYPE is not allowed');
        }
        return text;
      } on DioException catch (e) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.unknown) {
          lastError = e;
          continue;
        }
        rethrow;
      }
    }
    throw EgovApiException(
        uri, null, 'gave up after $maxAttempts attempts: $lastError');
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
