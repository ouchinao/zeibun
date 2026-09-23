# e-Gov 法令API Version 2 調査メモ

zeibun が利用する e-Gov 法令API v2 について、設計判断の根拠となる事実をまとめる。
「確認済」は公開されている利用実装・実測記録（下記の出典）から裏取りできたもの、「要確認」は公式仕様 (`lawapi-v2.yaml`) を実機で確認してから確定させるもの。

- ベースURL: `https://laws.e-gov.go.jp/api/2`
- 認証: 不要（APIキーなし、HTTPS）
- 公式仕様: `https://laws.e-gov.go.jp/api/2/swagger-ui/`（OpenAPI: `lawapi-v2.yaml`、約100KB）
- 利用条件: デジタル庁の公共データ利用規約 (PDL1.0) に準拠。**出典（e-Gov法令検索）の明記が必要**

## エンドポイント

| エンドポイント | 用途 | 状態 |
|---|---|---|
| `GET /laws` | 法令一覧（メタデータ）。絞り込み・ページング可 | 確認済 |
| `GET /law_revisions/{law_id}` | 1法令の改正履歴（過去・現行・未施行） | 確認済 |
| `GET /law_data/{law_id or law_num or law_revision_id}` | 法令本文＋メタデータ（JSON/XML） | 確認済（パラメータは要確認） |
| `GET /law_file/{file_type}/{law_revision_id}` | 本文ファイル。`json` は `Law` 要素のツリーがそのまま返る | 確認済（`json`,`xml`） |
| `GET /keyword` | 全法令に対するサーバ側の全文検索（ハイライト付き） | 要確認 |
| `GET /attachment/{law_revision_id}` | 別表等の添付ファイル | 要確認 |

## `GET /laws`

### クエリパラメータ（仕様書に記載のもの）

`law_id`, `law_num`（および `law_num_era` 等の分割指定）, `law_title`（法令名または略称の**部分一致**）, `law_type`, `asof`, `category_cd`, `promulgation_date_from` / `promulgation_date_to`, `repeal_status`, `limit`, `offset`, `order`, `response_format`

- `updated_from` のような**差分取得パラメータは存在しない**。未知のパラメータは無視され、全件が返る
- `limit=5000` は受理される。全法令（約9,570件）は2リクエストで取れる。gzip 圧縮で 1,000件 1.96MB → 137KB
- `order` の既定は `law_info.law_id`。`order=law_id` は400。正しい形は `+law_info.law_id`
- `total_count` は1ページ目に総件数、終端（`count=0`）ページでは `0`
- `asof=YYYY-MM-DD` で「その日時点で施行されているリビジョン」の一覧になる（未来日も指定可）
- `law_type` の値: `Constitution`, `Act`, `CabinetOrder`, `ImperialOrder`, `MinisterialOrdinance`, `Rule`（複合値 `Act,CabinetOrder` 等も存在）
- `repeal_status` の値: `None`, `Repeal`, `Expire`, `LossOfEffectiveness`（実測分布 None 9010 / Repeal 414 / LossOfEffectiveness 105 / Expire 38）
- `category_cd`: 事項別分類コード（3桁ゼロ埋め、001〜050）。**国税=023、財務通則=021、地方財政=008 と推定。要実機確認。** コードが合わなくても `revision_info.category`（分類名の文字列）でクライアント側フィルタが可能

### レスポンス構造（確認済）

```jsonc
{
  "total_count": 9567,
  "count": 1000,
  "laws": [
    {
      "law_info": {
        "law_id": "340AC0000000034",
        "law_num": "昭和四十年法律第三十四号",
        "law_num_era": "Showa",          // Meiji / Taisho / Showa / Heisei / Reiwa
        "law_num_year": 40,
        "law_num_type": "Act",
        "law_num_num": "34",
        "law_type": "Act",
        "promulgation_date": "1965-03-31"
      },
      "revision_info": {                  // 現行施行リビジョンの情報。null の行もある
        "law_revision_id": "340AC0000000034_20260723_508AC0000000064",
        "law_type": "Act",
        "law_title": "法人税法",
        "law_title_kana": "ほうじんぜいほう",
        "abbrev": null,
        "category": "国税",               // 事項別分類名
        "updated": "2026-07-23T10:12:00+09:00",   // このリビジョンのデータ更新時刻
        "amendment_promulgate_date": "2026-07-23",
        "amendment_enforcement_date": "2026-07-23",
        "amendment_enforcement_comment": null,
        "amendment_scheduled_enforcement_date": null,
        "amendment_law_id": "508AC0000000064",
        "amendment_law_title": "金融商品取引法及び資金決済に関する法律の一部を改正する法律",
        "amendment_law_title_kana": null,
        "amendment_law_num": "令和八年法律第六十四号",
        "amendment_type": "3",
        "repeal_status": "None",
        "repeal_date": null,
        "remain_in_force": false,
        "mission": "New",
        "current_revision_status": "CurrentEnforced"   // CurrentEnforced / PreviousEnforced / UnEnforced / Repeal
      }
    }
  ]
}
```

- `law_revision_id` の形式は `<law_id>_<施行日YYYYMMDD>_<改正法令ID>`
- `/laws` は**現行施行リビジョンしか返さない**。未施行改正の登録は `/laws` の `updated` に現れないので `/law_revisions` で拾う

