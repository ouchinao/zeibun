# zeibun 設計書 — 税制法令検索アプリ（Flutter × e-Gov 法令API v2）

- 状態: ドラフト v0.5（2026-09-23）— Phase 0 の実 API 計測を反映し、レビューで未確定事項を決定
- 関連: [e-Gov 法令API v2 調査メモ](./egov-law-api-v2.md)、[公式 OpenAPI 仕様 v2.1.139](./lawapi-v2.yaml)、[Phase 0 スパイク](../spike/README.md)

### v0.4 からの変更点（レビューでの決定）

| # | 決定 | 内容 |
|---|---|---|
| 1 | 改正附則は**既定で除いて取得**（案 A） | 初回表示を軽くする。附則タブの「改正附則を読み込む」を 1 回タップすると全文を取り直し、以後はキャッシュから表示 |
| 2 | **MVP はモバイル（iOS / Android）のみ** | Web は Phase 3 以降の候補。CORS は問題ないので中継サーバは不要だが、広告を載せる前提なら COOP/COEP ヘッダを設定できるホスティング（Cloudflare Pages 等）を使う。`lib/data` に `dart:io` を入れない方針は維持し、Web への道は残す |
| 3 | 廃止・失効した税法は**「参考」として一覧に載せる** | 63 件。別グループ・「廃止」バッジ |

### v0.3 からの変更点（Phase 0 実測による）

| # | 変更 | 根拠（2026-09-23 実測） |
|---|---|---|
| 1 | 本文の取得を **`/law_data`（XML、gzip）** に変更。`/law_file` は使わない | `/law_file` は非圧縮で返る（所得税法 16.4MB がそのまま）。`/law_data` は gzip で約 24 分の 1（672KB） |
| 2 | 本文は既定で **改正法令の附則を除いて取得**（`omit_amendment_suppl_provision=true`）。「改正附則も読む」は法令ごとのオプション | 所得税法は附則を含むと 16.4MB・要素 20 万・Dart デスクトップで decode 1.7 秒・RSS +157MB。除くと 3.7MB・0.4 秒。中位 Android では前者は OOM リスク |
| 3 | Web の技術的な障害が無いことを確認（採否は v0.5 で「MVP はモバイルのみ」に決定） | `access-control-allow-origin: *` を確認 |
| 4 | 未施行改正の検知に `current_revision_info.law_revision_id` のみを使う。`current_revision_status` は使わない | 252 件中 13 件で `current_revision_info.current_revision_status` が `PreviousEnforced`（asof 基準で評価される模様）。`law_revision_id` は 252 件すべて asof なしの現行と一致 |
| 5 | 廃止・失効した税法も**「参考」として一覧に載せる**（既定の検索結果では末尾に「廃止」バッジ付き）。一覧取得に `repeal_status` の絞り込みは付けず、値を保存して表示で区別する | `013` は廃止・失効 35 件を含めて 287 件。本文は廃止法令でも取得できる（実測）。レビューでの決定 |
| 6 | 取得した本文の `revision_info.law_revision_id` が要求したリビジョンと一致することを保存前に検証する（§11 T） | `/law_data` の封筒にメタが付くので無料で検証できる |

### v0.2 からの変更点

| # | 変更 | 根拠 |
|---|---|---|
| 1 | 事項別分類コードを **国税=`013`、地方財政=`036`** に修正（v0.2 の `023`/`008` は「国債」「国有財産」） | 公式仕様 `category_cd` 表 |
| 2 | 本文の取得形式を **XML を正**とし、JSON は差し替え可能なオプションに変更 | 公式仕様が JSON 形式を「試行版・仕様変更あり」と明記。サーバを持たない構成では致命的 |
| 3 | 未施行改正の検知を **MVP に前倒し**。`/laws?asof=2099-12-31` を使い追加 2 リクエストで済ませる | `/laws` の `asof` と `current_revision_info` の仕様 |
| 4 | 明示指定の法令 ID を実カタログで 12 件に確定。`/laws` の `law_id` は部分一致・単一指定なので 1 件 1 リクエスト | 公式仕様と実カタログ集計 |
| 5 | §11 にセキュリティ設計（STRIDE）を新設。免責表示とバックオフ規定を追加 | 設計レビュー |
| 6 | Web を「CORS 確認後に判断する条件付き対象」に変更 | Flutter Web 自体は可。e-Gov API の CORS ヘッダが未確認 |
| 7 | 起動時同期・本文取得・先読みの重複記述を §4 に統合。Phase 2 以降の詳細は縮約 | 冗長性の整理 |

## 1. 目的と要件

税制に関する法令（所得税法、法人税法、消費税法、相続税法、租税特別措置法、国税通則法、地方税法 など）を、**常に最新の条文で**、スマホから素早く検索・閲覧できるアプリを作る。

| # | 要件 | 補足 |
|---|---|---|
| R1 | 起動時に e-Gov 法令API v2 から一覧を取り直し、改正を検知する | ユーザー操作は不要。未施行改正の有無も表示する |
| R2 | 法令名で検索し、目的の法令の**最新本文**を見られる | 開いたときに最新リビジョンを取得。本文内検索・条番号ジャンプ |
| R2' | 条文の横断全文検索 | Phase 2。本文をまとめて端末に持つ必要があるため MVP から外す |
| R3 | 条・項・号・表を崩さず表示し、目次から移動できる | |
| R4 | 一度開いた法令はオフラインでも閲覧できる | 本文は端末にキャッシュ。同期はベストエフォート |
| R5 | データソースは e-Gov 法令API v2 のみ。自前サーバを持たない | |
| R6 | 出典（e-Gov法令検索）を明記し、非公式アプリである旨と免責を表示する | 公共データ利用規約（PDL1.0） |

非要件: バックグラウンド定期同期、通達・質疑応答事例・判例、条文の解説や AI 要約、ユーザーアカウント。

## 2. 対象法令（スコープ）

e-Gov の事項別分類は 1 法令 1 分類で、税法は複数の分類に散る。実カタログ（2026-09、`spike/fixtures/catalog_tax_snapshot.json`）での集計は次のとおり。

