# zeibun 設計書 — 税制法令検索アプリ（Flutter × e-Gov 法令API v2）

- 状態: ドラフト v0.2（2026-09-23）— MVP を「起動時に一覧を最新化 → 法令名で検索 → 開いた法令の最新本文をその場で取得・表示」に絞り込み、横断全文検索を Phase 2 に移動
- 関連: [e-Gov 法令API v2 調査メモ](./egov-law-api-v2.md)

## 1. 目的と要件

税制に関する法令（所得税法、法人税法、消費税法、租税特別措置法、国税通則法、地方税法 など）を、
**常に最新の条文で**、スマホから素早く検索・閲覧できるアプリを作る。

### 要件

| # | 要件 | 補足 |
|---|---|---|
| R1 | アプリ起動時に e-Gov 法令API v2 から最新版をフェッチする | 起動のたびに一覧を取り直し、改正があった法令を検知する。ユーザー操作は不要 |
| R2 | 税制の法令を検索し、**目的の法令の最新本文**を見られる | 法令名で検索 → 最新リビジョンの本文（XML/JSON）を取得して表示 → 本文内検索・条番号ジャンプ |
| R2' | 条文の横断全文検索（複数法令にまたがる語句検索） | Phase 2。本文をまとめて端末に持つ必要があるため MVP から外す |
| R3 | 条文を読める | 条・項・号・表を崩さず表示。目次から移動できる |
| R4 | オフラインでも一度開いた法令は閲覧できる | 取得した本文は端末にキャッシュ。同期はベストエフォート。失敗しても使える |
| R5 | データソースは e-Gov 法令API v2 のみ | 自前サーバを持たない（後述の将来案は除く） |
| R6 | 出典表示 | 公共データ利用規約に従い「e-Gov法令検索」を出典として明記 |

### 非要件（今回やらないこと）

- バックグラウンドでの定期同期（OS のスケジューラ利用）。同期トリガは起動時のみ
- 通達・質疑応答事例・判例（e-Gov に無い。国税庁サイトの範囲）
- 条文の解説・AI要約
- ユーザーアカウント、サーバ側の状態

## 2. 対象法令（スコープ）の定義

e-Gov の「事項別分類」は1法令1分類で、税法は次のように散っている（実カタログの集計。詳細は調査メモ）。

| 取り込み単位 | 内容 | 件数目安 |
|---|---|---|
| 分類「国税」全件 | 所得税法・法人税法・消費税法・相続税法・租税特別措置法・国税通則法・国税徴収法・印紙税法・登録免許税法・税理士法・関税法 と、その施行令・施行規則 | 252 |
| 分類「地方財政」のうち題名に「税」を含むもの | 地方税法・同施行令・同施行規則、地方交付税法、各種譲与税法 | 46 |
| 明示指定の法令ID | 上記で漏れるもの（例: 国税収納金整理資金に関する法律=財務通則、国税不服審判所組織令=行政組織、租税条約実施特例法関連） | 10前後 |

- スコープはアプリ内の設定ファイル `lib/core/config/law_scope.dart` に「分類コード」「分類名＋題名の正規表現」「法令IDの明示リスト」の3種のルールで宣言する。ルールの追加はコード変更のみで済む
- 合計 約300法令。同期対象・検索対象はこの集合
- 関税関係（関税法・関税定率法）は「国税」分類に含まれるためそのまま入る。除外したければ除外ルールで対応

## 3. 全体アーキテクチャ

**クライアント完結（ローカルファースト）**。アプリが直接 e-Gov API を呼び、端末内 SQLite に法令一覧と取得済み本文を保持し、検索も端末内で行う。

MVP の基本動作は次の3ステップ。

1. **起動時**: `/laws` で対象法令の一覧（現行リビジョンID付き）を取り直し、ローカル一覧を最新化する。リビジョンが変わった法令のキャッシュ本文は「古い」と印を付ける
2. **検索**: 法令名・略称で一覧を検索して法令を選ぶ
3. **閲覧**: その法令の最新リビジョンの本文を `/law_file/json/{revision_id}`（または XML）で取得し、パースして表示。取得した本文はキャッシュし、次回以降はリビジョンが同じならローカルから開く。本文内の語句検索と条番号ジャンプができる