## `GET /law_revisions/{law_id}`

```jsonc
{
  "law_info": { "law_id": "340AC0000000034", ... },
  "revisions": [
    {
      "law_revision_id": "340AC0000000034_20261001_508AC0000000012",
      "law_title": "法人税法",
      "updated": "2026-04-01T09:00:00+09:00",
      "amendment_promulgate_date": "2026-03-31",
      "amendment_enforcement_date": "2026-10-01",
      "amendment_scheduled_enforcement_date": null,
      "amendment_enforcement_comment": null,
      "amendment_law_id": "508AC0000000012",
      "amendment_law_num": "令和八年法律第十二号",
      "amendment_law_title": "所得税法等の一部を改正する法律",
      "amendment_law_title_kana": null,
      "amendment_type": "3",
      "repeal_status": "None",
      "current_revision_status": "UnEnforced"
    }
  ]
}
```

- 1リクエスト約10KB前後、0.1秒程度
- `amendment_enforcement_date > today` のものが未施行改正（税制改正の「施行予定」表示に使う）

## `GET /law_data/{id}` と `GET /law_file/json/{law_revision_id}`

- `/law_data` は `law_info`, `revision_info`, `law_full_text`, `attached_files_info` を含む（要確認）。`asof`、`elm`（`MainProvision-Article_1` のような要素指定）、`law_full_text_format` のパラメータがあると認識している（要確認）
- `/law_file/json/{revision_id}` は `Law` 要素のツリーだけを返す（確認済）
- サイズ目安: 労働基準法 約400KB / 0.2秒。全法令中の最大XMLは約17MB/件（租税特別措置法クラス）
- 廃止・失効法令でも 200 で本文が返る

### 本文JSONのノード形式（確認済）

```jsonc
{ "tag": "Article", "attr": { "Num": "22" }, "children": [ { "tag": "ArticleCaption", ... }, "文字列", ... ] }
```

- 子要素は `LawNode | string` の配列
- 主要タグ: `Law > LawBody > (TOC | MainProvision | SupplProvision | AppdxTable ...)`
  - 構造: `Part`, `Chapter`, `Section`, `Subsection`, `Division`, `Article`, `Paragraph`, `Item`, `Subitem1..10`
  - 見出し・番号: `ArticleTitle`（第二十二条）, `ArticleCaption`（（各事業年度の所得の金額の計算の通則））, `ParagraphNum`, `ItemTitle`, `ChapterTitle` など
  - 文: `ParagraphSentence`, `ItemSentence`, `Column`, `Sentence`
  - その他: `TableStruct/Table/TableRow/TableColumn`, `Ruby/Rt`（ルビ。`Rt` は本文から除外）, `Remarks`, `FigStruct`
- `Paragraph` の `OldNum="true"` は `ParagraphNum` が空。`attr.Num` から項番号を補う

## 更新検知に関する実測事実

| 項目 | 事実 |
|---|---|
| HTTPキャッシュ | ETag / Last-Modified なし。`cache-control: max-age=0, no-cache, no-store` |
| レート制限 | ヘッダなし。20連続リクエストで全200（2.9秒）。既存実装は 5 req/s 程度に自主制限している |
| 更新タイミング | 日中随時（08時台〜22時台に観測） |
| 更新頻度 | 現行本文の更新は直近7日で約50件、30日で約370件（全法令）。土日はほぼ更新なし |
| 検知方法 | `/laws` の `revision_info.law_revision_id` / `updated` を前回値と比較するしかない |

## 税制の対象範囲（実データ 2026-09 時点のカタログから集計）

| 分類 | 法令数 | 備考 |
|---|---|---|
| 国税 | 252（法律62 / 政令97 / 省令93） | 所得税法、法人税法、消費税法、相続税法、租税特別措置法、国税通則法、国税徴収法、印紙税法、登録免許税法、税理士法、地方法人税法、関税法 など。すべて現行（廃止なし）。うち58件に未施行改正あり |
| 地方財政 | 120（うち題名に「税」を含む46） | **地方税法・地方税法施行令・施行規則はここ**。地方交付税法、譲与税各法も |
| 財務通則 | 297（うち「税」を含む15） | 国税収納金整理資金に関する法律 など |
| その他 | 「税」を含む題名が55件 | 国税不服審判所組織令（行政組織）、租税条約実施特例関連 など |

改正履歴の多さ（税法は改正が多い）: 租税特別措置法 過去159 / 未施行16、地方税法 過去197 / 未施行32、法人税法 過去58 / 未施行10、登録免許税法 過去148 / 未施行18。

## 出典

- 法令API Version 2 Swagger UI: https://laws.e-gov.go.jp/api/2/swagger-ui/
- デジタル庁「法令API Version2リリースのお知らせ」(2025-03-14)
- okamyuji/egov-law-sync `docs/measurements.md`（2026-09-11 の HTTP 実測記録）: https://github.com/okamyuji/egov-law-sync
- yno9/legalize-jp-fetcher `src/datasource/EGovDataSource.ts`, `src/parseJSON.ts`, `data/laws.json`（レスポンス型と実カタログ）: https://github.com/yno9/legalize-jp-fetcher
- e-Gov 法令データ ドキュメンテーション「法令種別と法令ID」: https://laws.e-gov.go.jp/docs/law-data-basic/607318a-lawtypes-and-lawid/