| ルール | 内容 | 件数 |
|---|---|---|
| 分類 `013` 国税 の全件 | 所得税法・法人税法・消費税法・相続税法・租税特別措置法・国税通則法・国税徴収法・印紙税法・登録免許税法・地方法人税法・税理士法・関税法・関税定率法 と施行令・施行規則。法律 62 / 政令 97 / 省令 93。廃止なし。58 件に未施行改正あり | 252 |
| 分類 `036` 地方財政 のうち題名が `税` に一致 | 地方税法・同施行令・同施行規則、地方交付税法、各種譲与税法 | 46 |
| 法令 ID の明示指定 | 財務通則 `003`: 国税収納金整理資金に関する法律・同施行令・同事務取扱規則、収入印紙及び自動車重量税印紙の売りさばきに関する省令、防衛特別法人税に関する政令・省令、防衛特別所得税に関する政令（未施行）。行政組織 `011`: 国税不服審判所組織令・同組織規則、国税審議会令、税制調査会令。行政手続 `021`: 国税関係法令に係る情報通信技術を活用した行政の推進等に関する省令 | 12 |
| 上記のうち廃止・失効（`repeal_status != None`） | 「参考」扱い。一覧では「廃止・失効（参考）」グループに分け、検索結果では末尾に「廃止」バッジ付きで出す。本文は取得・閲覧できる | 国税 35（LossOfEffectiveness 31 / Repeal 3 / Expire 1）＋地方財政の「税」28（LossOfEffectiveness 25 / Repeal 3） |

- 合計 約 310 法令（現行）＋ 廃止・失効 63 法令（参考）。ルールは `lib/core/config/law_scope.dart` に「分類コード」「分類コード＋題名の正規表現」「法令 ID」の 3 種で宣言する（スパイクの `LawScope.tax` がその原型）
- 関税関係は「国税」分類に含まれるのでそのまま入る。除外したければ除外ルールで対応
- 分類コード表（全 50）は公式仕様の `category_cd` スキーマが正。名称→コードの対応表をアプリに持ち、`/laws` の `revision_info.category`（名称）と突合する

## 3. 全体アーキテクチャ

**クライアント完結（ローカルファースト）**。アプリが直接 e-Gov API を呼び、端末内 SQLite に法令一覧と取得済み本文を保持する。

1. **起動時**: `/laws` で対象法令の一覧（現行リビジョン ID と次の未施行リビジョン ID）を取り直す。通信は十数リクエスト・数十 KB
2. **検索**: 法令名・略称で一覧を検索して法令を選ぶ
3. **閲覧**: その法令の現行リビジョンの本文を `/law_data/{revision_id}`（XML、gzip）で取得し、パースして表示・キャッシュ。次回以降はリビジョンが同じならローカルから開く

```
┌──────────────────────── Flutter アプリ ────────────────────────┐
│ UI (features/*) ── Riverpod ──▶ Repository 層                  │
│   検索 / 閲覧 / 改正履歴 / 同期状態    LawRepository            │
│                                       SyncService              │
│                          ┌─────────────┼──────────────┐        │
│                  EgovApiClient    LawDatabase(drift)   LawParser│
│                  GET /laws        laws / law_revisions (Isolate)│
│                  GET /law_revisions   articles                  │
│                  GET /law_data (xml)                            │
└────────────┬───────────────────────────────────────────────────┘
             │ HTTPS (gzip)。認証なし・レート制限ヘッダなし・HTTP キャッシュヘッダなし
             ▼
   https://laws.e-gov.go.jp/api/2
```

この構成を選ぶ理由: API が無認証・無料で対象が約 310 法令と小さい。R4 のために端末内キャッシュがどのみち必要。起動時同期は端末内で完結できる。

### 本文の取得形式: `/law_data` の XML を正とする

XML と JSON は同じ法令標準XML の表現違いで、要素名も属性も同一。公式仕様は **JSON 形式を「試行版であり仕様変更が発生する場合がある」と明記**している。サーバを持たない本アプリでは JSON の変更がそのままアプリ障害になるため、XML を取得形式にする。

- エンドポイントは `/law_data/{revision_id}?response_format=xml&law_full_text_format=xml`。`/law_file` は gzip されず所得税法で 16MB がそのまま流れるのに対し、`/law_data` は gzip で 672KB。封筒（`law_data_response`）の `revision_info` で取得したリビジョンを検証できる利点もある
- 既定では `omit_amendment_suppl_provision=true` を付け、改正法令の附則（各改正法の経過措置）を除いた本文を取る。所得税法で 16.4MB → 3.8MB、租税特別措置法で 14.5MB → 6.4MB。法令ごとに「改正附則も読む」を選ぶと全文を取り直す（§4.5）
- アプリ内で XML を `LawNode {tag, attr, children}` のツリー（JSON と同じ形）に変換し、パーサはこのツリーだけを入力にする。スパイクで XML 由来と JSON 由来、`/law_file` 由来と `/law_data` 由来のツリーが同一になることを確認済み
- 全文（改正附則込み）の所得税法は要素 20 万・Dart デスクトップで decode 1.7 秒・RSS +157MB。全文を扱うときは `xml` パッケージのイベントストリームで条単位に読み、メモリを条 1 つ分に抑える実装を使う（Phase 1 の後半）
- JSON は `LawNode.fromJson` として残し、実験用途に限る。2.1.139 で追加された `json_format=light` は属性が落ちる（`Article@Num` が無い）ので使わない

### 検討したが採らない案

| 案 | 不採用の理由 |
|---|---|
| サーバ側全文検索（`/keyword` のみ） | オフライン不可。ただし Phase 3 でスコープ外法令の補助検索に使う（`category_cd` で絞れる） |
| 自前ジョブで日次スナップショットを配信 | R5 に反する。Phase 2 の先読みが遅すぎた場合の再検討事項 |
| 起動時に本文を全件先読み | 初回に数百 MB。Phase 2 で設定オプションとして導入 |

## 4. 起動時同期と本文取得

### 4.1 方針

- 起動直後にローカル DB で画面を使える状態にし、同期は裏で走らせる
- 起動時に取るのは一覧だけ。本文は法令を開いたときに取る（オンデマンド）
- 初回起動でもブートストラップ画面は不要。一覧が取れなければ「一覧を取得できませんでした」を出し、キャッシュ済みの法令だけ開ける
- 前回成功から 10 分以内の再起動はカタログ取得を省略する（設定で無効化可）

