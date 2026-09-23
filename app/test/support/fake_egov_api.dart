import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:zeibun/data/db/database.dart';
import 'package:zeibun/data/egov/egov_api.dart';

/// パスごとに固定レスポンスを返す fake。呼び出した URI を記録する。
class FakeEgovApi extends EgovApi {
  FakeEgovApi();

  final Map<String, String Function(Uri uri)> routes = {};
  final List<Uri> calls = [];

  /// すべての呼び出しを失敗させる（オフライン再現）。
  bool offline = false;

  void onPath(String path, String Function(Uri uri) handler) =>
      routes[path] = handler;

  @override
  Future<Uint8List> getBytes(Uri uri) async {
    calls.add(uri);
    if (offline) {
      throw EgovApiException(EgovErrorKind.network, uri, message: 'offline');
    }
    final h = routes[uri.path];
    if (h == null) {
      throw EgovApiException(EgovErrorKind.clientError, uri,
          statusCode: 404, message: 'no route for ${uri.path}');
    }
    return utf8.encode(h(uri));
  }
}

AppDatabase inMemoryDatabase() =>
    AppDatabase(DatabaseConnection(NativeDatabase.memory()));

/// 実 API のレスポンスを保存したフィクスチャはコアパッケージと共用する。
String fixture(String name) =>
    File('../packages/zeibun_core/test/fixtures/$name').readAsStringSync();

/// `/laws` 用: 国税の実レスポンス抜粋（12 法令）を、クエリに関わらず返す。
/// 明示指定 ID（`law_id=`）には空を返す。
String Function(Uri) catalogHandler({
  Map<String, dynamic>? Function(Map<String, dynamic> row)? transform,
}) {
  final body = jsonDecode(fixture('laws_category_cd_013_asof_excerpt.json'))
      as Map<String, dynamic>;
  return (uri) {
    if (uri.queryParameters.containsKey('law_id') ||
        uri.queryParameters['category_cd'] != '013') {
      return jsonEncode(
          {'total_count': 0, 'count': 0, 'next_offset': null, 'laws': []});
    }
    var rows = (body['laws'] as List).cast<Map<dynamic, dynamic>>();
    if (transform != null) {
      rows = [
        for (final r in rows)
          if (transform(Map<String, dynamic>.from(r)) case final t?) t,
      ];
    }
    return jsonEncode({
      'total_count': rows.length,
      'count': rows.length,
      'next_offset': null,
      'laws': rows,
    });
  };
}
