# zeibun_spike — Phase 0 スパイク（純 Dart）

設計書 §13 Phase 0 の確認事項を潰すためのコード。Flutter に依存しない（`dart:io` と `xml` のみ）。
`lib/src` の `LawNode` / `LawParser` は Phase 1 で `lib/data/parser` に移す前提。

## 中身

| ファイル | 内容 |
|---|---|
| `lib/src/law_node.dart` | 法令標準XML のツリー `LawNode {tag, attr, children}`。API の JSON と XML の両方から同じツリーを作る |
| `lib/src/law_parser.dart` | `LawNode` → 条レコード（設計書 §5 `articles` / §7）。平文化 `PlainText` を含む |
| `lib/src/egov_client.dart` | 法令API v2 クライアント。gzip、5 req/s 制限、5xx の指数バックオフ、通信量計測 |
| `lib/src/catalog.dart` | `/laws` 行のモデル、公式の `category_cd` 表、税制スコープ `LawScope.tax`、主要税法の ID |
| `lib/src/synth.dart` | 実 API に届かない環境で規模感を測るための合成法令（JSON / XML） |
| `fixtures/spec_example_kokki_kokka.xml` | 公式仕様書 (lawapi-v2.yaml) の例示法令の XML。パーサのフィクスチャ |
| `fixtures/catalog_tax_snapshot.json` | 実カタログ（2026-09）のうち税関連 442 行。スコープ判定のテスト用 |

## 実行

```sh
cd spike
dart pub get
dart test
```

実 API に対する `catalog` / `fetch` / `bench` コマンド（`bin/`）は、`laws.e-gov.go.jp` に到達できるセッションで追加・実行する
（設計書 §13 Phase 0 の表 1〜5 を埋める。CORS 確認は `Origin` ヘッダ付きの `GET /laws` 1 回）。
公式仕様は [`../docs/lawapi-v2.yaml`](../docs/lawapi-v2.yaml)（v2.1.138）に同梱。
