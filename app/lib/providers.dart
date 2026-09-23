import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeibun_core/zeibun_core.dart';

import 'data/db/database.dart';
import 'data/egov/egov_api.dart';
import 'data/repositories/law_repository.dart';
import 'data/repositories/search_repository.dart';
import 'data/repositories/sync_service.dart';

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

final searchRepositoryProvider = Provider<SearchRepository>(
    (ref) => SearchRepository(db: ref.watch(databaseProvider)));

/// 設定（設計書 §8 設定画面）。
class AppSettings {
  const AppSettings({this.prefetchEnabled = false, this.skipRecentSync = true});
  final bool prefetchEnabled;

  /// 前回成功から 10 分以内の再起動でカタログ取得を省略する。
  final bool skipRecentSync;

  AppSettings copyWith({bool? prefetchEnabled, bool? skipRecentSync}) =>
      AppSettings(
        prefetchEnabled: prefetchEnabled ?? this.prefetchEnabled,
        skipRecentSync: skipRecentSync ?? this.skipRecentSync,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kPrefetch = 'prefetch_enabled';
  static const _kSkipRecent = 'skip_recent_sync';

  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = AppSettings(
      prefetchEnabled: p.getBool(_kPrefetch) ?? false,
      skipRecentSync: p.getBool(_kSkipRecent) ?? true,
    );
  }

  Future<void> setPrefetch(bool v) async {
    state = state.copyWith(prefetchEnabled: v);
    (await SharedPreferences.getInstance()).setBool(_kPrefetch, v);
  }

  Future<void> setSkipRecentSync(bool v) async {
    state = state.copyWith(skipRecentSync: v);
    (await SharedPreferences.getInstance()).setBool(_kSkipRecent, v);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final repo = ref.watch(lawRepositoryProvider);
  return SyncService(
    api: ref.watch(egovApiProvider),
    db: db,
    prefetch: (changes) async {
      // 先読み設定が ON のとき、主要法令と最近開いた法令の本文を取り直す（設計書 §4.4）
      if (!ref.read(settingsProvider).prefetchEnabled) return;
      final cutoff =
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      for (final c in changes) {
        final law = await db.getLaw(c.lawId);
        if (law == null || law.bodyRevisionId == null) continue;
        final recent =
            law.lastOpenedAt != null && law.lastOpenedAt!.compareTo(cutoff) > 0;
        if (!majorTaxLaws.containsKey(c.lawId) && !recent) continue;
        try {
          await repo.fetchBody(c.lawId, law.currentRevisionId!,
              includeAmendSuppl: law.bodyIncludesAmendSuppl);
        } catch (e) {
          debugPrint('prefetch failed for ${c.lawId}: $e');
        }
      }
    },
  );
});

/// 同期状態（`ValueListenableBuilder` で購読する）。
final syncStateListenableProvider = Provider<ValueListenable<SyncState>>(
    (ref) => ref.watch(syncServiceProvider).state);

final lawsStreamProvider =
    StreamProvider<List<Law>>((ref) => ref.watch(databaseProvider).watchLaws());

final lawStreamProvider = StreamProvider.family<Law?, String>(
    (ref, lawId) => ref.watch(databaseProvider).watchLaw(lawId));

final recentLawsProvider = FutureProvider<List<Law>>((ref) {
  ref.watch(lawsStreamProvider); // 一覧が変わったら取り直す
  return ref.watch(databaseProvider).recentLaws();
});