本文を「起動時に全部先読み」するのではなく「開いたときに最新を取る」方式にすることで、起動時の通信は一覧の数十KBで済み、初回起動のブートストラップも不要になる。横断全文検索（R2'）が必要になった段階で、対象法令の本文をまとめて先読みして FTS 索引を作る（Phase 2）。

```
┌──────────────────────────────── Flutter アプリ ────────────────────────────────┐
│                                                                                │
│  UI (features/*)                                                               │
│   ├ 検索画面  ─┐                                                               │
│   ├ 法令閲覧  ─┼─ Riverpod Providers ──┐                                       │
│   ├ 改正履歴  ─┤                        │                                       │
│   └ 同期状態  ─┘                        ▼                                       │
│                              Repository 層                                     │
│                     LawRepository / SearchRepository / SyncService            │
│                        │                       │                  │            │
│                        ▼                       ▼                  ▼            │
│              EgovApiClient (dio)      LawDatabase (drift)   LawJsonParser      │
│              GET /laws                 laws / revisions      (Isolate で実行)   │
│              GET /law_revisions        articles + FTS5                         │
│              GET /law_file/json                                                │
└────────────┬───────────────────────────────────────────────────────────────────┘
             │ HTTPS (gzip)
             ▼
   https://laws.e-gov.go.jp/api/2   （認証なし・レート制限ヘッダなし・ETag なし）
```

### この構成を選ぶ理由

- API が無認証・無料で、対象が約300法令と小さい。サーバを置く理由がない
- R4（オフライン閲覧）を満たすには端末内に本文キャッシュが必要
- 「起動時にフェッチ」は端末内で完結できる（バックグラウンド実行の制約を受けない）

### 本文の取得形式: XML か JSON か

`/law_file/xml/{revision_id}` と `/law_file/json/{revision_id}` は同じ法令標準XMLの表現違いで、要素名（`Article`, `Paragraph`, `Sentence` …）も属性も同一。

| | XML | JSON |
|---|---|---|
| 取得 | `Content-Disposition: attachment` でファイルとして返る | `{tag, attr, children}` のツリー |
| Dart での扱い | `xml` パッケージ。イベントストリームで巨大ファイルも省メモリで読める | `dart:convert` の `json.decode` で即オブジェクト化。実装が単純 |
| サイズ | ほぼ同等（労働基準法で XML 398KB / JSON 420KB） | |

**MVP は JSON を採用**する（実装が単純で、`/law_data` のレスポンス構造とも共通）。パーサは `LawNode` ツリーを入力にするインターフェースで抽象化し、租税特別措置法クラス（十数MB）で `json.decode` のメモリが問題になったら XML ストリーム読みの実装に差し替える。どちらでも保存形式（§5 の `articles`）は同じ。

### 検討したが採らない案

| 案 | 内容 | 不採用の理由 |
|---|---|---|
| A. サーバ側で全文検索（`/keyword` API のみ） | 端末に本文を持たず、検索のたびに API を叩く | オフライン不可。API 仕様（パラメータ・ハイライト）が未確認。ただし**スコープ外の法令をついでに検索する補助機能**として Phase 3 で検討 |
| B. GitHub Actions で日次スナップショット配信 | 自前のジョブが e-Gov を毎日取り込み、アプリは差分パッケージを取る | Phase 2 の全件先読みが遅すぎた場合の選択肢。まずは「シード DB 同梱」（§4.6）で対処し、それでも不足なら再検討 |
| C. 起動時に対象法令の本文を全部先読み | 起動時同期で約300法令の本文を取り、常にオフラインで全件検索できる | 初回に数百MB のダウンロードが必要で起動が重い。横断全文検索が必要になる Phase 2 で、設定オプションとして導入する |

## 4. 起動時同期（R1）

### 4.1 方針

- 起動直後に**ローカルDBで即座に画面を使える状態**にし、同期は裏で走らせる（ブロッキングしない）
- 起動時に取るのは**一覧（カタログ）だけ**。通信は 1〜3 リクエスト（数十KB）で終わる
- 本文は法令を開いたときに取得する（オンデマンド）。一覧で検知したリビジョンとキャッシュのリビジョンが違えば取り直す
- 初回起動でも一覧を取るだけなので、ブートストラップ画面は不要。一覧が取れないほどのオフライン時は「一覧を取得できませんでした」を出し、キャッシュ済みの法令だけ開ける状態にする
- 「よく使う法令を先読み」は設定でON にできるオプション（§4.5）

