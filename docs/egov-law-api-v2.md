# e-Gov 法令API Version 2 調査メモ

zeibun が利用する e-Gov 法令API v2 について、設計判断の根拠となる事実をまとめる。
「仕様」は公式 OpenAPI 仕様 [`lawapi-v2.yaml` v2.1.139](./lawapi-v2.yaml)（本リポジトリに同梱）の記載、「実測」は 2026-09-23 に本プロジェクトのスパイク（`spike/`）で実 API に対して計測した値、または公開されている実測記録（末尾の出典）から裏取りした値。

### 2026-09-23 の実測で確定した要点

| 項目 | 結果 |
|---|---|
| `category_cd=013` | 「国税」を返す。`repeal_status=None` で 252 件、指定なしだと廃止・失効を含め 287 件（LossOfEffectiveness 31 / Repeal 3 / Expire 1）。`023` は「国債」 |
| `category_cd=036` | 「地方財政」120 件（`repeal_status=None`）。題名に「税」を含むもの 46 件 |
| `asof=2099-12-31` | 全行に `current_revision_info` が付き、その `law_revision_id` は `asof` なしの一覧の現行と 252 件すべて一致。`revision_info` 側が現行と異なる（= 未施行改正あり）法令は 55 件。**ただし `current_revision_info.current_revision_status` は 13 件で `PreviousEnforced` になる**（asof 基準で評価されている模様）ので、判定には `law_revision_id` の比較だけを使う |
| `law_id=<ID>` | 1 件だけ返る（`total_count: 1`）。明示指定は 1 件 1 リクエスト |
| CORS | `/laws` に `Origin` ヘッダを付けると **`access-control-allow-origin: *`** が返る（CloudFront 配信）。Flutter Web から直接呼べる |
| `/law_file` の圧縮 | **gzip されない**（`content-type: application/octet-stream`、`content-disposition: attachment`、`content-encoding` なし）。所得税法 XML は 16.4MB がそのまま流れる |
| `/law_data` の圧縮 | **gzip が効く**。同じ所得税法 XML が wire 672KB（約 24 分の 1）。本文取得はこちらを使う |
| 本文サイズ | 調査メモ v0.1 の目安（数百 KB〜十数 MB）より大きい。下記「本文」の表を参照 |
| 一覧の通信量 | `013` asof 付き 39.5KB / `036` 18KB（gzip）。起動時同期の一覧は合計 60KB 程度 + 明示 ID 分 12 × 0.6KB |
| 仕様書の版 | 2.1.139（ミラーで読んだ 2.1.138 からの差分は `/law_data` の `json_format=light` 追加と `order` の説明文のみ） |

- ベース URL: `https://laws.e-gov.go.jp/api/2`
- 認証: 不要（API キーなし、HTTPS）
- 公式仕様: `https://laws.e-gov.go.jp/api/2/swagger-ui/`（OpenAPI 3.0.3、`lawapi-v2.yaml`）。Redoc: `https://laws.e-gov.go.jp/api/2/redoc/`
- 利用条件: デジタル庁の公共データ利用規約（PDL1.0）。**出典（e-Gov法令検索）の明記が必要**
- 公開日: v2 は 2025-03-14。v1（`elaws.e-gov.go.jp/api/1`）も当面利用可、終了日は未公表
- **試行版の注意**（仕様書の冒頭）: 「法令本文取得APIで返却されるJSON形式のデータ」「法令本文ファイル取得APIで取得できるJSON形式のデータ」「キーワード検索APIで `law_num` を含むパラメータ指定時のレスポンス」は試行版で仕様変更が発生し得る。**XML 形式は対象外（安定）**

## エンドポイント（仕様）

