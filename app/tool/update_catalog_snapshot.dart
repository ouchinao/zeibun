// アプリに同梱する法令一覧（assets/catalog_snapshot.json）を e-Gov から作り直す。
//
//   cd app && dart run tool/update_catalog_snapshot.dart
//
// アプリと同じ CatalogFetcher で取るので、起動時同期と同じ法令・同じ現行の判定になる。
import 'dart:convert';
import 'dart:io';

import 'package:zeibun_core/zeibun_core.dart';

Future<void> main() async {
  final client = HttpClient()
    ..userAgent = 'zeibun-snapshot (+https://github.com/ouchinao/zeibun)';
  try {
    final fetcher = CatalogFetcher(getJson: (uri) async {
      // 並列に投げないのは、アプリと同じ 5 req/s の自主制限を守るため
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final res = await (await client.getUrl(uri)).close();
      final body = await utf8.decodeStream(res);
      if (res.statusCode != 200) {
        throw HttpException('${res.statusCode} $uri: '
            '${body.substring(0, body.length.clamp(0, 200))}');
      }
      return jsonDecode(body) as Map<String, dynamic>;
    });
    final laws = (await fetcher.fetch()).values.toList()
      ..sort((a, b) => a.lawId.compareTo(b.lawId));
    final snap = CatalogSnapshot(
        generatedAt: DateTime.now().toUtc().toIso8601String(), laws: laws);
    final out = File('assets/catalog_snapshot.json');
    await out.writeAsString(
        '${const JsonEncoder.withIndent(' ').convert(snap.toJson())}\n');
    stdout.writeln('${laws.length} laws -> ${out.path}');
  } finally {
    client.close();
  }
}