### 4.2 シーケンス

```
起動
 ├ DB open → 画面表示（前回同期済みデータ）
 └ SyncService.runOnLaunch()
     1. 一覧取得（すべて asof=2099-12-31 を付ける。repeal_status は絞らず値を保存する。1 行に
        revision_info = その時点で最新（未施行を含む）の履歴、
        current_revision_info = 現時点の現行履歴 が入る）
          GET /laws?category_cd=013&asof=2099-12-31&limit=1000   … 国税 287 件（現行 252 + 廃止等 35）、gzip 約 41KB
          GET /laws?category_cd=036&asof=2099-12-31&limit=1000   … 地方財政 162 件、約 20KB（題名で絞ると 74 件）
          GET /laws?law_id=<ID>&asof=2099-12-31                  … 明示指定 12 件（1 件ずつ、各 0.6KB）
        count == limit なら next_offset で続きを取る。合計 14 リクエスト・約 70KB・5 req/s で 3 秒
     2. スコープ判定（§2）→ 対象法令リスト（repeal_status != None は「参考」フラグ付き）
     3. ローカル laws と突合（比較には law_revision_id と updated だけを使う。
        current_revision_info.current_revision_status は asof 基準で評価されるため使わない）
        - 未登録                                         → NEW
        - current_revision_info.law_revision_id が違う  → REVISED（改正の施行 / 施行日到来）
        - law_revision_id 同じ・updated が違う           → CORRECTED（訂正・再登録）
        - revision_info.law_revision_id が現行と違う     → 未施行改正あり（実測 252 件中 55 件）
        - ローカルにあるが一覧に無い                      → MISSING（削除せずフラグ）
     4. laws を更新（current_revision_id / catalog_updated / has_pending_amendment）
        本文キャッシュ（body_revision_id）は残す → 一覧側と食い違えば「要更新」
     5. 先読み対象（§4.4）のうち REVISED / CORRECTED のものは本文を取り直す（並列 3、5 req/s）
     6. sync_runs に記録。UI に「最終同期 09:12 / 改正あり 3 件 / 施行予定あり 55 件」

法令を開いたとき（LawRepository.openLaw(lawId)）
     a. current_revision_id == body_revision_id → キャッシュから表示（通信なし）
     b. 違う（または未取得）→ GET /law_data/{current_revision_id}?response_format=xml
           &law_full_text_format=xml&omit_amendment_suppl_provision=true
        - オンライン: 取得 → 封筒の revision_info.law_revision_id を検証 → Isolate でパース →
          1 トランザクションで articles を差し替え → body_revision_id 更新 → 表示
        - オフライン: 古いキャッシュがあれば「○月○日時点の内容です（改正あり）」と注記して表示。
          無ければエラー表示
     c. 改正履歴タブを開いたとき GET /law_revisions/{law_id} を取り law_revisions を差し替える。
        「次に施行される改正」の日付はここから出す（asof 遠未来の revision_info は最も遠い
        施行日のものになるため。租税特別措置法なら 2030-01-01 施行分）
```

`current_revision_info` が返らない場合（仕様変更時の保険）は、`asof` 無しの一覧をもう 1 回取って現行を得る。

### 4.3 差分判定の根拠

- `/laws` に差分取得パラメータは無く、HTTP キャッシュヘッダも無い（`cache-control: no-store`）。一覧の `law_revision_id` と `updated` を前回値と比べるのが唯一の方法。`/law_revisions` には `updated_from` があるが法令 ID 指定が必須なので全体の差分検知には使えない
- 施行日到来は `/laws` 側で現行の `law_revision_id` が切り替わるので REVISED として拾える
- `laws.current_revision_id`（一覧の値）と `laws.body_revision_id`（本文を保存できたリビジョン）を別カラムにする。途中で kill されても次回起動時に再判定できる

### 4.4 先読み（オプション）

設定「よく使う法令を先読みする」を ON にすると、主要法令セット（所得税法・法人税法・消費税法・相続税法・国税通則法・国税徴収法・租税特別措置法・地方税法とその施行令・規則、約 30 件。スパイクの `majorTaxLaws`）とブックマーク、直近 30 日に開いた法令を、起動時同期の中で取り直す。Phase 2 ではこれを「スコープ全法令の先読み＋FTS 索引」に拡張する。

### 4.5 本文取得の手順（共通）

1. `GET /law_data/{revision_id}?response_format=xml&law_full_text_format=xml&omit_amendment_suppl_provision=true`（gzip、タイムアウト 30 秒、5xx は指数バックオフで 3 回、展開後の受信上限 64MB）。法令の「改正附則も読む」が ON のときは `omit_amendment_suppl_provision` を付けない
2. 封筒の `revision_info.law_revision_id` が要求した ID と一致しなければ破棄
3. `Isolate.run` で XML → `LawNode` → 条レコード（§7）。全文（改正附則込み）のときはイベントストリームで条単位に処理
4. 1 トランザクションで該当法令の `articles` を全削除 → 挿入、`laws.body_revision_id` / `body_synced_at` / `body_includes_amend_suppl` を更新
5. 失敗時は何も書かない（古いキャッシュが残る）

主要税法の実測（2026-09-23、`/law_data` XML gzip）: 所得税法 wire 222KB（附則除く）/ 672KB（全文）、法人税法 183KB / 310KB、租税特別措置法 667KB / 1.46MB、地方税法 674KB（附則除く）。データセンターからは各 0.5〜1.5 秒。

#### 「改正附則を除く」が何を落とすか（判断材料、2026-09-23 実測）

`omit_amendment_suppl_provision=true` は `SupplProvision@AmendLawNum` を持つ要素、つまり**過去の各改正法が持ち込んだ附則**を落とす。法令自身の制定時の附則（`AmendLawNum` なし）は残る。

| 法令 | 附則ブロック数 全文 → 除く | 附則の文字数 全文 → 除く | 全文の附則に「なお従前の例による」 |
|---|---|---|---|
| 所得税法 | 352 → 1（制定時、36 条） | 457 万字 → 22 万字 | 560 回 |
| 法人税法 | 343 → 1（制定時、21 条） | 44 万字 → 1.1 万字 | 415 回 |