| エンドポイント | 用途 | 主なパラメータ |
|---|---|---|
| `GET /laws` | 法令一覧 | `law_id`（部分一致）, `law_num`（部分一致）, `law_num_era/num/type/year`, `law_title`（法令名または略称の部分一致）, `law_title_kana`, `law_type`（複数可）, `amendment_law_id`, `asof`, `category_cd`（複数可）, `mission`, `omit_current_revision_info`, `promulgation_date_from/to`, `repeal_status`（複数可）, `limit`（既定 100）, `offset`, `order`, `response_format` |
| `GET /law_revisions/{law_id_or_num}` | 1 法令の改正履歴（新しい順） | `law_title`（`/…/` で正規表現）, `amendment_date_from/to`, `amendment_law_id/num/title`, `amendment_promulgate_date_from/to`, `amendment_type`, `category_cd`, `current_revision_status`, `mission`, `remain_in_force`, `repeal_date_from/to`, `repeal_status`, `updated_from/to`, `response_format` |
| `GET /law_data/{law_id_or_num_or_revision_id}` | 本文＋メタ（`attached_files_info`, `law_info`, `revision_info`, `law_full_text`） | `law_full_text_format`（json/xml）, `json_format`（`full` / `light`、2.1.139 で追加）, `asof`（履歴 ID 指定時は無視）, `elm`, `omit_amendment_suppl_provision`, `include_attached_file_content`, `response_format` |
| `GET /law_file/{file_type}/{law_id_or_num_or_revision_id}` | 本文ファイル | `file_type` = `xml` / `json` / `html` / `rtf` / `docx`。クエリ `asof` |
| `GET /keyword` | 全法令の全文検索 | `keyword`（必須。`*` `?` ワイルドカード、AND/OR/NOT）, `law_num*`, `law_type`, `asof`, `category_cd`, `promulgation_date_from/to`, `limit`（既定 100・上限 1000、`sentences` の `position` 数の総和）, `offset`, `order`, `sentences_limit`, `sentence_text_size`（既定 100）, `highlight_tag`（既定 `span`）, `response_format` |
| `GET /attachment/{law_revision_id}` | 添付ファイル（jpg / pdf） | `src`（`Fig@src` の値。省略時は zip 一括） |

- 共通: `response_format` 未指定時は `Accept` ヘッダで判断、判断できなければ JSON
- エラーは `{code, message}`。例: `400004 日付（asof等）が誤っています。`、`404003 指定のパラメータで取得できる添付ファイルは存在しません。`、`500001 サーバ内処理で異常が発生しました。`
- `/law_data` で `response_format` と `law_full_text_format` が異なる場合、`law_full_text` は **Base64** で返る

## `GET /laws`

### 仕様の要点

- `laws[]` の各行は `law_info`（履歴に依存しない）、`revision_info`（`asof` 時点で最新の履歴）、`current_revision_info`（`asof` に関係なく現時点の現行履歴。`omit_current_revision_info=true` で省略）
- `asof=YYYY-MM-DD` は「指定時点以前で最新の改正履歴」。未来日を指定すると未施行の履歴が `revision_info` に入る → **`asof=2099-12-31` の 1 回で「現行」（`current_revision_info`）と「最後に登録された未施行」（`revision_info`）が同時に取れる**（2026-09-23 に 252 件で確認。設計書 §4.2）。複数の未施行改正がある法令では `revision_info` は最も遠い施行日のもの（例: 租税特別措置法は 2030-01-01 施行分）になるので、「次に施行される改正」の日付は `/law_revisions` で取る
- レスポンスは `total_count`（条件一致の全件数）, `count`, `next_offset`（末尾なら null）, `laws[]`
- `law_id` は**部分一致で単一指定**。複数 ID をカンマで並べる指定は無い
- `order` は `+law_info.law_id,-revision_info.amendment_promulgate_date` の形式。既定 `law_info.law_id`
- 改正区分の見分け方（仕様書冒頭）: 新規制定 = `amendment_type=1` かつ `mission=New`、一部改正 = `mission=Partial`、被改正法 = `amendment_type=3` かつ `mission=New`、廃止 = `amendment_type=8` または `repeal_status` が `Repeal`/`Expire`/`LossOfEffectiveness`

### 列挙値（仕様）

