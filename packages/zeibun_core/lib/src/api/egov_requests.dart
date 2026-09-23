import '../catalog/law_scope.dart';

/// e-Gov 法令API v2 のリクエストを組み立てる（HTTP は行わない）。
///
/// 設計書 §11 の入力検証（法令 ID・履歴 ID の形式）をここで行い、
/// 不正な値はエンドポイントの URL にならないようにする。
class EgovRequests {
  EgovRequests({Uri? baseUrl})
      : baseUrl = baseUrl ?? Uri.parse('https://laws.e-gov.go.jp/api/2/');

  final Uri baseUrl;

  /// 法令 ID: 15 桁の英数字（例 `340AC0000000034`、`321CONSTITUTION`）。
  static final RegExp lawIdPattern = RegExp(r'^[0-9A-Z]{15}$');

  /// 法令履歴 ID: `<law_id>_<YYYYMMDD>_<改正法令ID>`。
  static final RegExp revisionIdPattern =
      RegExp(r'^[0-9A-Z]{15}_\d{8}_[0-9A-Z]{15}$');

  /// 条番号（`attr.Num`）: `22`、`66_4`、`42_12_5`。
  static final RegExp articleNumPattern = RegExp(r'^\d+(_\d+)*$');

  /// 未施行改正の検知に使う「遠い未来」の時点（設計書 §4.2）。
  static const String farFutureAsOf = '2099-12-31';

  static bool isValidLawId(String s) => lawIdPattern.hasMatch(s);
  static bool isValidRevisionId(String s) => revisionIdPattern.hasMatch(s);
  static bool isValidArticleNum(String s) => articleNumPattern.hasMatch(s);

  Uri _build(String path, Map<String, String> query) =>
      baseUrl.resolve(path).replace(queryParameters: query);

  /// `GET /laws`。既定で `asof` 遠未来を付ける。`asOf: null` で現時点の一覧
  /// （`current_revision_info` が返らなかったときの保険。設計書 §4.2）。
  Uri laws(Map<String, String> query,
      {String? asOf = farFutureAsOf, int? offset}) {
    final lawId = query['law_id'];
    if (lawId != null && !isValidLawId(lawId)) {
      throw ArgumentError.value(lawId, 'law_id', 'invalid law id');
    }
    return _build('laws', {
      ...query,
      if (asOf != null) 'asof': asOf,
      'response_format': 'json',
      if (offset != null && offset > 0) 'offset': '$offset',
    });
  }

  /// 起動時同期の一覧取得（設計書 §4.2 ステップ 1）。
  List<Uri> catalog(LawScope scope) =>
      [for (final q in scope.catalogQueries()) laws(q)];

  /// `GET /law_data/{revision_id}` を XML 本文（gzip が効く）で取る。
  /// 既定では改正法令の附則を除く（`omit_amendment_suppl_provision=true`）。
  Uri lawDataXml(String revisionId, {bool includeAmendmentSuppl = false}) {
    if (!isValidRevisionId(revisionId)) {
      throw ArgumentError.value(
          revisionId, 'revisionId', 'invalid revision id');
    }
    return _build('law_data/$revisionId', {
      'response_format': 'xml',
      'law_full_text_format': 'xml',
      if (!includeAmendmentSuppl) 'omit_amendment_suppl_provision': 'true',
    });
  }

  /// `GET /law_revisions/{law_id}`。
  Uri lawRevisions(String lawId) {
    if (!isValidLawId(lawId)) {
      throw ArgumentError.value(lawId, 'lawId', 'invalid law id');
    }
    return _build('law_revisions/$lawId', {'response_format': 'json'});
  }

  /// `GET /keyword`（Phase 3）。税制の範囲は `category_cd=013,036` で近似する。
  Uri keyword(String keyword,
      {List<String> categoryCodes = const ['013', '036'], int limit = 50}) {
    return _build('keyword', {
      'keyword': keyword,
      'category_cd': categoryCodes.join(','),
      'limit': '$limit',
      'response_format': 'json',
    });
  }

  /// 「e-Gov で開く」の URL（設計書 §11 E: ホストを固定し ID は検証済みのみ）。
  static Uri egovLawPage(String lawId) {
    if (!isValidLawId(lawId)) {
      throw ArgumentError.value(lawId, 'lawId', 'invalid law id');
    }
    return Uri.https('laws.e-gov.go.jp', '/law/$lawId');
  }
}
