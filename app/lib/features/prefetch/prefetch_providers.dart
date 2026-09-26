import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/platform/network_kind.dart';
import '../../providers.dart';

/// 一覧が変わるたびに数え直す（保存が進めば減る）。
final prefetchTargetCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  ref.watch(lawsStreamProvider);
  return (await ref.watch(prefetchServiceProvider).targets()).length;
});

/// テストで差し替えるための注入口。
final networkProbeProvider =
    Provider<Future<NetworkKind> Function()>((_) => detectNetworkKind);

enum PrefetchLaunch {
  start,

  confirmMetered,

  /// 回線の種類が分からない。分からないまま数百 MB を流さないので確認を出す
  confirmUnknown,
}

/// 状態が「回線を確認中」の bool だけなのは、確認ダイアログの二重表示を防ぐのに
/// 必要な情報がそれしか無いため。実行中かどうかは [prefetchStateProvider] が持つ。
class PrefetchLauncher extends Notifier<bool> {
  @override
  bool build() => false;

  /// Wi-Fi でも確認を出さないのは、毎回出る確認は読まれずに押されるため。
  /// 確認中に再度呼ばれたら null（画面は何もしない）。
  Future<PrefetchLaunch?> prepare() async {
    if (state) return null;
    state = true;
    try {
      return switch (await ref.read(networkProbeProvider)()) {
        NetworkKind.unmetered => PrefetchLaunch.start,
        NetworkKind.metered => PrefetchLaunch.confirmMetered,
        NetworkKind.unknown => PrefetchLaunch.confirmUnknown,
      };
    } finally {
      state = false;
    }
  }

  void start() => ref.read(prefetchServiceProvider).start();
}

final prefetchLauncherProvider =
    NotifierProvider<PrefetchLauncher, bool>(PrefetchLauncher.new);
