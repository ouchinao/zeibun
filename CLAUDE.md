# zeibun

e-Gov 法令API v2 を使う税法検索アプリ（Flutter）。名前は「税文」＝税の条文。
仕様と判断の根拠は `docs/design.md`（設計書）にある。

## 構成

- `app/` Flutter アプリ。`lib/features/<機能>/` に画面と状態、`lib/data/` に DB・API・リポジトリ
- `packages/zeibun_core/` 純 Dart のコア（法令 XML の解析など）。Web でも動かす
- `spike/` Phase 0 の調査用ツール
- `docs/` 設計書・API 資料・プライバシーポリシー・公開手順、`store/` ストア掲載文

## 確認コマンド（CI と同じ）

`app/` で:

```
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test --timeout 60s
```

`packages/zeibun_core/` と `spike/` は `dart format` / `dart analyze --fatal-infos` / `dart test`。
アプリの `lib` に `dart:io` と証明書検証を緩めるコードは入れない（CI で落ちる）。

## 進め方

- 返事は日本語で、短く。
- テストを流すときは、流す前にそう伝え、かかる時間の目安も添える。
- コミット・push の前に、変更内容とコミットメッセージ案を見せて確認をとる。
- main に直接 push しない。ブランチを切って PR を出す。マージは ouchinao が行う。
- 実装を変えた PR では、`docs/design.md` も実装に合わせて直す。

## コミットと PR

- 作者は `--author="ouchinao <67366394+ouchinao@users.noreply.github.com>"`。
- コミットメッセージの末尾は `Co-Authored-By` の行だけ。セッションの URL は入れない。
- PR 本文は日本語。末尾は `🤖 Generated with [Claude Code](https://claude.com/claude-code)` だけで、セッションの URL は入れない。

## 書き方

- コードには How
- テストコードには What
- コミットログには Why
- コードコメントには Why not（「〜しないのは、〜ため」の形）

## レビューの観点

- 画面から通信処理を減らす
- boolだらけの状態を整理する
- onPressedの長い処理を外へ出す
- エラー処理を場合ごとに分ける
- APIモデルとUIモデルを分ける
- 共通化のやりすぎを減らす
- ローディング中の二重実行を防ぐ
- フォルダ構成を機能単位で整理する
- 関心の分離が適切になされている
- アクセシビリティは `docs/design.md` §12 の基準で見る
