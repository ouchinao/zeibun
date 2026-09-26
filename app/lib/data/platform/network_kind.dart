import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum NetworkKind {
  unmetered,
  metered,

  /// プラグインが応答しない・対応していない環境。判断は画面側に委ねる
  unknown,
}

/// `mobile` の有無だけで判定しないのは、Wi-Fi とモバイルの両方に繋がった端末で
/// 警告を出さないため。取得の失敗を例外のまま返さないのは、回線が分からない
/// だけで保存を始められなくならないようにするため。
/// Provider にせず関数なのは、一回きりの問い合わせで、autoDispose の Provider を
/// `.future` で読むと購読者が無いまま破棄されて例外になるため。
Future<NetworkKind> detectNetworkKind() async {
  final List<ConnectivityResult> results;
  try {
    results = await Connectivity().checkConnectivity();
  } catch (e) {
    debugPrint('connectivity unavailable: $e');
    return NetworkKind.unknown;
  }
  if (results.contains(ConnectivityResult.wifi) ||
      results.contains(ConnectivityResult.ethernet)) {
    return NetworkKind.unmetered;
  }
  if (results.contains(ConnectivityResult.mobile)) return NetworkKind.metered;
  return NetworkKind.unknown;
}
