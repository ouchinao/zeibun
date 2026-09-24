# zeibun app（Flutter）

税制法令を e-Gov 法令API v2 から最新化し、端末内で検索・閲覧する Flutter アプリ本体。
Flutter 非依存のロジック（法令 XML のツリー・条文パーサ・スコープ・差分判定）は
[`../packages/zeibun_core`](../packages/zeibun_core) にある。

## 構成

```
lib/
├── main.dart / app.dart / router.dart
├── providers.dart               DB・API・リポジトリ・一覧ストリームなど基盤の Provider
├── app_notices.dart             出典・免責の文言（1 箇所）
├── data/                        通信と保存。画面からは Provider 経由でしか触らない
│   ├── db/database.dart          drift スキーマ（設計書 §5）と DAO、`Law` 行の状態（LawFlags）
│   ├── db/database_location.dart DB の置き場（Application Support/db。iOS はバックアップ除外を AppDelegate に依頼）
│   ├── db/storage_errors.dart    SQLite の例外から「空き容量が尽きた」を見分ける
│   ├── egov/egov_api.dart        dio クライアント（5 req/s、再試行、受信上限、失敗種別 EgovErrorKind）
│   └── repositories/
│       ├── sync_service.dart     起動時同期・手動更新（§4.2）、バックオフ（§4.6）、二重実行の抑止
│       ├── law_repository.dart   本文の取得・検証・キャッシュ（§4.5）、改正時の先読み、改正履歴
│       ├── prefetch_service.dart 全法令の保存（§4.4）: 逐次取得・進捗・中断・通信失敗での打ち切り
│       ├── bookmark_repository.dart ブックマークの登録・解除・一覧（時刻の付与）
│       └── search_repository.dart 法令名検索・略称展開・条番号ジャンプ・横断全文検索（§6）
├── features/                    画面（機能単位）
│   ├── home/        検索窓・同期バナー・最近開いた法令・ブックマーク・主要税法・初回免責
│   ├── bookmarks/   ブックマークの Provider、ホームの一覧、法令画面のしおりボタン
│   ├── search/      検索結果（条番号ジャンプの候補を含む）
│   ├── law_list/    法令一覧（分類・種別、末尾に「廃止・失効（参考）」）
│   ├── law_viewer/  閲覧。law_page（枠）、in_text_search（本文内検索の一致計算）、main_tab / suppl_tab / revisions_tab、
│   │                toc_drawer、article_menu、law_text（画面用モデル）、law_node_renderer
│   ├── sync/        同期状態バナー
│   └── settings/    設定の Notifier（SharedPreferences）、設定画面、全法令を端末に保存する画面
└── util/           format（日時・種別・バイト数）、highlight（検索語の強調）
```

層の決まり:

- 画面は `data/` を直接 import しない（`Law` などの行型と `providers.dart` を通す）。通信・DB 操作は Repository / Service に置く
- 画面の状態は bool を並べず、`sealed class`（同期状態）・`enum`（本文の取得結果・失敗理由・保存状態）・小さな状態クラス（本文内検索）にまとめる
- 失敗は種類で分ける: 通信環境（オフライン）／e-Gov 側の異常／受け取ったデータの異常。バナーと本文ヘッダの文言はこれで変わる

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

## ライセンス

権利留保（リポジトリ直下の [LICENSE](../LICENSE)）。閲覧・参照はできるが、再配布・ストア公開・商用利用はできない。
