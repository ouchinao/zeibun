import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// 1 リクエストの結果。通信量の計測のため、圧縮後（wire）と展開後の両方の
/// バイト数を持つ。
class FetchResult {
  FetchResult({
    required this.uri,
    required this.statusCode,
    required this.bytes,
    required this.wireBytes,
    required this.elapsed,
    required this.headers,
    required this.attempts,
  });

  final Uri uri;
  final int statusCode;

  /// 展開後のボディ。
  final List<int> bytes;

  /// 受信したバイト数（gzip なら圧縮後）。
  final int wireBytes;
  final Duration elapsed;
  final Map<String, String> headers;
  final int attempts;

  String get bodyText => utf8.decode(bytes);
  dynamic get json => jsonDecode(bodyText);
}

class EgovHttpException implements IOException {
  EgovHttpException(this.uri, this.statusCode, this.body);
  final Uri uri;
  final int statusCode;
  final String body;

  @override
  String toString() => 'EgovHttpException($statusCode $uri): $body';
}

/// e-Gov 法令API v2 の最小クライアント（純 Dart、`dart:io` のみ）。
///
/// - `Accept-Encoding: gzip` を付け、自前で展開する（通信量計測のため）
/// - 5 req/s（既定）の自主制限
/// - 5xx・タイムアウト・接続エラーは指数バックオフで再試行（既定 3 回）
/// - 4xx は再試行せず [EgovHttpException]
class EgovClient {
  EgovClient({
    Uri? baseUrl,
    this.userAgent = 'zeibun-spike/0.1 (+https://github.com/ouchinao/zeibun)',
    this.maxRequestsPerSecond = 5,
    this.timeout = const Duration(seconds: 30),
    this.maxAttempts = 3,
    this.retryBaseDelay = const Duration(seconds: 1),
    this.onLog,
  }) : baseUrl = baseUrl ?? Uri.parse('https://laws.e-gov.go.jp/api/2') {
    _client = HttpClient()
      ..autoUncompress = false
      ..connectionTimeout = timeout
      ..userAgent = userAgent;
    // HTTPS_PROXY / NO_PROXY を尊重する（ループバックはプロキシを通さない）
    _client.findProxy = (uri) => HttpClient.findProxyFromEnvironment(uri,
        environment: Platform.environment);
  }

  final Uri baseUrl;
  final String userAgent;
  final int maxRequestsPerSecond;
  final Duration timeout;
  final int maxAttempts;
  final Duration retryBaseDelay;
  final void Function(String message)? onLog;

  late final HttpClient _client;
  DateTime _nextSlot = DateTime.fromMillisecondsSinceEpoch(0);

  int requestCount = 0;
  int totalWireBytes = 0;
  int totalBytes = 0;

  void close() => _client.close(force: true);

  Uri resolve(String path, [Map<String, String>? query]) {
    final base = baseUrl.toString().endsWith('/')
        ? baseUrl.toString()
        : '${baseUrl.toString()}/';
    final p = path.startsWith('/') ? path.substring(1) : path;
    var uri = Uri.parse('$base$p');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: {...uri.queryParameters, ...query});
    }
    return uri;
  }

  /// `GET /laws`
  Future<FetchResult> laws(Map<String, String> query) =>
      get('laws', {'response_format': 'json', ...query});

  /// `GET /law_revisions/{law_id_or_num}`
  Future<FetchResult> lawRevisions(String lawIdOrNum,
          [Map<String, String>? query]) =>
      get('law_revisions/$lawIdOrNum', {'response_format': 'json', ...?query});

  /// `GET /law_file/{file_type}/{id}`
  Future<FetchResult> lawFile(String fileType, String id,
          [Map<String, String>? query]) =>
      get('law_file/$fileType/$id', query);

  /// `GET /law_data/{id}`
  Future<FetchResult> lawData(String id, [Map<String, String>? query]) =>
      get('law_data/$id', query);

  /// `GET /keyword`
  Future<FetchResult> keyword(Map<String, String> query) =>
      get('keyword', {'response_format': 'json', ...query});

  Future<FetchResult> get(String path, [Map<String, String>? query]) async {
    final uri = resolve(path, query);
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (attempt > 1) {
        final delay = retryBaseDelay * (1 << (attempt - 2));
        onLog?.call('retry $attempt/$maxAttempts in ${delay.inMilliseconds}ms: '
            '$uri ($lastError)');
        await Future<void>.delayed(delay);
      }
      await _throttle();
      final sw = Stopwatch()..start();
      try {
        final req = await _client.getUrl(uri).timeout(timeout);
        req.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip');
        req.headers.set(HttpHeaders.acceptHeader, 'application/json, */*');
        final res = await req.close().timeout(timeout);
        final chunks = <int>[];
        await res.listen(chunks.addAll).asFuture<void>().timeout(timeout * 2);
        sw.stop();
        requestCount++;
        final wire = chunks.length;
        final encoding =
            res.headers.value(HttpHeaders.contentEncodingHeader) ?? '';
        final body = encoding.contains('gzip') ? gzip.decode(chunks) : chunks;
        totalWireBytes += wire;
        totalBytes += body.length;
        final headers = <String, String>{};
        res.headers.forEach((k, v) => headers[k] = v.join(', '));
        final result = FetchResult(
          uri: uri,
          statusCode: res.statusCode,
          bytes: body,
          wireBytes: wire,
          elapsed: sw.elapsed,
          headers: headers,
          attempts: attempt,
        );
        if (res.statusCode >= 500) {
          lastError =
              EgovHttpException(uri, res.statusCode, _preview(result.bodyText));
          continue;
        }
        if (res.statusCode >= 400) {
          throw EgovHttpException(uri, res.statusCode, _preview(body));
        }
        return result;
      } on TimeoutException catch (e) {
        lastError = e;
      } on SocketException catch (e) {
        lastError = e;
      } on HttpException catch (e) {
        lastError = e;
      }
    }
    throw EgovHttpException(
        uri, 0, 'gave up after $maxAttempts attempts: $lastError');
  }

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

  static String _preview(Object body) {
    final s = body is String
        ? body
        : utf8.decode(body as List<int>, allowMalformed: true);
    return s.length > 300 ? '${s.substring(0, 300)}…' : s;
  }
}
