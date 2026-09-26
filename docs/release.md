# リリース手順（iOS）

設計書 §13 Phase R の R3。Android は v1 では出さない（R7）。

## 前提（初回だけ）

- Apple Developer Program に登録済みで、Xcode にそのアカウントを追加してある
- App Store Connect に Bundle ID `io.github.ouchinao.zeibun` のアプリを作ってある
- `app/ios/Runner.xcworkspace` を Xcode で開き、Runner ターゲットの Signing & Capabilities で「Automatically manage signing」を ON にし、Team を選んである（この変更は `project.pbxproj` に `DEVELOPMENT_TEAM` として入るので、そのままコミットしてよい）
- 手元の Mac に Flutter stable と CocoaPods が入っている

## 毎回の手順

1. `main` を最新にし、`app/pubspec.yaml` の `version` を上げる。`x.y.z+ビルド番号` の形で、ビルド番号は前回より必ず大きくする（App Store Connect は同じビルド番号を受け付けない）
2. 変更内容を `CHANGELOG` 代わりに PR の説明とストアの「このバージョンの新機能」に書く
3. 手元で確認する

   ```sh
   cd app
   flutter pub get
   flutter analyze --fatal-infos
   flutter test
   ```

4. アーカイブを作る

   ```sh
   flutter build ipa --release
   ```

   `build/ios/archive/Runner.xcarchive` と `build/ios/ipa/*.ipa` ができる。署名でつまずいたら Xcode で `Runner.xcworkspace` を開き Product > Archive で同じことをする

5. アップロードする。次のどちらか
   - Xcode の Organizer でアーカイブを選び Distribute App > App Store Connect
   - `xcrun altool` の後継である Transporter アプリに `.ipa` をドラッグ
6. App Store Connect でビルドが処理されるのを待つ（数分〜数十分）。`ITSAppUsesNonExemptEncryption = false` を Info.plist に入れてあるので、輸出規制の質問は出ない
7. TestFlight の内部テストに自分を入れ、実機で通し確認（R12）をする
8. 問題なければ App Store のバージョンにそのビルドを割り当て、審査に出す
9. 審査が通って公開されたら、`main` の該当コミットに `v x.y.z` のタグを打つ

   ```sh
   git tag -a vX.Y.Z -m "App Store 公開 X.Y.Z"
   git push origin vX.Y.Z
   ```

## つまずきやすいところ

- ビルド番号を上げ忘れると、アップロードは成功するが App Store Connect が黙って捨てる
- `flutter build ipa` は `--export-method` を省略すると App Store 向けになる。TestFlight もこれでよい
- Pod まわりで壊れたら `cd ios && pod repo update && pod install`
