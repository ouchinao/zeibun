import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 設定画面にバージョンを出すのは、問い合わせのときに「どの版か」を利用者に
/// 読んでもらうため。
final appVersionProvider =
    FutureProvider<PackageInfo>((_) => PackageInfo.fromPlatform());

String formatVersion(PackageInfo info) =>
    '${info.version} (${info.buildNumber})';