### 4.2 シーケンス

```
起動
 ├ DB open → 画面表示（前回同期済みデータ）
 └ SyncService.runOnLaunch()
     1. GET /laws?category_cd=023&limit=1000          … 国税
        GET /laws?category_cd=008&limit=1000          … 地方財政（題名で絞る）
        GET /laws?law_id=<明示ID>                     … 明示指定分（数件）
        （category_cd が使えない場合の代替: /laws?limit=5000 を2回取り、
          revision_info.category でクライアント側フィルタ。gzip 1.6MB）
     2. スコープ判定 → 対象法令リスト（law_id, law_revision_id, updated, ...）
     3. ローカル laws テーブルと突合
        - 未登録                                 → NEW
        - current_revision_id が違う             → REVISED（改正の施行 or 施行日到来）
        - updated が違う（revision_id は同じ）    → CORRECTED（訂正・再登録）
        - ローカルにあるが一覧に無い              → MISSING（削除しない。フラグのみ）
        - 一致                                   → SKIP
     4. laws テーブルを更新（current_revision_id / catalog_updated を新しい値に）。
        本文キャッシュ（body_revision_id）はそのまま残す → 一覧側と食い違えば「要更新」
     5. 「先読み」設定が ON の法令、および直近に開いた法令のうち REVISED / CORRECTED の
        ものは、この場で本文を取り直す（並列度 3、5 req/s 上限。§4.6 の手順）
     6. sync_runs に結果を記録。UI に「最終同期 09:12 / 改正あり 3件」を表示

法令を開いたとき（LawRepository.openLaw(lawId)）
     a. laws.current_revision_id == body_revision_id ならキャッシュから表示（通信なし）
     b. 違う（または未取得）なら GET /law_file/json/{current_revision_id}
        - オンライン: 取得 → Isolate でパース → 1トランザクションで articles を差し替え →
          body_revision_id を更新 → 表示
        - オフライン: 古いキャッシュがあれば「○月○日時点の内容です（改正あり）」と注記して表示。
          無ければエラー表示
     c. GET /law_revisions/{law_id} で改正履歴（未施行改正を含む）を取り、law_revisions を差し替え
```

### 4.3 差分判定の根拠

- API に `updated_from` のような差分パラメータは無く、HTTP キャッシュヘッダも無い。**一覧の `law_revision_id` と `updated` を前回値と比べる**のが唯一の方法
- 施行日到来（未施行改正が現行になる）は `/laws` 側で `law_revision_id` が切り替わるので、REVISED として自然に拾える
- `laws.current_revision_id`（一覧の値）と `laws.body_revision_id`（本文を保存できたリビジョン）を**別カラム**にする。「この法令のキャッシュは最新か」がこの2つの比較で分かり、途中で kill されても次回起動時にそのまま再判定できる
- 未施行改正の登録は `/laws` の `updated` に現れない。改正履歴は法令を開いたときに `/law_revisions` で取り直す（MVP）。スコープ全法令の履歴を日次で回すのは Phase 3（「今後施行される改正一覧」を作るとき）

### 4.4 同期の状態と UI

`SyncState = idle | checking | downloading(done, total, currentTitle) | success(updated, at) | offline(lastSyncAt) | error(message, lastSyncAt)`

- 検索画面上部の細いバナーに表示。`downloading`（先読み中）でも検索・閲覧は可能
- 一覧の各行と閲覧画面ヘッダに「最新」「改正あり（未取得）」「オフライン: ○月○日時点」のバッジを出す
- 手動の「今すぐ更新」は設定画面に置く（起動時同期の再実行）
- 起動時同期の抑制はしない（要件どおり毎回チェック）。ただし前回成功から 10 分以内の再起動はカタログ取得を省略する（連続起動時の無駄打ち防止。設定で無効化可）

### 4.5 先読み（オプション）