| 項目 | 値 |
|---|---|
| `law_type` / `law_num_type` | `Constitution`, `Act`, `CabinetOrder`, `ImperialOrder`, `MinisterialOrdinance`, `Rule`, `Misc` |
| `law_num_era` | `Meiji`, `Taisho`, `Showa`, `Heisei`, `Reiwa` |
| `repeal_status` | `None`, `Repeal`, `Expire`, `Suspend`, `LossOfEffectiveness`（実測分布 None 9010 / Repeal 414 / LossOfEffectiveness 105 / Expire 38） |
| `current_revision_status` | `CurrentEnforced`, `UnEnforced`, `PreviousEnforced`, `Repeal` |
| `amendment_type` | `1` 新規, `3` 被改正, `8` 廃止 |
| `mission` | `New`, `Partial` |

### `category_cd`（事項別分類コード、仕様）

v0.1 の推定（国税=023 など）は誤りだった。公式表は次のとおり。

| コード | 名称 | コード | 名称 | コード | 名称 | コード | 名称 | コード | 名称 |
|---|---|---|---|---|---|---|---|---|---|
| 001 | 憲法 | 011 | 行政組織 | 021 | 行政手続 | 031 | 地方自治 | 041 | 司法 |
| 002 | 刑事 | 012 | 消防 | 022 | 土地 | 032 | 道路 | 042 | 災害対策 |
| 003 | 財務通則 | **013** | **国税** | 023 | 国債 | 033 | 文化 | 043 | 農業 |
| 004 | 水産業 | 014 | 工業 | 024 | 金融・保険 | 034 | 陸運 | 044 | 航空 |
| 005 | 観光 | 015 | 電気通信 | 025 | 環境保全 | 035 | 社会福祉 | 045 | 防衛 |
| 006 | 国会 | 016 | 国家公務員 | 026 | 統計 | **036** | **地方財政** | 046 | 民事 |
| 007 | 警察 | 017 | 国土開発 | 027 | 都市計画 | 037 | 河川 | 047 | 建築・住宅 |
| 008 | 国有財産 | 018 | 事業 | 028 | 教育 | 038 | 産業通則 | 048 | 林業 |
| 009 | 鉱業 | 019 | 商業 | 029 | 外国為替・貿易 | 039 | 海運 | 049 | 貨物運送 |
| 010 | 郵務 | 020 | 労働 | 030 | 厚生 | 040 | 社会保険 | 050 | 外事 |

`revision_info.category` にはこの名称が入る。XML 一括ダウンロード（`bulkdownload?file_section=2&category_cd=13`）ではゼロ埋め無しの数値を使う。

### レスポンス構造（仕様・実測）

```jsonc
{
  "total_count": 252, "count": 252, "next_offset": null,
  "laws": [{
    "law_info": { "law_id": "340AC0000000034", "law_num": "昭和四十年法律第三十四号",
                  "law_num_era": "Showa", "law_num_year": 40, "law_num_type": "Act",
                  "law_num_num": "034", "law_type": "Act", "promulgation_date": "1965-03-31" },
    "revision_info": {                  // asof 時点で最新の履歴
      "law_revision_id": "340AC0000000034_20260723_508AC0000000064",
      "law_type": "Act", "law_title": "法人税法", "law_title_kana": "ほうじんぜいほう",
      "abbrev": null,                   // 複数ある場合はカンマ区切り（例: 国旗国歌法,日の丸君が代法）
      "category": "国税",
      "updated": "2026-07-23T10:12:00+09:00",   // 正誤等によるデータ更新日時
      "amendment_promulgate_date": "2026-07-23",
      "amendment_enforcement_date": "2026-07-23",
      "amendment_enforcement_comment": null,
      "amendment_scheduled_enforcement_date": null,
      "amendment_law_id": "508AC0000000064",
      "amendment_law_title": "金融商品取引法及び資金決済に関する法律の一部を改正する法律",
      "amendment_law_title_kana": null,
      "amendment_law_num": "令和八年法律第六十四号",
      "amendment_type": "3", "repeal_status": "None", "repeal_date": null,
      "remain_in_force": false, "mission": "New",
      "current_revision_status": "CurrentEnforced"
    },
    "current_revision_info": { /* revision_info と同じ形。現時点の現行 */ }
  }]
}
```

