/// zeibun の Flutter 非依存コア（設計書 §10 `lib/data` に相当）。
///
/// - `law/`: 法令標準XML のツリー `LawNode` と条文パーサ `LawParser`
/// - `catalog/`: `/laws` の行モデル、公式の分類コード表、対象法令スコープ
/// - `sync/`: 起動時同期の差分判定（設計書 §4.2 ステップ 3）
/// - `api/`: e-Gov 法令API v2 のリクエスト組み立てと `/law_data` 封筒の検証
/// - `text/`: 検索用の正規化、条番号の解釈、略称辞書
///
/// `dart:io` と Flutter に依存しない。HTTP と SQLite の実体はアプリ側が持つ。
library;

export 'src/api/egov_requests.dart';
export 'src/api/law_data_envelope.dart';
export 'src/catalog/category_codes.dart';
export 'src/catalog/law_scope.dart';
export 'src/catalog/law_summary.dart';
export 'src/law/law_node.dart';
export 'src/law/law_parser.dart';
export 'src/sync/catalog_diff.dart';
export 'src/text/law_abbrev.dart';
export 'src/text/normalize.dart';