- 設定「よく使う法令を先読みする」を ON にすると、**主要法令セット**（所得税法・法人税法・消費税法・相続税法・国税通則法・国税徴収法・租税特別措置法・地方税法 とその施行令・規則、約30件）と、ブックマークした法令を起動時同期の中で取り直す。オフラインでも最新に近い状態で開けるようにするため
- 直近30日に開いた法令も、改正が検知されたら同じ扱いで取り直す
- Phase 2（横断全文検索）では、これを「スコープ全法令の先読み」に拡張し、FTS 索引を作る。そのときは進捗画面と Wi-Fi 推奨表示を追加する

### 4.6 本文取得の手順（共通）

1. `GET /law_file/json/{revision_id}`（gzip、タイムアウト 30 秒、5xx は指数バックオフで 3 回）
2. `Isolate.run` で JSON をデコードし、§7 のパーサで条レコード群に変換
3. 1 トランザクションで該当法令の `articles` を全削除 → 挿入、`laws.body_revision_id` / `body_synced_at` を更新。ここで初めて「反映済」になる
4. 失敗時は何も書かない（古いキャッシュが残る）

同期処理と本文取得は Flutter に依存しない純 Dart で書き、`dart run` でデスクトップからも動かせるようにする。単体テストと、Phase 2 で必要になれば本文入りシード DB の生成（`tool/build_seed.dart`）に使う。

## 5. データモデル（SQLite / drift）

```sql
-- 法令（1行 = 1法令）
CREATE TABLE laws (
  law_id               TEXT PRIMARY KEY,   -- 例 340AC0000000034
  law_num              TEXT NOT NULL,      -- 昭和四十年法律第三十四号
  law_type             TEXT NOT NULL,      -- Act / CabinetOrder / MinisterialOrdinance / Rule ...
  title                TEXT NOT NULL,
  title_kana           TEXT,
  abbrev               TEXT,               -- API の略称
  category             TEXT,               -- 国税 / 地方財政 ...
  promulgation_date    TEXT,               -- YYYY-MM-DD
  repeal_status        TEXT NOT NULL,      -- None / Repeal / Expire / LossOfEffectiveness
  scope_reason         TEXT NOT NULL,      -- category:023 / title-regex / explicit
  current_revision_id  TEXT,               -- /laws が返した現行リビジョン
  current_enforced_at  TEXT,               -- その施行日
  catalog_updated      TEXT,               -- revision_info.updated
  body_revision_id     TEXT,               -- 本文を保存済みのリビジョン（NULL = 未取得）
  body_synced_at       TEXT,
  missing_since        TEXT                -- 一覧から消えた日（通常 NULL）
);

-- 改正履歴（過去・現行・未施行）
CREATE TABLE law_revisions (
  revision_id          TEXT PRIMARY KEY,   -- <law_id>_<YYYYMMDD>_<改正法令ID>
  law_id               TEXT NOT NULL REFERENCES laws(law_id),
  enforced_at          TEXT NOT NULL,
  promulgated_at       TEXT,
  scheduled_enforced_at TEXT,
  enforcement_comment  TEXT,
  amendment_law_id     TEXT,
  amendment_law_num    TEXT,
  amendment_law_title  TEXT,
  amendment_type       TEXT,
  status               TEXT NOT NULL,      -- CurrentEnforced / PreviousEnforced / UnEnforced / Repeal
  api_updated          TEXT,
  fetched_at           TEXT NOT NULL
);
CREATE INDEX idx_revisions_law ON law_revisions(law_id, enforced_at);

-- 条文（1行 = 1条。本則・附則・別表それぞれ）
CREATE TABLE articles (
  id                   INTEGER PRIMARY KEY,
  law_id               TEXT NOT NULL REFERENCES laws(law_id),
  revision_id          TEXT NOT NULL,
  seq                  INTEGER NOT NULL,   -- 法令内の表示順
  section              TEXT NOT NULL,      -- main / suppl / appdx
  suppl_amend_law_num  TEXT,               -- 附則の場合の改正法令番号
  path                 TEXT NOT NULL,      -- 例 main/Article_22、suppl[令和八年法律第十二号]/Article_3
  article_num          TEXT,               -- attr.Num（"22", "66_4" など）
  article_title        TEXT,               -- 第二十二条
  caption              TEXT,               -- （各事業年度の所得の金額の計算の通則）
  breadcrumb           TEXT,               -- 第二編 > 第一章 > 第一節（章節の見出しを連結）
  plain_text           TEXT NOT NULL,      -- 検索用の本文（項・号・表を平文化。NFKC 正規化済み）
  body_json            BLOB NOT NULL       -- 表示用: Article 要素のサブツリー JSON（gzip）
);
CREATE INDEX idx_articles_law_seq ON articles(law_id, seq);
CREATE INDEX idx_articles_law_num ON articles(law_id, section, article_num);

-- 全文検索（外部コンテンツ FTS5、trigram トークナイザ）
-- Phase 2 で追加。MVP では作らない
CREATE VIRTUAL TABLE articles_fts USING fts5(
  plain_text, caption, article_title,
  content='articles', content_rowid='id',
  tokenize='trigram'
);
-- articles への INSERT/DELETE と同期するトリガを張る

-- 同期ログ
CREATE TABLE sync_runs (
  id INTEGER PRIMARY KEY, started_at TEXT, finished_at TEXT,
  status TEXT, laws_checked INTEGER, laws_updated INTEGER, bytes_downloaded INTEGER, error TEXT
);

-- 雑多なメタ
CREATE TABLE app_meta (key TEXT PRIMARY KEY, value TEXT);  -- last_catalog_sync_at, last_revisions_refresh_date, schema_version
```

