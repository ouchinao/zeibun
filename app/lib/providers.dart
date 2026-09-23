import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeibun_core/zeibun_core.dart';

import 'data/db/database.dart';
import 'data/egov/egov_api.dart';
import 'data/repositories/law_repository.dart';
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

/// 同期状態（`ValueListenableBuilder` で購読する）。
final syncStateListenableProvider = Provider<ValueListenable<SyncState>>(
    (ref) => ref.watch(syncServiceProvider).state);

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
final abbrevIndexProvider = Provider<LawAbbrevIndex>((ref) =>
    abbrevIndexFor(ref.watch(lawsStreamProvider).valueOrNull ?? const []));

final searchRepositoryProvider = Provider<SearchRepository>((ref) =>
    SearchRepository(
        db: ref.watch(databaseProvider),
        abbrevs: ref.watch(abbrevIndexProvider)));

/// 画面を離れたら購読を止める（開いた法令ごとにストリームを残さない）。
final lawStreamProvider = StreamProvider.autoDispose.family<Law?, String>(
    (ref, lawId) => ref.watch(databaseProvider).watchLaw(lawId));