- 落ちる内容は、各改正法の「施行期日」「経過措置（改正前の規定はなお従前の例による、○年分の所得税については…）」「罰則の適用に関する経過措置」。ほとんどは `Extract="true"` の抜粋で、1 改正あたり 1〜9 千字
- 実務で参照するのは、直近数年の税制改正の経過措置（例: 令和八年法律第十二号の附則）。それより古い附則はほぼ参照されないが、量の大半を占める
- 検討した案: A. 既定で除き法令ごとに全文へ切替 / B. 主要 12 法令だけ全文を既定 / C. 常に全文
- **決定: A**。初回表示を軽くすることを優先する。附則タブに「改正附則を読み込む（約 ○○KB）」ボタンを置き、タップで `omit_amendment_suppl_provision` なしで取り直して `articles` を差し替え、`laws.body_includes_amend_suppl = 1` にする。以後は同じリビジョンならキャッシュから表示し、改正で REVISED になったときは前回の設定（全文/除く）を引き継いで取り直す
- 附則の表示は「改正法令番号ごとに折りたたみ、新しい順」にする（所得税法の全文は 1,000 件超）

同期処理と本文取得は Flutter に依存しない純 Dart で書き、`dart run` でデスクトップからも動かせるようにする。スパイクの `EgovClient` / `LawParser` がその原型。

### 4.6 バックオフ規定（e-Gov への負荷を自分で増やさない）

- 自主制限: 並列 3、5 req/s、`Accept-Encoding: gzip`、`User-Agent: zeibun/<version>`
- 5xx・タイムアウトは 1s, 2s, 4s（±25% のジッタ）で最大 3 回。4xx は記録して次へ
- 起動時同期が 2 回連続で失敗したら、次回の自動同期までの間隔を 10 分 → 1 時間 → 6 時間 → 24 時間と伸ばす。成功でリセット。手動「今すぐ更新」は常に可
- 同一の一覧取得が失敗しても本文取得は試みない（一覧が取れないときはサーバ側障害の可能性が高い）

## 5. データモデル（SQLite / drift）

```sql
CREATE TABLE laws (
  law_id               TEXT PRIMARY KEY,   -- 例 340AC0000000034
  law_num              TEXT NOT NULL,
  law_type             TEXT NOT NULL,      -- Act / CabinetOrder / MinisterialOrdinance / Rule / ...
  title                TEXT NOT NULL,
  title_kana           TEXT,
  abbrev               TEXT,               -- API の略称（カンマ区切りで複数のことがある）
  category             TEXT,               -- 国税 / 地方財政 ...
  promulgation_date    TEXT,
  repeal_status        TEXT NOT NULL,      -- None / Repeal / Expire / Suspend / LossOfEffectiveness
  scope_reason         TEXT NOT NULL,      -- category:013 / title:036 / explicit
  current_revision_id  TEXT,               -- 現行リビジョン（current_revision_info）
  current_enforced_at  TEXT,
  catalog_updated      TEXT,               -- current_revision_info.updated
  has_pending_amendment INTEGER NOT NULL DEFAULT 0, -- asof 遠未来の revision_info が現行と違う
  body_revision_id     TEXT,               -- 本文を保存済みのリビジョン（NULL = 未取得）
  body_synced_at       TEXT,
  body_includes_amend_suppl INTEGER NOT NULL DEFAULT 0, -- 改正法令の附則を含めて取得したか
  missing_since        TEXT
);

CREATE TABLE law_revisions (                -- 改正履歴（開いた法令のみ。過去・現行・未施行）
  revision_id          TEXT PRIMARY KEY,   -- <law_id>_<YYYYMMDD>_<改正法令ID>
  law_id               TEXT NOT NULL REFERENCES laws(law_id),
  enforced_at          TEXT NOT NULL,
  promulgated_at       TEXT,
  scheduled_enforced_at TEXT,
  enforcement_comment  TEXT,
  amendment_law_id     TEXT,
  amendment_law_num    TEXT,
  amendment_law_title  TEXT,
  amendment_type       TEXT,               -- 1 新規 / 3 被改正 / 8 廃止
  status               TEXT NOT NULL,      -- CurrentEnforced / PreviousEnforced / UnEnforced / Repeal
  api_updated          TEXT,
  fetched_at           TEXT NOT NULL
);
CREATE INDEX idx_revisions_law ON law_revisions(law_id, enforced_at);

CREATE TABLE articles (                     -- 1 行 = 1 条（本則・附則・別表それぞれ）
  id                   INTEGER PRIMARY KEY,
  law_id               TEXT NOT NULL REFERENCES laws(law_id),
  revision_id          TEXT NOT NULL,
  seq                  INTEGER NOT NULL,
  section              TEXT NOT NULL,      -- main / suppl / appdx
  suppl_amend_law_num  TEXT,
  path                 TEXT NOT NULL,      -- main/Article_22、suppl[令和八年法律第十二号]/Article_3
  article_num          TEXT,               -- attr.Num（"22", "66_4"）。仮想条は NULL
  article_title        TEXT,
  caption              TEXT,
  breadcrumb           TEXT,               -- 第二編 > 第一章 > 第一節
  plain_text           TEXT NOT NULL,      -- 検索用の平文（NFKC 正規化済み）
  body_json            BLOB NOT NULL       -- 表示用: 条のサブツリー JSON（gzip）
);
CREATE INDEX idx_articles_law_seq ON articles(law_id, seq);
CREATE INDEX idx_articles_law_num ON articles(law_id, section, article_num);

-- Phase 2: 外部コンテンツ FTS5（trigram）。MVP では作らない
-- CREATE VIRTUAL TABLE articles_fts USING fts5(plain_text, caption, article_title,
--   content='articles', content_rowid='id', tokenize='trigram');

CREATE TABLE sync_runs (
  id INTEGER PRIMARY KEY, started_at TEXT, finished_at TEXT,
  status TEXT, laws_checked INTEGER, laws_updated INTEGER, bytes_downloaded INTEGER, error TEXT
);
CREATE TABLE app_meta (key TEXT PRIMARY KEY, value TEXT);  -- last_catalog_sync_at, parser_version, backoff_level, schema_version
```

