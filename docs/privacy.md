# zeibun プライバシーポリシー

最終更新: 2026-10-03

zeibun（以下「本アプリ」）は、ouchinao が個人で開発・配布するアプリです。本アプリの利用にあたって取り扱う情報は次のとおりです。

## 収集する情報

本アプリは、利用者の個人情報を収集しません。

- アカウント登録はありません。氏名・メールアドレス・電話番号などの入力を求めません。
- 利用状況の分析（アクセス解析）やクラッシュレポートの送信は行いません。
- 広告 SDK を含みません。
- 端末の識別子、位置情報、連絡先、写真などにはアクセスしません。

## 通信先

本アプリが通信する相手は、デジタル庁が提供する e-Gov 法令検索の法令API（`laws.e-gov.go.jp`）のみです。法令の一覧と本文を取得するために、法令 ID と取得条件だけを送ります。検索した語や閲覧した法令が送られることはありません。通信はすべて HTTPS で行います。

## 端末内に保存する情報

次の情報を、利用者の端末内にのみ保存します。開発者を含む第三者に送信されることはありません。

- 取得した法令の一覧と本文（オフラインで閲覧するためのキャッシュ）
- 閲覧履歴（最近開いた法令）
- ブックマーク（法令・条）
- 設定（同期の設定、初回の確認を表示済みかどうか）

法令の本文・閲覧履歴・ブックマークは、端末のバックアップ（iCloud バックアップ、Google のバックアップ）には含めていません。本文が数百 MB になり得るためです。機種変更をしても引き継がれません。本アプリを削除すると、これらの情報はすべて端末から消えます。

## 外部サイトへのリンク

本アプリには、e-Gov 法令検索の該当ページと、このサイト（サポート・プライバシーポリシー）のページを開くリンクがあります。サポートのページからはお問い合わせフォーム（Google フォーム）と GitHub を開けます。リンク先での情報の取り扱いは、リンク先のポリシーに従います。

## お問い合わせ

本アプリに関するお問い合わせの方法は、[サポート](support)のページをご覧ください。

## 改定

本ポリシーを改定する場合は、このページを更新し、最終更新日を改めます。

---

<div lang="en" markdown="1">

## Privacy Policy (English summary)

Last updated: 2026-10-03. This is a summary of the Japanese policy above. If they differ, the Japanese version prevails.

- **No personal data is collected.** There is no account registration, analytics, crash reporting or advertising SDK. The app does not access device identifiers, location, contacts or photos.
- **Network access.** The app communicates only with the e-Gov Law API (`laws.e-gov.go.jp`) provided by the Digital Agency of Japan, sending only law IDs and query conditions over HTTPS. Search terms and the laws you read are not sent.
- **Data stored on the device only.** Downloaded law texts, recently opened laws, bookmarks and settings are stored only on your device and are never sent to the developer or third parties. Law texts, history and bookmarks are excluded from device backups. All of this data is deleted when you delete the app.
- **External links.** The app can open e-Gov Law Search and this site (support and privacy policy). The support page links to a contact form (Google Forms) and GitHub. Those sites are governed by their own policies.
- **Contact.** See the [support page](support).

</div>