- `law_revision_id` の形式は `<law_id>_<施行日YYYYMMDD>_<改正法令ID>`。制定時は改正法令 ID が `000000000000000`
- `/laws`（`asof` なし）は現行施行リビジョンしか返さず、未施行改正の登録は `updated` に現れない

## `GET /law_revisions/{law_id}`

- `law_info` と `revisions[]`（`revision_info` と同じ形、新しい順）。1 リクエスト約 10KB、0.1 秒（実測）
- `current_revision_status=UnEnforced` または `amendment_enforcement_date > today` が未施行改正
- 履歴は 2016 年頃以降のものだけが提供される（実測）

## 本文: `GET /law_data/{id}` と `GET /law_file/xml/{revision_id}`

- `/law_file/xml` は `Law` 要素だけの XML を `Content-Disposition: attachment`、`application/octet-stream` で返す。**gzip されない**。`/law_file/json` は同じ構造の `{tag, attr, children}`（試行版）で、インデント付きのため XML の 2.5〜4.4 倍のサイズ
- `/law_data` は `law_data_response > (attached_files_info, law_info, revision_info, law_full_text > Law)` の封筒付き。**gzip が効く**（約 24 分の 1）。`elm`（例 `MainProvision-Article_1`）で一部だけ取得可。`omit_amendment_suppl_provision=true` で改正法令の附則を除ける（所得税法 16.4MB → 3.8MB、租税特別措置法 14.5MB → 6.4MB）。`include_attached_file_content=true` で添付ファイルの zip（Base64）が付く
- `json_format=light`（2.1.139）は「パースに最適化された簡易版」だが、属性は `AmendLawNum`・`Extract`・`Paragraph@Num` しか残らず（`Article@Num` が落ちる）、ルビ等のインライン要素はテキストにタグ文字列として埋め込まれる。本アプリの正本には使わない
- 廃止・失効法令でも 200 で本文が返る（実測）
- 仕様書の注意: 本文が大きい場合 Swagger UI ではエラーになることがある

### 主要税法の本文サイズ（2026-09-23 実測、現行リビジョン）

| 法令 | `/law_file/xml` raw | `/law_file/json` raw | `/law_data` xml gzip wire | 同 `omit_amendment_suppl_provision` raw / wire |
|---|---|---|---|---|
| 所得税法 | 16.44 MB | 72.50 MB | 672 KB | 3.84 MB / 222 KB |
| 所得税法施行令 | 3.64 MB | 10.37 MB | | |
| 法人税法 | 3.22 MB | 9.10 MB | 310 KB | 1.84 MB / 183 KB |
| 法人税法施行令 | 6.06 MB | 17.30 MB | | |
| 消費税法 | 1.28 MB | 3.53 MB | | |
| 相続税法 | 0.83 MB | 2.26 MB | | |
| 租税特別措置法 | 14.45 MB | 36.06 MB | 1.46 MB | 6.36 MB / 667 KB |
| 租税特別措置法施行令 | 13.84 MB | 36.87 MB | | |
| 国税通則法 | 0.93 MB | 2.85 MB | | |
| 地方税法 | 12.15 MB | 34.17 MB | | 6.49 MB / 674 KB |
| 地方法人税法 | 0.28 MB | 0.80 MB | 28 KB | |

`/law_file` の非圧縮ダウンロードはデータセンターからでも 1〜2.6 秒。モバイル回線では所得税法クラスで数十秒になり得るので、本文取得は `/law_data`（gzip）を使う。

### XML と JSON のパース比較（Dart 3.13 VM、Linux x86_64、`spike bench`、best of 2）

同じ法令の XML と JSON から作った `LawNode` ツリーは要素数・条数・`plain_text` の文字数まで一致した（`/law_file/xml` と `/law_data` の XML も同様）。