- 条を単位にする。検索ヒットの粒度・閲覧のアンカー・差し替えの単位が条で揃う
- 表示は `body_json` から描画するので、項・号・表・ルビをテーブル設計に落とし込まない
- 過去リビジョンの本文は保持しない。時点指定は Phase 3 で API 直接取得
- 附則は `section='suppl'` で区別し、本文内検索のデフォルトは本則のみ・切替で附則も対象。既定の取得では改正法令の附則が含まれないので、附則タブに「改正附則を含めて取得する」ボタンを置く（所得税法で附則レコード 39 → 1,074 件）

## 6. 検索設計（R2）

| 入力例 | モード | フェーズ | 実装 |
|---|---|---|---|
| `法人税` `措置法` | 法令名検索 | MVP | `laws.title / abbrev / title_kana` に LIKE。略称辞書（法法・所法・消法・措法・通法・徴法・相法・地法 …）で展開。API の `abbrev`（租特法 など）も辞書に取り込む。廃止・失効法令は現行の後ろに「廃止」バッジ付きで並べる |
| `法人税法22条` `法法２２` `措法42の12の5` | 条番号ジャンプ | MVP | 正規表現で「法令名/略称 + 条番号（枝番 `の`）」を抽出 → `articles(law_id, section, article_num)` の条へスクロール。候補が複数なら一覧 |
| （閲覧画面内で）`損金` | 本文内検索 | MVP | 開いている法令の `articles.plain_text` に LIKE（NFKC 正規化済み）。件数・前後移動・ハイライト |
| `役員給与 損金` | 横断全文検索 | Phase 2 | FTS5 trigram、AND 結合、`snippet()`。3 文字未満は LIKE にフォールバック。ユーザー入力は各トークンをダブルクォートで囲んで MATCH 式に渡す（演算子として解釈させない） |

Phase 2 の索引は本文の 2〜3 倍になり得る。既定の取得（改正附則除く）なら `plain_text` は所得税法 38 万字・法人税法 35 万字・地方税法 131 万字で、スコープ全体でも数千万字（数十 MB）に収まる見込み。

## 7. 本文パース（LawNode → 条文）

入力は `LawNode` ツリー（XML から変換。JSON からも同じ形）。スパイクの `LawParser` / `PlainText` が実装。

1. `/law_data` の封筒（`law_data_response > law_full_text > Law`）なら `Law` を取り出す。`Law > LawBody` の直下を走査し、`MainProvision`、各 `SupplProvision`（`AmendLawNum` を保持）、`Appdx*`（別表・別記・様式）をセクションとして扱う。`TOC`・`LawTitle`・`EnactStatement`・`Preamble` はレコード化しない
2. `Part / Chapter / Section / Subsection / Division` は `*Title` を積んで `breadcrumb` にする
3. `Article` ごとに 1 行。`article_title` = `ArticleTitle`、`caption` = `ArticleCaption`、`article_num` = `attr.Num`
4. `plain_text`: `Sentence` を文書順に連結。`Paragraph` は `ParagraphCaption` を独立行にした上で項番号（`ParagraphNum`。`OldNum="true"` で空なら `attr.Num`）を先頭に。`Item` / `Subitem*` は見出しを先頭に付けて改行区切り。表はセルをタブ、行を改行で区切る。`Rt`（ルビの読み）は除外
5. `Article` を持たない `Paragraph` の並び（附則に多い）は仮想条 `article_num = NULL` として 1 行にまとめる
6. 未知のタグは子を辿るだけで例外にしない。パース例外は法令単位で捕捉し、古いキャッシュを残す
7. `Isolate.run` で実行し UI スレッドを塞がない

## 8. 画面構成（R3）

| 画面 | 内容 |
|---|---|
| 検索（ホーム） | 検索窓、最近開いた法令、主要法令へのショートカット、同期状態バナー（最終同期・改正あり件数・施行予定件数） |
| 検索結果 | 法令名の一致一覧（種別・分類・施行日・「改正あり」「施行予定 ○月○日」バッジ）。条番号ジャンプの候補もここに出す |
| 法令閲覧 | 開いたときに最新本文を取得（取得中はスケルトン、キャッシュがあれば先に表示）。条の連続表示（`ListView` 遅延描画）。左ドロワーに目次。上部に本文内検索。条の長押しでコピー／共有／e-Gov で開く（`https://laws.e-gov.go.jp/law/{law_id}`）。ヘッダに「施行日 / 改正法令 / 取得日時 / リビジョン」を常時表示 |
| 改正履歴 | 閲覧画面のタブ。`law_revisions` を時系列表示。未施行改正は「施行予定 2026-10-01（所得税法等の一部を改正する法律）」と強調 |
| 法令一覧 | 分類・種別でグルーピングした全スコープ一覧。キャッシュ済み／未取得／改正あり をアイコンで表示。末尾に「廃止・失効（参考）」グループ（廃止日・状態を表示、グレー表示） |
| 設定 | 今すぐ更新、先読み ON/OFF、キャッシュ削除、同期ログ、出典・免責・ライセンス |

条文表示は `body_json` を再帰的に Widget に変換する `LawNodeRenderer`（`Paragraph` は項番号付きぶら下げ、`Item` はインデント、`TableStruct` は `Table`、`Ruby` はルビ表示）。WebView は使わない。

## 9. 技術選定

| 領域 | 選定 | 理由 |
|---|---|---|
| フレームワーク | Flutter stable / Dart 3 | MVP は iOS / Android。Web は Phase 3 以降の候補（下記）。macOS / Windows も同じコード |
| 状態管理・DI | `riverpod`（`riverpod_generator`） | Repository/Service の注入とテスト差し替え |
| ルーティング | `go_router` | 条へのディープリンク `/law/:lawId/article/:num` |
| HTTP | `dio` | gzip、タイムアウト、リトライ、キャンセル。Web でも同じコードが動く |
| XML | `xml` | DOM とイベントストリームの両方。DTD の外部実体を展開しない |
| DB | `drift` + `sqlite3_flutter_libs` | 型安全 SQL、FTS5、バックグラウンド isolate、デスクトップでも動く。Web は `sqlite3.wasm` + Worker 構成 |
| モデル | `freezed` + `json_serializable` | |
| 正規化 | `unorm_dart`（NFKC） | 全角半角の揺れ吸収 |
| テスト | `flutter_test`, `mocktail`, drift の `NativeDatabase.memory()` | |
| CI | GitHub Actions: `flutter analyze` / `flutter test` / `dart format --set-exit-if-changed` / `dart pub outdated` の定期確認 | |

