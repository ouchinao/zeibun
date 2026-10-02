# App Review への補足

設計書 §13 Phase R の R9。App Store Connect の「App Review に関する情報 > メモ」に、下の英文をそのまま貼る。Apple から英語で求められた項目（2026-09-30 の 2.1 Information Needed）に沿っている。

---

zeibun is a reference tool for reading Japanese tax laws (about 310 national and local tax laws and regulations). It is intended for tax accountants, accounting staff, students and individuals who need to check the current text of tax laws. The app only displays the text of the laws. It does not provide tax or legal advice, calculations, or filing services.

Problem it solves: the official e-Gov website is not designed for quickly looking up tax laws on a phone, does not work offline, and does not tell users when a law they read has been amended.

What the app adds on the device: on launch it checks for amendments and upcoming enforcement and marks the affected laws; laws that the user opens are saved on the device and can be read offline; the user can save all laws and run full-text search on the device; articles can be opened directly by number (for example "法法22" opens Article 22 of the Corporation Tax Act); laws and articles can be bookmarked.

How to access the main features (no login, setup or sample files are required):
1. Launch the app and tap "確認しました" on the disclaimer dialog.
2. Type "法法22" in the search field on the home screen. Article 22 of the Corporation Tax Act opens.
3. Turn on Airplane Mode and relaunch the app. The same law can still be read.
4. Type "損金の額" in the home search field and open the "本文" (full text) tab. Laws already opened are searched; Settings > "全法令を端末に保存" saves all laws for searching.

External services: the app uses a single external service, e-Gov Law API Version 2 (https://laws.e-gov.go.jp/), a public API provided by the Digital Agency of Japan, as the data source for the law texts. It uses no authentication service, payment processor, analytics SDK, advertising SDK or AI service, and it does not collect any personal data.

About e-Gov maintenance: e-Gov occasionally stops for maintenance (for example on October 1-2, 2026, which overlapped with a previous review). The app includes the list of tax laws at build time, so the list and law-name search work even while e-Gov is unavailable, and the app shows "e-Gov 法令検索がメンテナンス中..." (e-Gov is under maintenance) instead of a generic error. Law texts that have not been opened yet can be read once e-Gov is back. If you see the maintenance message, please wait a while and tap the banner at the top of the home screen to retry.

Regional differences: none. The app shows Japanese laws in Japanese and functions the same in all regions.

Third-party material: the law texts are provided by the Government of Japan through the e-Gov Law API. Under Article 13 of the Japanese Copyright Act, statutes and regulations are not subject to copyright. The data is also published under the Public Data License (PDL 1.0, compatible with CC BY 4.0), which allows reuse on condition that the source is credited. The app credits the source ("出典: e-Gov法令検索") on the home screen and in Settings, and states in the first-launch dialog, in Settings and in the App Store description that it is not an official app of the Digital Agency or e-Gov.

Support: https://ouchinao.github.io/zeibun/support