| 法令 | 形式 | サイズ | 要素数 | → LawNode | → 条レコード | 条（本則/附則/別表） |
|---|---|---|---|---|---|---|
| 所得税法 | xml | 15.68 MB | 200,993 | 2,235 ms | 112 ms | 302 / 1,074 / 6 |
| 所得税法 | json | 69.14 MB | 200,993 | 1,682 ms | 150 ms | 同上 |
| 租税特別措置法 | xml | 13.78 MB | 97,182 | 917 ms | 109 ms | 496 / 3,176 / 0 |
| 租税特別措置法 | json | 34.39 MB | 97,182 | 798 ms | 71 ms | 同上 |
| 地方税法 | xml | 11.59 MB | 95,933 | 781 ms | 130 ms | 1,348 / 2,822 / 0 |
| 地方税法 | json | 32.59 MB | 95,933 | 556 ms | 67 ms | 同上 |
| 法人税法 | xml | 3.07 MB | 23,300 | 159 ms | 11 ms | 262 / 891 / 3 |
| 法人税法 | json | 8.68 MB | 23,300 | 122 ms | 10 ms | 同上 |
| 消費税法 | xml | 1.22 MB | 10,281 | 54 ms | 3 ms | 85 / 434 / 5 |
| 国税通則法 | xml | 0.89 MB | 8,248 | 41 ms | 4 ms | 194 / 235 / 0 |
| 地方法人税法 | xml | 0.27 MB | 2,220 | 11 ms | 1 ms | 58 / 51 / 0 |

JSON の `json.decode` は XML の DOM パースより 2〜3 割速いが、転送量が 2.5〜4.4 倍で `/law_file` は非圧縮。gzip の効く `/law_data` の XML を採用する判断は変わらない。

### 本文のノード形式

```jsonc
{ "tag": "Article", "attr": { "Num": "22" }, "children": [ { "tag": "ArticleCaption", ... }, "文字列", ... ] }
```

- 属性が無い要素の `attr` は `{}` または `""`（仕様書の例に両方ある）
- 主要タグ: `Law > LawNum, LawBody > (LawTitle | EnactStatement | Preamble | TOC | MainProvision | SupplProvision | AppdxTable | AppdxNote | AppdxStyle | AppdxFormat | Appdx | AppdxFig)`
  - 構造: `Part`, `Chapter`, `Section`, `Subsection`, `Division`, `Article`, `Paragraph`, `Item`, `Subitem1..10`, `List`, `Sublist1..3`
  - 見出し・番号: `ArticleTitle`, `ArticleCaption`, `ParagraphCaption`, `ParagraphNum`, `ItemTitle`, `ChapterTitle`, `SupplProvisionLabel`, `AppdxTableTitle`, `RelatedArticleNum`
  - 文: `ParagraphSentence`, `ItemSentence`, `ListSentence`, `Column`, `Sentence`
  - その他: `TableStruct/Table/TableRow/TableColumn`, `Ruby/Rt`（`Rt` は本文から除外）, `Remarks`, `FigStruct/Fig@src`
  - 属性例: `Article@Num="1"`, `@Delete`, `@Hide`, `Paragraph@OldStyle`, `Paragraph@OldNum`, `Sentence@WritingMode`, `SupplProvision@AmendLawNum`, `@Extract`
- `Paragraph` の `OldNum="true"` は `ParagraphNum` が空。`Num` 属性から項番号を補う

## `GET /keyword`

- レスポンス: `total_count`, `sentence_count`, `next_offset`, `items[]{law_info, revision_info, sentences[]{position, text}}`
- `position` は `elm` 形式（例 `MainProvision-Article_21-Paragraph_3`、`amendsupplprovision`）
- `text` はヒット箇所を `<span>`（`highlight_tag` で変更可）で囲んだ HTML。表示時にタグを除去すること
- `law_id` での絞り込みは無い。`category_cd` で絞れるので、税制の範囲は `013,036` で近似できる