### 設計上のポイント

- **条を単位**にする。検索ヒットの粒度・閲覧のアンカー・差し替えの単位がすべて条で揃う
- 表示は `body_json`（条のサブツリーそのまま）から描画するので、項・号・表・ルビの表現をテーブル設計に落とし込まなくて済む。検索は `plain_text` に平文化したものを使う
- 過去リビジョンの本文は保持しない（v1）。現行のみ。「時点指定（asof）」は Phase 3 で API 直接取得として扱う
- 附則は税法では膨大（租税特別措置法など）。`section='suppl'` で区別し、検索のデフォルトは本則のみ・切替で附則も対象、とする

## 6. 検索設計（R2）

### 6.1 検索モード（1つの検索窓で自動判定）

| 入力例 | モード | フェーズ | 実装 |
|---|---|---|---|
| `法人税` `措置法` | 法令名検索 | MVP | `laws.title / abbrev / title_kana` に LIKE。略称辞書（法法・所法・消法・措法・通法・徴法・相法・地法 …）で展開。結果をタップすると最新本文を取得して開く |
| `法人税法22条` `法法２２` `措法42の12の5` | 条番号ジャンプ | MVP | 正規表現で「法令名/略称 + 条番号（枝番 `の` 対応）」を抽出 → 法令を開き `articles(law_id, section, article_num)` の条へスクロール。候補が複数なら一覧表示 |
| （閲覧画面内で）`損金` | 本文内検索 | MVP | 開いている法令の `articles.plain_text` に LIKE（NFKC 正規化済み）。ヒット件数、前へ／次へ、ハイライト。ブラウザの「ページ内検索」相当 |
| `役員給与 損金` `インボイス` | 横断全文検索 | Phase 2 | FTS5 MATCH（AND 結合）。`snippet()` でハイライト。3文字未満の語は `LIKE` にフォールバック。対象法令の本文を先読み済みであることが前提 |

### 6.2 横断全文検索の実装（Phase 2）

- **FTS5 + trigram トークナイザ**（SQLite 3.34+。`sqlite3_flutter_libs` の同梱 SQLite で利用可能な想定。Phase 0 で確認）
  - 日本語は分かち書きができないため、部分一致に強い trigram を採用。形態素解析器を端末に入れない
  - `case_sensitive=0`。索引・クエリの双方を NFKC 正規化（全角英数字→半角、「第２２条」→「第22条」）してから投入する
- 絞り込み: 法令種別（法律 / 政令 / 省令・規則）、分類、本則のみ／附則含む、法令の指定
- 並び: 法令の重要度（主要法令セットを上位）→ FTS の rank。同一法令内は `seq` 順
- 結果表示: 法令名 ＋ 条見出し ＋ ハイライト付きスニペット。タップで該当条に直接スクロール
- 索引サイズは本文の 2〜3 倍になり得る。Phase 0 で実測し、大きすぎる場合は `detail='none'` や附則の索引除外で調整

