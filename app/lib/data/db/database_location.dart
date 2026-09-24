import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Android で呼ばないのは、`AndroidManifest.xml` の除外規則が同じディレクトリを
/// 外すため。iOS 側の受け口は `AppDelegate.swift`。
@visibleForTesting
const backupChannel = MethodChannel('io.github.ouchinao.zeibun/storage');

Future<String> _appSupportPath() async =>
    (await getApplicationSupportDirectory()).path;

/// drift_flutter の既定（Documents）に置かないのは、全法令を保存すると数百 MB の
/// 本文が iCloud / Google のバックアップに入るため（設計書 §11 I、Phase R R13）。
/// DB 用のサブディレクトリにまとめるのは、`-wal` / `-shm` などの付随ファイルごと
/// 1 回の指定で除外するため。
///
/// 除外に失敗しても DB は開く。除外は容量の問題で、開けなくなるより軽い。
Future<String> databaseDirectory({
  Future<String> Function() appSupportPath = _appSupportPath,
}) async {
  final dir = p.join(await appSupportPath(), 'db');
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    try {
      await backupChannel.invokeMethod<void>('excludeFromBackup', dir);
    } on PlatformException catch (e) {
      debugPrint('backup exclusion failed: $e');
    } on MissingPluginException catch (e) {
      debugPrint('backup exclusion unavailable: $e');
    }
  }
  return dir;
}