## 更新検知に関する実測事実

| 項目 | 事実 |
|---|---|
| HTTP キャッシュ | ETag / Last-Modified なし。`cache-control: max-age=0, no-cache, no-store`。If-Modified-Since は 200 |
| レート制限 | ヘッダなし。20 連続リクエストで全 200（2.9 秒）。既存実装は 5 req/s 程度に自主制限 |
| 更新タイミング | 日中随時（08 時台〜22 時台に観測）。土日はほぼ更新なし |
| 更新頻度 | 現行本文の更新は直近 7 日で約 50 件、30 日で約 370 件（全法令、再登録を含む） |
| `asof` の未来日 | `asof=2099-12-31` は 200 で総件数同じ。現在と `revision_id` が異なる法令は 842 件（未施行改正を持つ法令の一覧として使える） |
| ページング | `limit=5000` は受理。`offset` が総件数を超えると `{"total_count":0,"count":0,"laws":[]}` |
| gzip | 1000 件 1.96MB → 137KB |
| CORS | `Origin` ヘッダ付きの `/laws` に `access-control-allow-origin: *` が返る（2026-09-23 実測）。Flutter Web から直接呼べる |
| `/law_file` と `/law_data` の圧縮 | `/law_file` は非圧縮、`/law_data` は gzip（2026-09-23 実測） |

## 税制の対象範囲（実カタログ 2026-09、`spike/fixtures/catalog_tax_snapshot.json`）

| 分類 | 法令数 | 備考 |
|---|---|---|
| 国税（013） | 252（法律 62 / 政令 97 / 省令 93） | 所得税法、法人税法、消費税法、相続税法、租税特別措置法、国税通則法、国税徴収法、印紙税法、登録免許税法、税理士法、地方法人税法、関税法 など。すべて現行。58 件に未施行改正あり |
| 地方財政（036） | 120（うち題名に「税」を含む 46） | 地方税法・同施行令・同施行規則、地方交付税法、譲与税各法 |
| 財務通則（003） | 297（うち「税」を含む 15） | 国税収納金整理資金に関する法律、防衛特別法人税に関する政令 など |
| その他 | 「税」を含む題名が 55 件 | 国税不服審判所組織令（行政組織）、租税条約実施特例関連 など |

API の `abbrev` に入っている税法の略称: 租特法・租特法施行令・租特法施行規則、輸徴法、滞調法、耐用年数省令、電子帳簿保存法、国外送金法、震災特例法、租税条約等実施特例法、交付税法 など（所得税法・法人税法・消費税法・地方税法には無い。アプリ側の略称辞書で補う）。

改正履歴の多さ: 租税特別措置法 過去 159 / 未施行 16、地方税法 過去 197 / 未施行 32、法人税法 過去 58 / 未施行 10、登録免許税法 過去 148 / 未施行 18。

## 出典

- 法令API Version 2 OpenAPI 仕様 `lawapi-v2.yaml` v2.1.139（https://laws.e-gov.go.jp/api/2/swagger-ui/lawapi-v2.yaml 。本リポジトリでは `docs/lawapi-v2.yaml` に同梱）
- 本プロジェクトのスパイクによる実測（2026-09-23）: `spike/fixtures/real/` と設計書 §13
- デジタル庁「法令API Version2リリースのお知らせ」(2025-03-14)
- okamyuji/egov-law-sync `README.md`, `docs/measurements.md`（2026-09-11 の HTTP 実測記録）: https://github.com/okamyuji/egov-law-sync
- yno9/legalize-jp-fetcher `src/datasource/EGovDataSource.ts`, `src/parseJSON.ts`, `data/laws.json`（レスポンス型と実カタログ）: https://github.com/yno9/legalize-jp-fetcher
- ngs/go-jplaw-api-v2（`lawapi-v2.yaml` のミラー）: https://github.com/ngs/go-jplaw-api-v2
- e-Gov 法令データ ドキュメンテーション: https://laws.e-gov.go.jp/docs/
