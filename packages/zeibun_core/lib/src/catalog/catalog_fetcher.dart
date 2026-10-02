import '../api/egov_requests.dart';
import 'law_scope.dart';
import 'law_summary.dart';

/// スコープの一覧を `/laws` から取り、法令 ID → [LawSummary] にまとめる。
///
/// dio を直接使わないのは、同梱用の一覧を作るツール（dart:io）からも、アプリと
/// 同じ判定で取るため。
class CatalogFetcher {
  CatalogFetcher({
    required this.getJson,
    LawScope? scope,
    EgovRequests? requests,
  })  : scope = scope ?? LawScope.tax,
        requests = requests ?? EgovRequests();

  final Future<Map<String, dynamic>> Function(Uri uri) getJson;
  final LawScope scope;
  final EgovRequests requests;

  /// クエリを並列に投げないのは、5 req/s の自主制限を守るため。
  /// `asof=2099-12-31` を付けるのは、1 リクエストで現行（`current_revision_info`）と
  /// 未施行の履歴（`revision_info`）が同時に取れ、`/law_revisions` を全法令に
  /// 投げずに済むから。
  Future<Map<String, LawSummary>> fetch() async {
    final out = <String, LawSummary>{};
    for (final q in scope.catalogQueries()) {
      final rows = await _fetchAllPages(q, asOf: EgovRequests.farFutureAsOf);
      // asof 付きの行に current_revision_info が無ければ、その行の revision_info は
      // 未施行側なので現行として使えない。同じクエリを asof なしで取り直して現行を得る
      final currentById = <String, Map<String, dynamic>>{};
      if (rows.any((r) => r['current_revision_info'] is! Map)) {
        for (final r in await _fetchAllPages(q, asOf: null)) {
          currentById[_lawIdOf(r)] = r;
        }
      }
      for (final row in rows) {
        final s =
            LawSummary.fromApiRow(row, currentRow: currentById[_lawIdOf(row)]);
        if (scope.reasonFor(s) == null) continue;
        out.putIfAbsent(s.lawId, () => s);
      }
    }
    return out;
  }

  static String _lawIdOf(Map<String, dynamic> row) =>
      (row['law_info'] as Map?)?['law_id'] as String? ?? '';

  Future<List<Map<String, dynamic>>> _fetchAllPages(Map<String, String> q,
      {required String? asOf}) async {
    final rows = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      final body = await getJson(requests.laws(q, asOf: asOf, offset: offset));
      final page = (body['laws'] as List? ?? const []);
      rows.addAll(page.map((r) => (r as Map).cast<String, dynamic>()));
      final next = body['next_offset'];
      if (next is int && page.isNotEmpty && next > offset) {
        offset = next;
      } else {
        return rows;
      }
    }
  }
}