### 6.3 オンライン補助検索（Phase 3）

- `GET /keyword` を使い、スコープ外の全法令も横断検索する「e-Gov で検索」ボタン。オフライン時は非表示

## 7. 本文パース（JSON → 条文）

入力は `/law_file/json/{revision_id}` の `{tag, attr, children}` ツリー。

1. `Law > LawBody` の直下を走査し、`MainProvision`、各 `SupplProvision`（`attr.AmendLawNum` を保持）、`AppdxTable` 等をセクションとして扱う
2. `Part / Chapter / Section / Subsection / Division` は見出し（`*Title`）を積んで `breadcrumb` にする。テーブル行にはしない
3. `Article` ごとに 1 行生成
   - `article_title` = `ArticleTitle` のテキスト、`caption` = `ArticleCaption` のテキスト、`article_num` = `attr.Num`
   - `plain_text` = 配下の `Sentence` を文書順に連結。`Paragraph` は `ParagraphNum`（`OldNum="true"` の場合は `attr.Num` から補う）、`Item` は `ItemTitle` を先頭に付けて改行区切り。`TableStruct` はセルをタブ区切りで平文化。`Rt`（ルビの読み）は除外
   - `body_json` = `Article` サブツリーを JSON 文字列化して gzip
4. `Article` を持たない `Paragraph` 直下（附則で多い）は仮想条 `article_num = null` として 1 行にまとめる
5. 実行は `Isolate.run` で行い UI スレッドを塞がない。巨大法令（十数MB）で `json.decode` のメモリが問題になる場合は、`/law_file/xml` を `xml` パッケージのイベントストリームで読む実装に差し替える（パーサはインターフェースで抽象化しておく）

## 8. 画面構成（R3）

| 画面 | 内容 |
|---|---|
| 検索（ホーム） | 検索窓、最近開いた法令、主要法令へのショートカット、同期状態バナー（最終同期時刻・改正あり件数） |
| 検索結果 | 法令名の一致一覧（種別・分類・施行日・「改正あり」バッジ）。条番号ジャンプの候補もここに出す。Phase 2 で横断検索の結果タブを追加 |
| 法令閲覧 | 開いたときに最新本文を取得（取得中はスケルトン、キャッシュがあれば先に表示）。条の連続表示（`ListView` + 遅延描画）。左ドロワーに目次（編章節条）。上部に本文内検索（ヒット数・前後移動・ハイライト）。条の長押しでコピー／共有／e-Gov で開く（`https://laws.e-gov.go.jp/law/{law_id}`）。ヘッダに「施行日 / 改正法令 / 取得日時」 |
| 改正履歴 | 閲覧画面のタブ。`law_revisions` を時系列表示。未施行改正は「施行予定 2026-10-01（所得税法等の一部を改正する法律）」のように強調 |
| 法令一覧 | 分類・種別でグルーピングした全スコープ一覧。キャッシュ済み／未取得／改正あり をアイコンで表示 |
| 設定 | 今すぐ更新、先読み ON/OFF、キャッシュ削除、同期ログ、出典表示・ライセンス |

条文表示は `body_json` を再帰的に Widget へ変換する `LawNodeRenderer` を用意する（`Paragraph` は項番号付きぶら下げ、`Item` はインデント、`TableStruct` は `Table`、`Ruby` は `ruby_text` 相当）。

## 9. 技術選定

| 領域 | 選定 | 理由 |
|---|---|---|
| フレームワーク | Flutter stable（最新）/ Dart 3 | 指定。iOS / Android を主対象。macOS / Windows も同じコードで動く |
| 状態管理・DI | `riverpod`（`riverpod_generator`） | Repository/Service の注入とテスト差し替えが容易 |
| ルーティング | `go_router` | 条へのディープリンク（`/law/:lawId/article/:num`）を URL で表せる |
| HTTP | `dio` | gzip、タイムアウト、リトライ（interceptor）、キャンセル |
| DB | `drift` + `sqlite3_flutter_libs` | 型安全な SQL、FTS5 対応、バックグラウンド isolate 対応、デスクトップでも同じコードが動く（シード生成に必要） |
| モデル | `freezed` + `json_serializable` | API レスポンス型と不変モデル |
| 圧縮 | `dart:io` の `gzip` | `body_json` の圧縮 |
| 正規化 | `unorm_dart`（NFKC） | 全角半角の揺れ吸収 |
| ログ | `logger` | 同期の診断 |
| テスト | `flutter_test`, `mocktail`, drift の `NativeDatabase.memory()` | |
| CI | GitHub Actions: `flutter analyze` / `flutter test` / `dart format --set-exit-if-changed` | |

