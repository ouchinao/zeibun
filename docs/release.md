# リリース手順（iOS）

設計書 §13 Phase R の R3。Android は v1 では出さない（R7）。
コマンドはすべて Mac のターミナルで打つ。`~/zeibun` に clone してある前提。

## A. Mac の準備（Mac ごとに 1 回）

1. ターミナルが Apple シリコンのまま動いているか確かめる

   ```sh
   uname -m        # arm64 ならOK。x86_64 なら下の手順で直す
   ```

   `x86_64` のときは、ターミナルを終了（⌘Q）→ Finder で「アプリケーション → ユーティリティ → ターミナル」を右クリック →「情報を見る」→「Rosetta を使用して開く」のチェックを外す → 開き直して `uname -m` をもう一度。

   Rosetta のまま入れた Homebrew は `/usr/local` に入り、ビルド済みの部品が配られないので、依存を何時間もかけてソースからビルドする。

2. Homebrew（Apple シリコン用）と CocoaPods を入れる

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
   eval "$(/opt/homebrew/bin/brew shellenv)"
   which brew                 # /opt/homebrew/bin/brew と出ること
   brew install cocoapods     # 数分で終わる。何十分もかかるなら 1 に戻る
   pod --version
   ```

3. Flutter が動くか確かめる

   ```sh
   flutter doctor
   ```

   - 1 行目に「(Rosetta)」が出ないこと
   - Xcode の行が ✓ であること（Android の ✗ は v1 では無視してよい）

4. git の作者を GitHub の非公開アドレスにする（公開リポジトリに個人のメールアドレスを出さないため）

   ```sh
   git config --global user.name "ouchinao"
   git config --global user.email "67366394+ouchinao@users.noreply.github.com"
   ```

5. リポジトリを取ってくる

   ```sh
   git clone https://github.com/ouchinao/zeibun.git ~/zeibun
   ```

## B. 署名の準備（Mac ごとに 1 回）

`DEVELOPMENT_TEAM` はリポジトリに入っているので、Team を選び直す必要は無い。Xcode にアカウントを入れて、端末を 1 台登録するだけ。

1. Xcode を開く

   ```sh
   cd ~/zeibun/app
   flutter pub get
   open ios/Runner.xcworkspace
   ```

   `.xcodeproj` を開かないのは、プラグインの設定が `.xcworkspace` 側にしか入らず、そちらでは署名やビルドが通らないため。

2. Xcode → Settings… → Accounts →「＋」→「Apple Account」で、Developer Program のアカウントでサインインする。「(Personal Team)」ではない Team が出ること
3. 左の青い「Runner」→ TARGETS の「Runner」→「Signing & Capabilities」で次を確かめる
   - 「Automatically manage signing」にチェック
   - Team が自分の Team
   - Bundle Identifier が `io.github.ouchinao.zeibun`
4. 「Your team has no devices」と出たら、iPhone をケーブルでつなぐ
   - iPhone のロックを外し、「このコンピュータを信頼」→ パスコード
   - Xcode 上部の実行先を、つないだ iPhone にする
   - 求められたら iPhone の「設定 → プライバシーとセキュリティ → デベロッパモード」を ON（再起動あり）
   - Signing の画面で「Try Again」を押し、⚠ が消えること

`pod install` は手で打たない。Podfile はリポジトリに無く、要るときは Flutter のビルドが作る（v1.0.0 は Swift Package Manager で解決され、Podfile は作られなかった）。

## C. 毎回の手順

### 1. バージョンを上げる（PR で）

`app/pubspec.yaml` の `version` を `x.y.z+ビルド番号` の形で上げる。ビルド番号は前回より必ず大きくする（同じ番号は App Store Connect に捨てられる）。

同じ PR で、アプリに同梱する法令一覧も作り直す。古いままでも同期で最新になるが、e-Gov に接続できない初回起動ではこの一覧がそのまま出るため。

```sh
cd ~/zeibun/app
dart run tool/update_catalog_snapshot.dart   # assets/catalog_snapshot.json を書き換える
```

```sh
cd ~/zeibun
git checkout main && git pull
git checkout -b version-X.Y.Z
# app/pubspec.yaml の version を書き換える（例: 1.0.0+1 → 1.0.1+2）
git commit -am "バージョンを X.Y.Z+N にする"
git push -u origin version-X.Y.Z
```

PR を作ってマージする。変更内容は PR の説明と、ストアの「このバージョンの新機能」に書く。

### 2. 手元で確かめる

```sh
cd ~/zeibun
git checkout main && git pull
cd app
flutter pub get
flutter analyze --fatal-infos
flutter test --timeout 60s
```

### 3. ipa を作る

```sh
flutter build ipa --release
ls build/ios/ipa/          # .ipa（v1.0.0 で 23MB）ができていること
```

最後に「Built IPA to build/ios/ipa」と出れば成功。

### 4. アップロードする

Transporter を使う（Mac App Store から入れる）。

1. Transporter を開き、Developer Program のアカウントでサインイン
2. Finder で `~/zeibun/app/build/ios/ipa/` を開き、`.ipa` を Transporter にドラッグ
3. 「配信」を押す

Transporter が使えないときは、Xcode で `ios/Runner.xcworkspace` を開き、実行先を「Any iOS Device (arm64)」にして Product → Archive → Organizer で Distribute App → App Store Connect → Upload。

### 5. TestFlight で確かめる

1. App Store Connect → アプリ → TestFlight に、10〜30 分でビルドが出る。`ITSAppUsesNonExemptEncryption = false` を Info.plist に入れてあるので、輸出規制の質問は出ない
2. 初回だけ: TestFlight の「内部テスト」でグループを作り、自分を追加する
3. 初回だけ: Apple から届く招待メール（件名に TestFlight）を **iPhone で**開き、「View in TestFlight」→「承認」する。承認するまで、テスターの状態は「利用可能なビルドなし」のままで、TestFlight アプリも「テスト準備完了」の画面から進まない
   - メールが見つからないときは、グループからテスターを外して入れ直すと招待が届き直す（テスターの「…」から出る「メール」は自分で書く普通のメールで、招待ではない）
   - iPhone の「設定 → 自分の名前 → メディアと購入」のアカウントが、招待したアドレスと同じであること
4. iPhone の TestFlight アプリからインストールする。2 回目以降は「アップデート」を押すだけ
5. 実機で通し確認（設計書 R12）をする

### 6. 審査に出す

1. App Store Connect → アプリ → 配信のバージョンを開き、「ビルド」の欄で TestFlight で確かめたビルドを選ぶ
2. 「このバージョンの新機能」を書く（初回は不要）
3. 「審査用に追加」→「審査に提出」

### 7. 公開されたらタグを打つ

```sh
cd ~/zeibun
git checkout main && git pull
git tag -a vX.Y.Z -m "App Store 公開 X.Y.Z"
git push origin vX.Y.Z
```

## つまずいたとき

| 症状 | 直し方 |
|---|---|
| `brew install` が何十分も終わらない、「Tier 3 configuration」と出る | ターミナルが Rosetta で動いている。A-1 からやり直す |
| `flutter doctor` の 1 行目に「(Rosetta)」 | 同上 |
| `pod install` で「No Podfile found」 | 手で打たなくてよい。`flutter build ipa` から進める |
| `flutter build` で「No valid code signing certificates were found」 | Xcode にアカウントが入っていないか Team が未選択。B-2・B-3 |
| Signing の画面で「Your team has no devices」 | iPhone をつないで登録する。B-4 |
| アップロードは成功したのに TestFlight に出てこない | ビルド番号を上げ忘れている。C-1 からやり直す |
| TestFlight アプリが「テスト準備完了」「コードを使う」の画面から進まない | 招待を承認していない。C-5 の 3 |
| アップロード後に「SDK が古い」というメールが来る | Xcode を上げてから C-3 をやり直す |