**Web について**: e-Gov API は `/laws`・`/law_data`・`/law_revisions`・`/keyword`・`/law_file` のすべてと OPTIONS プリフライトで `access-control-allow-origin: *` を返す（2026-09-23 実測）。中継サーバは不要で、静的ホスティングだけで動く。ただし次の制約がある。

| 制約 | 内容 | 対処 |
|---|---|---|
| SQLite | `sqlite3_flutter_libs` は Web 非対応。drift の `WasmDatabase`（`sqlite3.wasm` + Worker）を使う。最良モード（OPFS + 共有ワーカー）にはホスティング側で `Cross-Origin-Opener-Policy` / `Cross-Origin-Embedder-Policy` ヘッダが要る。GitHub Pages はヘッダを設定できないので Cloudflare Pages / Netlify などを使うか、性能の落ちるフォールバック（IndexedDB VFS）を受け入れる | ホスティングを選ぶ。FTS5 は wasm ビルドに含まれる |
| Isolate | Web に `Isolate.run` が無い。所得税法（附則除く）のパース 0.4 秒×ブラウザ係数が UI スレッドを塞ぐ | Web Worker でパースするか、条単位に `await` を挟んで分割する。dart2wasm ビルドで速度差は縮む |
| 永続性 | Safari は 7 日間使われないオリジンのストレージを消す。「一度開いた法令はオフラインで読める」（R4）を Safari では保証できない | Web 版では R4 をベストエフォートと明記。PWA としてホーム画面に追加すると緩和される |
| フォント | CanvasKit は日本語グリフを実行時に Google Fonts から取りに行く。オフライン時に条文が豆腐になる | Noto Sans JP のサブセットをアセットに同梱（数 MB）。初回ロードが重くなる |
| ライブラリ | `dart:io` 不可。`dio`・`xml`・`drift`・`go_router`・`unorm_dart` は Web 対応 | `lib/data` から `dart:io` を排除（スパイクの `EgovClient` は `dart:io` なので `dio` 版に置き換える） |
| 容量 | Phase 2 の全件先読み（数百 MB）は Safari の割当てを超える | Web では先読みを提供しない |

中継サーバや Web 固有のライブラリ制限で「できない」ものは無い。増えるのはホスティングの選定、Worker、フォント同梱、Safari の永続性の 4 点で、いずれもモバイル版の設計を変えずに後から足せる。**MVP はモバイルのみ**とし（Web で見るなら e-Gov 法令検索を直接使う人が多いという判断）、Web は Phase 3 以降に広告付きで公開する候補として残す。その場合は COOP/COEP を設定できる Cloudflare Pages 等を使う（GitHub Pages は不可）。

## 10. 品質・運用上の設計

- **失敗しても壊れない**: 本文の差し替えは法令単位のトランザクション。失敗した法令は `body_revision_id` が古いまま残り、次に開いたとき再試行
- **通信量**: 起動時は一覧の約 70KB（14 リクエスト）。法令を開くときにその法令の本文（gzip で 30KB〜700KB。改正附則込みなら最大 1.5MB）。先読み ON の改正日で数 MB
- **端末容量**: MVP は開いた法令のみで数十 MB 以内（`body_json` gzip は所得税法 0.4MB、地方税法 1.4MB）。キャッシュ上限（既定 500MB）を超えたら最終閲覧が古い法令から削除（先読み対象・ブックマークは除く）
- **巨大法令の体感**: Dart デスクトップで 所得税法（附則除く 3.7MB）decode 0.4 秒 + パース 0.02 秒、地方税法（6.2MB）0.34 + 0.06 秒、租税特別措置法全文（13.8MB）0.66 + 0.09 秒。中位 Android を 3〜5 倍遅いと見て、既定取得なら 1〜2 秒、全文で数秒。スケルトン表示、キャッシュがあれば先に古い本文を出してから差し替え
- **スキーマ移行**: drift のマイグレーション。`plain_text` の作り方を変える場合は `app_meta.parser_version` を上げ、ローカルの `body_json` から再生成
- **出典と免責**: 公共データ利用規約（PDL1.0、CC BY 4.0 互換）は出典明記を条件に商用利用（広告掲載を含む）を認めている。設定画面と閲覧画面フッタに「出典: e-Gov法令検索（https://laws.e-gov.go.jp/）」と取得日時。初回起動と設定画面に「デジタル庁・e-Gov の公式アプリではない」「表示内容の正確性・最新性を保証しない。正本は官報および e-Gov 法令検索で確認すること」を表示
- **API 仕様変更への耐性**: 一覧のフィールド欠落は該当項目を NULL にして続行。本文の XML スキーマ変更は未知タグを無視。`/law_data` が 4xx を返す法令は「取得不可」バッジで隔離し、他の法令に影響させない

## 11. セキュリティ設計（STRIDE）

### 前提

- 守るもの: (1) 表示する条文の**完全性**（改ざんされた条文を最新として見せないこと）、(2) アプリの**可用性**（オフライン時も含む）、(3) e-Gov API という**共有資源**への負荷、(4) ユーザーの閲覧履歴・ブックマーク（軽微な機微情報）
- 信頼境界: アプリ ⇄ e-Gov（HTTPS）、アプリ ⇄ OS・他アプリ（ディープリンク、共有、URL 起動）、アプリ ⇄ 端末内ストレージ
- 扱わないもの: 認証情報、決済、個人識別情報。アプリはアカウントを持たない

### 脅威と対策