- Web は当面対象外。理由: e-Gov API の CORS 設定が未確認、および `sqlite3` の wasm 構成が別途必要
- バックグラウンド同期（`workmanager` 等）は使わない（非要件）

## 10. プロジェクト構成

```
zeibun/
├── lib/
│   ├── main.dart
│   ├── app.dart                      # MaterialApp.router、テーマ
│   ├── core/
│   │   ├── config/law_scope.dart     # 対象法令ルール（§2）
│   │   ├── config/law_abbrev.dart    # 略称辞書（法法・所法 …）
│   │   ├── text/normalize.dart       # NFKC・条番号パース
│   │   └── logging.dart
│   ├── data/
│   │   ├── egov/                     # API クライアント（純 Dart、Flutter 非依存）
│   │   │   ├── egov_api_client.dart
│   │   │   └── models/              # LawsResponse, RevisionsResponse, LawNode …
│   │   ├── db/
│   │   │   ├── database.dart         # drift スキーマ・マイグレーション
│   │   │   ├── tables/*.dart
│   │   │   └── daos/*.dart           # LawDao, ArticleDao, SearchDao, SyncDao
│   │   ├── parser/
│   │   │   ├── law_parser.dart       # LawNode → ArticleRecord[]（§7）
│   │   │   └── plain_text.dart
│   │   └── repositories/
│   │       ├── law_repository.dart
│   │       ├── search_repository.dart
│   │       └── sync_service.dart     # §4 の同期本体（純 Dart）
│   └── features/
│       ├── search/                   # 検索窓・結果
│       ├── law_viewer/               # 閲覧・目次・LawNodeRenderer
│       ├── revisions/                # 改正履歴
│       ├── law_list/
│       ├── sync/                     # 同期バナー・先読み進捗
│       └── settings/
├── tool/
│   └── build_seed.dart               # シード DB 生成（Phase 2、§4.6）
├── assets/seed/                      # 生成物（Git LFS もしくはリリース時のみ生成）
├── test/
│   ├── data/egov/                    # 固定レスポンス JSON でのデコード
│   ├── data/parser/                  # 実法令 JSON（小さいもの）でのパース検証
│   ├── data/repositories/           # 同期の差分ロジック（fake API + in-memory DB）
│   └── features/                     # Widget テスト
└── docs/
```

`lib/data` は Flutter に依存させない（`dart:io` と drift のみ）。これで `tool/build_seed.dart` と単体テストが Flutter なしで動く。

## 11. 品質・運用上の設計

- **失敗しても壊れない**: 本文の差し替えは条単位ではなく法令単位のトランザクション。失敗した法令は `body_revision_id` が古いまま残り、次に開いたとき（または次回起動の先読み）で再試行される
- **リトライ**: 5xx・タイムアウトは指数バックオフで 3 回。4xx は記録して次へ
- **マナー**: 並列 3、5 req/s 上限、`Accept-Encoding: gzip`、`User-Agent: zeibun/<version>` を付与
- **通信量**: 起動時は一覧の数十KB。法令を開くときにその法令の本文（数百KB〜十数MB。租税特別措置法クラスが最大）。先読み ON の起動で改正があった日は数MB程度
- **端末容量**: 開いた法令の本文だけを持つので MVP では数十MB 以内。Phase 2 の全件先読み＋索引で数百MB になる可能性があり、そのときに附則の扱いを決める
- **巨大法令の体感**: 租税特別措置法・同施行令は取得＋パースに数秒かかる見込み。閲覧画面は「取得中」のスケルトン表示にし、キャッシュがあれば先に古い本文を出してから差し替える
- **スキーマ移行**: drift のマイグレーション。本文の再パースが必要な変更（`plain_text` の作り方を変える等）は `app_meta.parser_version` を上げ、全法令を再取得ではなく**ローカルの `body_json` から再生成**する
- **出典**: 設定画面と閲覧画面のフッタに「出典: e-Gov法令検索（https://laws.e-gov.go.jp/）」を表示。取得日時も併記

