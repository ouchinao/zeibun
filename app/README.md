# zeibun app（Flutter）

税制法令を e-Gov 法令API v2 から最新化し、端末内で検索・閲覧する Flutter アプリ本体。
Flutter 非依存のロジック（法令 XML のツリー・条文パーサ・スコープ・差分判定）は
[`../packages/zeibun_core`](../packages/zeibun_core) にある。

## 構成

```
lib/
├── main.dart / app.dart / router.dart / providers.dart
├── data/
│   ├── db/database.dart          drift スキーマ（設計書 §5）と DAO
│   ├── egov/egov_api.dart        dio クライアント（5 req/s、再試行、受信上限、DOCTYPE 拒否）
│   └── repositories/
│       ├── sync_service.dart     起動時同期（§4.2）とバックオフ（§4.6）
│       ├── law_repository.dart   本文の取得・検証・キャッシュ（§4.5）、改正履歴
│       └── search_repository.dart 法令名検索・略称展開・条番号ジャンプ（§6）
├── features/
│   ├── home/        検索窓・同期バナー・最近開いた法令・主要税法
│   ├── search/      検索結果（条番号ジャンプの候補を含む）
│   ├── law_list/    法令一覧（分類・種別、末尾に「廃止・失効（参考）」）
│   ├── law_viewer/  閲覧（本文 / 附則 / 改正履歴、目次、本文内検索、条文レンダラ）
│   ├── sync/        同期状態バナー
│   └── settings/    今すぐ更新・先読み・キャッシュ削除・同期ログ・出典と免責
└── util/format.dart
```

## 開発

```sh
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift のコード生成（database.g.dart）
flutter analyze
flutter test
flutter build web --release   # Web 版は当面出さないが、動く状態を CI で保つ
```

- `lib/data` と `zeibun_core` は `dart:io` を使わない（Web でも同じコードが動く）
- 本文の保存は法令単位のトランザクション。`/law_data` 封筒の `revision_info.law_revision_id` を要求と照合してから保存する
- Web で実行する場合は `web/` に drift の `sqlite3.wasm` と `drift_worker.js` を置く（drift_flutter のドキュメント参照）

## 出典

法令データは [e-Gov法令検索](https://laws.e-gov.go.jp/)（デジタル庁）の法令API Version 2 から取得。
本アプリはデジタル庁・e-Gov の公式アプリではない。