| 区分 | 脅威 | 影響 | 対策 | 段階 |
|---|---|---|---|---|
| **S**poofing | 偽の e-Gov サーバ（MITM・DNS 詐称・不正な Wi-Fi）が改変した条文を返す | 誤った条文を最新として表示 | HTTPS 固定・平文 HTTP 禁止。証明書検証は OS の信頼ストアに任せ、`badCertificateCallback` などの緩和コードを禁止（CI で grep）。証明書ピン留めは政府ドメインの証明書更新で全ユーザーが止まるリスクが大きいので採らない | MVP |
| S | 偽装ディープリンク（`/law/…` を装った URL）で意図しない画面へ誘導 | 混乱・フィッシングの踏み台 | `lawId` は `^\d{3}[A-Z]{2}\d{10}$`、条番号は `^\d+(_\d+)*$` で検証。不一致は一覧へ戻す。ディープリンクのパラメータから外部 URL を組み立てない | MVP |
| S | アプリ自体のなりすまし（e-Gov 公式と誤認） | 信頼の誤用 | 「非公式」の明示（§10）。ストアの表示名・アイコンに政府機関のロゴを使わない | MVP |
| **T**ampering | 通信経路での改ざん | 誤った条文 | TLS。加えてヘッダの `Content-Length` と受信長の不一致・XML パース失敗時は破棄し、古いキャッシュを残す | MVP |
| T | 取得途中の中断による部分的な本文 | 欠けた条文を表示 | 法令単位のトランザクション（§4.5）。`body_revision_id` は成功時のみ更新 | MVP |
| T | 要求と違うリビジョンの本文が返る（サーバ側の不整合・キャッシュ事故） | 古い条文を最新として表示 | `/law_data` 封筒の `revision_info.law_revision_id` を要求 ID と照合し、不一致は破棄 | MVP |
| T | 端末内 DB の改ざん（root/jailbreak 端末） | 本人の端末内のみ | 受容する。他ユーザーへ波及しない。端末所有者以外は到達不能 | — |
| T | 不正な構造の XML/JSON（想定外のタグ・巨大な属性） | パーサ例外・表示崩れ | 未知タグは無視、例外は法令単位で隔離（§7-6）。フィクスチャによる回帰テスト | MVP |
| T | e-Gov 側のデータ誤り・訂正 | 誤った条文 | 検知不能。緩和として取得日時・リビジョン・施行日を本文と一緒に常時表示し、「e-Gov で開く」で正本へ誘導。訂正は `updated` で CORRECTED として取り直す | MVP |
| **R**epudiation | 「その時点で何を表示していたか」が後から分からない | ユーザーが根拠を示せない | `sync_runs` と `laws.body_synced_at` / `body_revision_id` を残し、閲覧画面に表示。共有・コピーの文面にリビジョンと取得日時を含める | MVP |
| **I**nformation disclosure | 閲覧履歴・ブックマークの漏えい | 業務上の関心事が推測される（軽微） | 端末内 SQLite のみ。サーバ送信なし。OS の暗号化ストレージ領域を使う。クラッシュレポート・分析 SDK は入れない（入れる場合は法令 ID のみで検索語を送らない） | MVP |
| I | 端末バックアップに DB が含まれる | 同上 | 受容する。機密性は低く、バックアップは OS の保護下にある | — |
| I | `User-Agent` やクエリから個人が識別される | なし | UA はアプリ名とバージョンのみ。端末 ID やユーザー ID を送らない | MVP |
| I | Web 版: ブラウザストレージが他サイトから読まれる | 同上 | 同一オリジンポリシーで分離される。第三者スクリプトを読み込まない | Web 時 |
| **D**enial of service | 巨大レスポンス（17MB 級 XML、gzip 爆弾）でメモリ枯渇 | クラッシュ | 既定は改正附則を除いて取得（最大 6.5MB）。展開後の受信上限 64MB、超えたら中止。全文取得はストリーム読み。パースは Isolate | MVP |
| D | XML 実体展開攻撃（billion laughs）・外部実体（XXE） | メモリ枯渇・ファイル読み出し | `xml` パッケージは DTD の実体を展開せず外部実体を解決しない。念のため `<!DOCTYPE` を含むレスポンスは拒否する | MVP |
| D | e-Gov API の停止・遅延 | 同期不可 | キャッシュで閲覧を継続。タイムアウト 30 秒。§4.6 のバックオフ | MVP |
| D | **自分が e-Gov への DoS 源になる**（普及時のアクセス集中、リトライ嵐） | 公共 API に迷惑・遮断される | 5 req/s・並列 3、10 分抑制、失敗時の間隔延長（§4.6）。全件先読みは Wi-Fi 推奨とユーザーの明示操作でのみ実行。CI で「起動時のリクエスト数 ≤ 20」を fake サーバで検証 | MVP |
| D | 端末容量の枯渇 | 端末全体の不調 | キャッシュ上限と LRU 削除（§10）。空き容量不足時は本文取得を中止して通知 | MVP |
| **E**levation of privilege | SQL インジェクション | DB 破壊・漏えい | drift のパラメータ化クエリのみ。文字列連結の SQL を lint で禁止。FTS5 の MATCH 式はトークンをダブルクォートで囲みエスケープ | MVP / Phase 2 |
| E | パストラバーサル（`revision_id` や `Fig@src` `./pict/…` をファイル名に使う箇所） | 任意ファイルの読み書き | `revision_id` は `^[0-9A-Z_]+$` で検証。添付ファイル（Phase 3）は `src` をそのままパスにせず、ハッシュ化したファイル名で保存 | MVP / Phase 3 |
| E | `/keyword` の `text` に含まれる HTML タグ（`<span>` など）の解釈 | 表示崩れ・将来 WebView を使えば XSS | WebView を使わない。タグは受信直後に除去してハイライト範囲だけを保持。表示は `Text`/`RichText` | Phase 3 |
| E | 外部 URL の起動（「e-Gov で開く」） | 任意スキームの起動 | `https://laws.e-gov.go.jp/` 配下に固定し、`law_id` は検証済みの値のみ埋め込む | MVP |
| E | 過剰な OS 権限 | 権限悪用の面積 | 要求する権限はネットワークのみ。ストレージ・連絡先・位置情報は要求しない | MVP |
| E | 依存パッケージの侵害（供給網） | 任意コード | 依存は少数（dio, drift, xml, riverpod, go_router, freezed）。`pubspec.lock` をコミットし、Dependabot と `dart pub outdated` を CI に入れる。`flutter pub get` はロックファイルに従う | MVP |

### 残留リスク

- e-Gov 側のデータ自体の誤りは検知できない。表示上の注記と正本への導線で緩和する
- root/jailbreak 端末での改ざんは受容する
- CORS 確認前は Web 版のリスク評価を保留する

