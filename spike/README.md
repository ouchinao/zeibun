# zeibun_spike — Phase 0 スパイク（純 Dart）

設計書 §13 Phase 0 の確認事項を潰すためのコード。Flutter に依存しない（`dart:io` と `xml` のみ）。
`lib/src` の `LawNode` / `LawParser` は Phase 1 で `lib/data/parser` に移す前提。

## 中身

| ファイル | 内容 |
|---|---|
| `lib/src/law_node.dart` | 法令標準XML のツリー `LawNode {tag, attr, children}`。API の JSON と XML の両方から同じツリーを作る |
| `lib/src/law_parser.dart` | `LawNode` → 条レコード（設計書 §5 `articles` / §7）。`/law_data` の XML 封筒（`law_data_response`）も受け付ける。平文化 `PlainText` を含む |
| `lib/src/egov_client.dart` | 法令API v2 クライアント。gzip、5 req/s 制限、5xx の指数バックオフ、通信量計測 |
| `lib/src/catalog.dart` | `/laws` 行のモデル、公式の `category_cd` 表、税制スコープ `LawScope.tax`、主要税法の ID |
| `lib/src/synth.dart` | 実 API に届かない環境で規模感を測るための合成法令（JSON / XML） |
| `bin/spike.dart` | CLI（下記） |
| `fixtures/spec_example_kokki_kokka.xml` | 公式仕様書の例示法令の XML |
| `fixtures/catalog_tax_snapshot.json` | 実カタログ（2026-09）のうち税関連 442 行 |
| `fixtures/real/` | 実 API のレスポンス（2026-09-23 取得）: 地方法人税法の `/law_file` と `/law_data` の XML、`/laws`（asof あり・023・law_id 指定）、`/law_revisions`、`/keyword` |

## 実行

```sh
cd spike
dart pub get
dart test

# 実 API に対して（laws.e-gov.go.jp に到達できる環境で）
dart run bin/spike.dart catalog --out out            # 一覧取得・スコープ件数・asof・CORS・通信量
dart run bin/spike.dart fetch --out out/bodies       # 主要税法 10 件の本文 XML/JSON を保存し計測
dart run bin/spike.dart bench --dir out/bodies       # 保存した本文の Dart パース時間・メモリ
dart run bin/spike.dart synth --articles 2000        # 合成法令の生成（オフライン用）
```

計測結果は設計書 §13 Phase 0 と [調査メモ](../docs/egov-law-api-v2.md) に転記済み。公式仕様は [`../docs/lawapi-v2.yaml`](../docs/lawapi-v2.yaml)（v2.1.139）に同梱。
