import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zeibun_core/zeibun_core.dart';

import 'data/db/database.dart';
import 'data/db/database_location.dart';
import 'data/egov/egov_api.dart';
import 'data/repositories/bookmark_repository.dart';
import 'data/repositories/law_repository.dart';
import 'data/services/prefetch_service.dart';
import 'data/repositories/search_repository.dart';
import 'data/services/sync_service.dart';
import 'features/settings/settings_controller.dart';

/// 端末内 SQLite。Web では OPFS（drift の wasm 構成）。
QueryExecutor openDefaultExecutor() => driftDatabase(
      name: 'zeibun',
      native: const DriftNativeOptions(databaseDirectory: databaseDirectory),
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
        repo: ref.watch(lawRepositoryProvider),
        keepScreenOn: (on) => WakelockPlus.toggle(enable: on)));

final prefetchStateProvider =
    NotifierProvider<ListenableStateNotifier<PrefetchState>, PrefetchState>(
        () => ListenableStateNotifier(
            (ref) => ref.watch(prefetchServiceProvider).state));

/// 機能だけが使う Provider（最近開いた法令、全法令保存の対象数など）をここに
/// 置かないのは、全機能の変更でこのファイルが膨らみ、どの画面が何に依存するかが
/// 見えなくなるため。
final lawsStreamProvider =
    StreamProvider<List<Law>>((ref) => ref.watch(databaseProvider).watchLaws());

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