## 12. テスト方針

| 対象 | 方法 |
|---|---|
| API デコード | `/laws`, `/law_revisions`, `/law_file/json` の固定レスポンスを `test/fixtures` に置き、モデルへの変換を検証 |
| パーサ | 小さめの実法令（例: 地方法人税法）の JSON をフィクスチャにし、条数・見出し・`plain_text` のスナップショットテスト。`OldNum`、枝番条（`第六十六条の四`）、表、ルビ、附則の各ケース |
| 同期ロジック | fake `EgovApiClient` と in-memory DB で NEW / REVISED / CORRECTED / MISSING / 途中失敗→再開 のシナリオ |
| 検索 | in-memory DB に投入し、法令名・条番号ジャンプ・全文（2文字語のフォールバック含む）の結果を検証 |
| UI | 検索→閲覧→条ジャンプの Widget テスト |
| 結合（手動） | 実 API に対する起動時同期の所要時間・通信量、主要税法を開くときの取得＋パース時間の計測（Phase 0 のスパイクを流用） |

## 13. 開発フェーズ

### Phase 0: スパイク（実機・実 API で確認。設計の未確定事項を潰す）

1. `category_cd=023` が「国税」を返すか。返さなければ全件取得＋分類名フィルタに切替
2. `/law_file/json` と `/law_file/xml` の実レスポンスを主要税法で取得し、パーサのフィクスチャにする。`/law_data` のパラメータ（`elm`, `asof`, `law_full_text_format`）も確認
3. 主要税法 10 件の本文サイズと、Dart での `json.decode`＋パース時間・メモリ（Android 中位機）。租税特別措置法で XML ストリーム読みが必要か判断
4. 上記から「法令を開くまでの体感時間」を確定し、本書を v0.2 に更新

### Phase 1: MVP（起動時同期 ＋ 法令名検索 ＋ 最新本文の閲覧・本文内検索）

- プロジェクト雛形、CI、API クライアント、DB、パーサ
- 起動時同期（§4: 一覧の最新化と改正検知）、同期バナー、「改正あり」バッジ
- 法令一覧、法令名検索（略称辞書）、条番号ジャンプ
- 法令閲覧: 開いたときに最新リビジョンの本文を取得・キャッシュ、目次、条アンカー、本文内検索
- 改正履歴タブ（開いた法令の `/law_revisions`。未施行改正の施行予定日を表示）
- 出典表示

### Phase 2: 横断全文検索

- 対象法令の本文先読み（進捗画面、Wi-Fi 推奨表示、シード DB 同梱の検討）
- FTS5 trigram 索引、スニペット、フィルタ、本則/附則切替。`sqlite3_flutter_libs` の SQLite で FTS5 trigram が使えるか、索引サイズの実測はこの段階で行う
- 最近見た条文、ブックマーク（ブックマーク法令は先読み対象）

### Phase 3: 改正まわり・拡張

- 改正履歴画面、未施行改正の一覧（施行日順）、「今日施行された改正」通知バナー
- 時点指定（`asof`）での条文表示（API 直接取得）
- `/keyword` によるスコープ外のオンライン横断検索
- 改正前後の条文差分表示（旧リビジョンを API から取得して比較）

## 14. 未確定事項・確認したいこと

1. **対象範囲**: 「国税」分類 ＋ 地方税法まわり、という定義でよいか。関税関係を含めてよいか。通達は対象外でよいか
2. **プラットフォーム**: iOS / Android の2つでよいか（Web を含めるなら CORS と wasm SQLite の調査が必要）
3. **附則の扱い**: 税法は附則（経過措置）が実務上重要な一方、量が多い。MVP の閲覧・本文内検索では全部を対象にする。Phase 2 の横断検索で索引に含めるかはそのときに決める
4. **過去条文の必要性**: 「令和X年4月1日時点の条文」のような時点指定を v1 に入れるか（設計上は Phase 3）
5. **横断全文検索の必要性と時期**: 「語句で複数の税法を横断して条文を探す」がどの程度必要か。必要なら Phase 2 で対象法令の本文先読み（数百MB規模）を入れる
