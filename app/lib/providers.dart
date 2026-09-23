import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeibun_core/zeibun_core.dart';

import 'data/db/database.dart';
import 'data/egov/egov_api.dart';
import 'data/repositories/bookmark_repository.dart';
import 'data/repositories/law_repository.dart';
import 'data/repositories/prefetch_service.dart';
import 'data/repositories/search_repository.dart';
import 'data/repositories/sync_service.dart';
import 'features/settings/settings_controller.dart';

/// 端末内 SQLite。Web では OPFS（drift の wasm 構成）。
QueryExecutor openDefaultExecutor() => driftDatabase(
      name: 'zeibun',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openDefaultExecutor());
  ref.onDispose(db.close);
  return db;
});

final egovApiProvider = Provider<EgovApi>((ref) => DioEgovApi());

final lawRepositoryProvider = Provider<LawRepository>((ref) => LawRepository(
      api: ref.watch(egovApiProvider),
      db: ref.watch(databaseProvider),
    ));

final bookmarkRepositoryProvider = Provider<BookmarkRepository>(
    (ref) => BookmarkRepository(db: ref.watch(databaseProvider)));

final syncServiceProvider = Provider<SyncService>((ref) {
  final repo = ref.watch(lawRepositoryProvider);
  return SyncService(
    api: ref.watch(egovApiProvider),
    db: ref.watch(databaseProvider),
    prefetch: (changes) => ref.read(settingsProvider).prefetchEnabled
        ? repo.prefetchRevised(changes)
        : Future.value(),
  );
});

/// Service 自体を `Notifier` にせず `ValueNotifier` を写すのは、同期・保存の
/// ロジックを Riverpod に依存しない純 Dart のままテストするため。
class ListenableStateNotifier<T> extends Notifier<T> {
  ListenableStateNotifier(this.source);

  final ValueListenable<T> Function(Ref ref) source;

  @override
  T build() {
    final listenable = source(ref);
    void copy() => state = listenable.value;
    listenable.addListener(copy);
    ref.onDispose(() => listenable.removeListener(copy));
    return listenable.value;
  }
}

final syncStateProvider =
    NotifierProvider<ListenableStateNotifier<SyncState>, SyncState>(() =>
        ListenableStateNotifier((ref) => ref.watch(syncServiceProvider).state));

final prefetchServiceProvider = Provider<PrefetchService>((ref) =>
    PrefetchService(
        db: ref.watch(databaseProvider),
        repo: ref.watch(lawRepositoryProvider)));

final prefetchStateProvider =
    NotifierProvider<ListenableStateNotifier<PrefetchState>, PrefetchState>(
        () => ListenableStateNotifier(
            (ref) => ref.watch(prefetchServiceProvider).state));

/// 一覧が変わるたびに数え直す（保存が進めば減る）。
final prefetchTargetCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  ref.watch(lawsStreamProvider);
  return (await ref.watch(prefetchServiceProvider).targets()).length;
});

enum NetworkKind {
  unmetered,
  metered,

  /// プラグインが応答しない・対応していない環境。判断は画面側に委ねる
  unknown,
}

/// `mobile` の有無だけで判定しないのは、Wi-Fi とモバイルの両方に繋がった端末で
/// 警告を出さないため。取得の失敗を例外のまま画面に渡さないのは、回線が分からない
/// だけで保存を始められなくならないようにするため。
final networkKindProvider =
    FutureProvider.autoDispose<NetworkKind>((ref) async {
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
});

final lawsStreamProvider =
    StreamProvider<List<Law>>((ref) => ref.watch(databaseProvider).watchLaws());

/// 一覧から導く。別クエリにしないのは、一覧の変更通知と二重に購読しないため。
final recentLawsProvider = Provider<AsyncValue<List<Law>>>((ref) => ref
    .watch(lawsStreamProvider)
    .whenData((rows) => (rows.where((l) => l.lastOpenedAt != null).toList()
          ..sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!)))
        .take(10)
        .toList()));

/// 略称索引は一覧が変わったときだけ組み直す（同期で法令が増えた後に
/// 古い索引で検索しないため）。
final abbrevIndexProvider = Provider<LawAbbrevIndex>(
    (ref) => abbrevIndexFor(ref.watch(lawsStreamProvider).value ?? const []));

final searchRepositoryProvider = Provider<SearchRepository>((ref) =>
    SearchRepository(
        db: ref.watch(databaseProvider),
        abbrevs: ref.watch(abbrevIndexProvider)));

/// 画面を離れたら購読を止める（開いた法令ごとにストリームを残さない）。
final lawStreamProvider = StreamProvider.autoDispose.family<Law?, String>(
    (ref, lawId) => ref.watch(databaseProvider).watchLaw(lawId));
