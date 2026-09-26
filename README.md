# zeibun

税制に関する法令（所得税法・法人税法・消費税法・租税特別措置法・地方税法 など）を、
e-Gov 法令API Version 2 から起動時に最新化し、端末内で検索・閲覧できる Flutter アプリ。
名前は「税文」（税の条文）から。

## ドキュメント

- [設計書](docs/design.md)
- [プライバシーポリシー](docs/privacy.md)、[リリース手順（iOS）](docs/release.md)、[ストア掲載文の下書き](store/)
- [e-Gov 法令API v2 調査メモ](docs/egov-law-api-v2.md)
- [公式 OpenAPI 仕様 lawapi-v2.yaml v2.1.139](docs/lawapi-v2.yaml)
- [Flutter アプリ本体](app/README.md)
- [コアパッケージ zeibun_core（純 Dart）](packages/zeibun_core/)
- [Phase 0 スパイク（純 Dart）](spike/README.md)

## 開発

```sh
(cd packages/zeibun_core && dart pub get && dart test)
(cd app && flutter pub get && dart run build_runner build -d && flutter analyze && flutter test)
```

## 出典

法令データは [e-Gov法令検索](https://laws.e-gov.go.jp/)（デジタル庁）の法令APIから取得しています。
本アプリはデジタル庁・e-Gov の公式アプリではありません。

## ライセンス

権利留保（All rights reserved）。ソースは閲覧・参照のために公開していますが、
複製・改変・再配布・ストア公開・商用利用はできません。「zeibun」の名称・アイコン・
ストア掲載物も同様です。詳細は [LICENSE](LICENSE)。