## 12. テスト方針

| 対象 | 方法 |
|---|---|
| API デコード | `/laws`（`asof` あり・なし）、`/law_revisions`、`/law_data`（XML 封筒）の固定レスポンスでモデル変換を検証（実レスポンスは `spike/fixtures/real/`） |
| パーサ | 公式仕様の例示法令 XML と、実法令（Phase 0 で取得）をフィクスチャに。`OldNum`、枝番条、表、ルビ、附則、`ParagraphCaption` の各ケース（スパイクの `law_parser_test` を移植） |
| 同期ロジック | fake `EgovApiClient` + in-memory DB で NEW / REVISED / CORRECTED / 未施行あり / MISSING / 途中失敗→再開 / バックオフの段階 |
| 検索 | 法令名・略称・条番号ジャンプ・本文内検索（NFKC）。Phase 2 で FTS のエスケープ |
| セキュリティ | ディープリンク・`revision_id` の検証、`<!DOCTYPE` 拒否、受信上限、起動時リクエスト数の上限を fake サーバで検証 |
| UI | 検索→閲覧→条ジャンプの Widget テスト |
| 結合（手動） | 実 API に対する起動時同期の所要時間・通信量、主要税法の取得＋パース時間（Phase 0 のスパイク CLI を流用） |

## 13. 開発フェーズ

### Phase 0: スパイク

| # | 確認事項 | 結果（2026-09-23 実 API） |
|---|---|---|
| 1 | `category_cd` の値 | **確定**: `013` が「国税」252 件（`repeal_status=None`）、`036` が「地方財政」120 件、`023` は「国債」 |
| 2 | `/law_file` / `/law_data` の実レスポンス | **確定**: `/law_file` は非圧縮、`/law_data` は gzip。地方法人税法の両方を `spike/fixtures/real/` に保存し、同一の条レコードになることをテスト済み |
| 3 | 主要税法の本文サイズと Dart パース時間・メモリ | **確定**（下表）。中位 Android の実機計測は Phase 1 の最初に行う |
| 4 | e-Gov API の CORS | **確定**: `access-control-allow-origin: *`。Web を MVP に含める |
| 5 | `asof=2099-12-31` の一覧で `current_revision_info` が現行を返すこと | **確定**: 252 件すべて一致。ただし `current_revision_status` は 13 件で `PreviousEnforced` になるので `law_revision_id` だけを使う |
| 6 | `sqlite3_flutter_libs` の SQLite で FTS5 trigram が使えるか | Phase 2 の着手時に確認 |

Dart パース計測（Dart 3.13 VM、Linux x86_64、best of 2。`spike/bin/spike.dart bench`）:

| 法令 | 取得 | XML サイズ | 要素数 | XML → LawNode | LawNode → 条 | 条（本則/附則/別表） | plain_text 文字数 | body_json gz | RSS 増 |
|---|---|---|---|---|---|---|---|---|---|
| 所得税法 | 全文 | 15.68 MB | 201,027 | 1,733 ms | 124 ms | 302 / 1,074 / 6 | 1,179,864 | 1.14 MB | +157 MB |
| 所得税法 | 附則除く | 3.66 MB | 43,767 | 410 ms | 20 ms | 302 / 39 / 6 | 382,004 | 0.38 MB | — |
| 法人税法 | 全文 | 3.07 MB | 23,334 | 183 ms | 29 ms | 262 / 891 / 3 | 603,816 | 0.77 MB | — |
| 法人税法 | 附則除く | 1.76 MB | 12,099 | 68 ms | 5 ms | 262 / 21 / 3 | 349,231 | 0.33 MB | +17 MB |
| 租税特別措置法 | 全文 | 13.79 MB | 97,216 | 664 ms | 87 ms | 496 / 3,176 / 0 | 3,206,900 | 3.07 MB | +77 MB |
| 地方税法 | 附則除く | 6.19 MB | 46,907 | 343 ms | 55 ms | 1,348 / 217 / 0 | 1,314,486 | 1.36 MB | +74 MB |
| 地方法人税法 | 全文 | 0.27 MB | 2,254 | 10 ms | 0 ms | 58 / 51 / 0 | 51,224 | 0.07 MB | — |

所得税法の全文は要素数が突出しており（附則 1,074 件）、これが「既定では改正附則を除く」（v0.4 変更 2）の根拠。`/law_file/json` は同じ法令で XML の 2.5〜4.4 倍のサイズになる（調査メモ）。

### Phase 1: MVP

- プロジェクト雛形、CI、API クライアント、DB、パーサ（スパイクから移植）
- 起動時同期（§4）、同期バナー、「改正あり」「施行予定」バッジ
- 法令一覧、法令名検索（略称辞書）、条番号ジャンプ
- 法令閲覧: 最新本文の取得・キャッシュ、目次、条アンカー、本文内検索
- 改正履歴タブ、出典・免責表示、§11 の MVP 項目

### Phase 2: 横断全文検索

- 対象法令の本文先読み（進捗画面、Wi-Fi 推奨、明示操作）、FTS5 trigram、スニペット、フィルタ、本則/附則切替、ブックマーク

### Phase 3: 改正まわり・拡張

- 未施行改正の一覧（施行日順）、「今日施行された改正」バナー、時点指定（`asof`）の条文表示、`/keyword` によるスコープ外オンライン検索（`category_cd=013,036` で絞る）、改正前後の差分表示、添付ファイル（`/attachment`）の表示
- Web 版（§9 の制約表に従う。広告付きで公開するなら COOP/COEP を設定できるホスティング）

## 14. 未確定事項・確認したいこと

1. **対象範囲**: 「国税」分類 ＋ 地方税法まわり ＋ 明示 12 件でよいか。関税関係を含めてよいか
2. **Web の時期**: モバイル MVP の後、どの段階で Web（広告付き）を出すか
3. **過去条文の必要性**: 時点指定を v1 に入れるか（設計上は Phase 3）
4. **横断全文検索の必要性と時期**: Phase 2 で数百 MB 規模の先読みを入れるかどうか

決定済み（v0.5）: MVP はモバイルのみ。改正附則は既定で除き、タップで全文を取り直す（案 A）。廃止・失効法令は「参考」として一覧に載せる。
