import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:zeibun_core/zeibun_core.dart';

import '../db/database.dart';
import '../db/storage_errors.dart';
import '../egov/egov_api.dart';

/// 同期の状態（設計書 §4.4 の UI バナー用）。
sealed class SyncState {
  const SyncState();
}

class SyncIdle extends SyncState {
  const SyncIdle();
}

class SyncChecking extends SyncState {
  const SyncChecking();
}

class SyncSuccess extends SyncState {
  const SyncSuccess({
    required this.at,
    required this.revised,
    required this.pending,
    required this.checked,
  });
  final DateTime at;
  final int revised;
  final int pending;
  final int checked;
}

class SyncSkipped extends SyncState {
  const SyncSkipped(this.lastSyncAt);
  final DateTime lastSyncAt;
}

class SyncBackingOff extends SyncState {
  const SyncBackingOff(this.failures, this.lastSyncAt);
  final int failures;
  final DateTime? lastSyncAt;
}

class SyncOffline extends SyncState {
  const SyncOffline(this.lastSyncAt);
  final DateTime? lastSyncAt;
}

/// e-Gov 法令検索のメンテナンス中。SyncError に文言を渡す形にしないのは、
/// 利用者の操作や端末の問題ではないことを、バナーの色と文言で区別するため。
class SyncMaintenance extends SyncState {
  const SyncMaintenance(this.lastSyncAt);
  final DateTime? lastSyncAt;
}

class SyncError extends SyncState {
  const SyncError(this.message, this.lastSyncAt);
  final String message;
  final DateTime? lastSyncAt;
}

/// 起動時同期。
///
/// 一覧だけを取り、本文は開いたときに取る。起動時に本文まで先読みしないのは、
/// 主要税法だけで数 MB、全件なら数百 MB になり、初回起動が成立しないため。
/// 差分は `law_revision_id` と `updated` の比較だけで判定する。HTTP のキャッシュ
/// ヘッダも差分パラメータも API に無いので、他に方法がない（設計書 §4.3）。
class SyncService {
  SyncService({
    required this.api,
    required this.db,
    LawScope? scope,
    EgovRequests? requests,
    DateTime Function()? clock,
    this.minInterval = const Duration(minutes: 10),
    this.prefetch,
    this.loadBundledCatalog,
  })  : scope = scope ?? LawScope.tax,
        requests = requests ?? EgovRequests(),
        _clock = clock ?? DateTime.now;

  final EgovApi api;
  final AppDatabase db;
  final LawScope scope;
  final EgovRequests requests;
  final DateTime Function() _clock;

  /// 前回成功からこの時間以内なら一覧取得を省略する。
  final Duration minInterval;

  /// REVISED / CORRECTED になった法令の本文を取り直すフック（先読み設定が ON のとき）。
  final Future<void> Function(List<CatalogChange> changes)? prefetch;

  /// アプリに同梱した法令一覧（JSON）を読む。端末に一覧が無いときだけ呼ぶ。
  /// 中身を受け取らないのは、一覧がある 2 回目以降の起動でも 300KB 近い asset を
  /// 毎回読むことになるため。
  final Future<String> Function()? loadBundledCatalog;

  final ValueNotifier<SyncState> state = ValueNotifier(const SyncIdle());

  Future<SyncState>? _inFlight;

  static const _metaLastSync = 'last_catalog_sync_at';
  static const _metaLastAttempt = 'last_catalog_attempt_at';
  static const _metaFailures = 'consecutive_failures';

  Future<SyncState> runOnLaunch({bool skipRecent = true}) async {
    final lastSync = await _metaDate(_metaLastSync);
    // 10 分抑制は最後の成功から、バックオフは最後の試行から測る。
    // 成功から測ると、一度も成功していない端末や成功が古い端末で
    // 失敗のたびに即再試行してしまう
    if (skipRecent &&
        lastSync != null &&
        _clock().difference(lastSync) < minInterval) {
      return _emit(SyncSkipped(lastSync));
    }
    final failures = await _consecutiveFailures();
    final lastAttempt = await _metaDate(_metaLastAttempt);
    if (lastAttempt != null &&
        _clock().difference(lastAttempt) < backoffFor(failures)) {
      return _emit(SyncBackingOff(failures, lastSync));
    }
    return _syncOnce();
  }

  /// 手動更新を `runOnLaunch(force:)` にしないのは、「抑制は無視するがバックオフの
  /// カウンタは進める」といった条件の分岐が起動時の経路に増え続けるため。
  Future<SyncState> refreshNow() => _syncOnce();

  /// 設定画面の同期ログ。画面が DB を直接引かないための入口。
  Future<List<SyncRun>> recentRuns() => db.recentSyncRuns();

  /// 進行中の同期があればそれに相乗りする。バナー連打や設定画面との同時操作で
  /// 同じ 14 リクエストを並走させないため。
  Future<SyncState> _syncOnce() =>
      _inFlight ??= _sync().whenComplete(() => _inFlight = null);

  Future<SyncState> _sync() async {
    final lastSync = await _metaDate(_metaLastSync);
    _emit(const SyncChecking());
    await _seedIfEmpty();
    final startedAt = _clock();
    await db.setMeta(_metaLastAttempt, startedAt.toIso8601String());
    final runId = await db.startSyncRun(startedAt.toIso8601String());
    try {
      final remote = await CatalogFetcher(
              getJson: api.getJson, scope: scope, requests: requests)
          .fetch();
      final local = await db.localLawStates();
      final diff = diffCatalog(remote: remote.values, local: local);
      final now = _clock().toIso8601String();
      // unchanged の行も書くのは、未施行改正の登録（pending_revision_id）は
      // リビジョンが変わらなくても動くから
      await db.applyCatalogChanges(
        present: [
          for (final c in diff.changes)
            if (c.remote case final s?)
              (summary: s, scopeReason: scope.reasonFor(s)!),
        ],
        missing: [
          for (final c in diff.changes)
            if (c.kind == CatalogChangeKind.missing) c.lawId,
        ],
        at: now,
      );
      final refetch = diff.needsRefetch.toList();
      if (prefetch != null && refetch.isNotEmpty) {
        await prefetch!(refetch);
      }
      await db.setMeta(_metaLastSync, now);
      await db.setMeta(_metaFailures, '0');
      await db.finishSyncRun(runId,
          finishedAt: now,
          status: SyncRunStatus.success,
          lawsChecked: diff.changes.length,
          lawsUpdated: diff.revised + diff.corrected + diff.added);
      return _emit(SyncSuccess(
        at: _clock(),
        revised: diff.revised + diff.corrected,
        pending: diff.pending,
        checked: remote.length,
      ));
    } catch (e) {
      await _recordFailure(runId, e);
      // 通信環境の問題だけ「オフライン」と出し、e-Gov 側の異常や形式の変化は
      // 再試行しても直らないので別の文言にする
      return _emit(switch (e) {
        EgovApiException(kind: final k) when k.isOffline =>
          SyncOffline(lastSync),
        EgovApiException(kind: EgovErrorKind.maintenance) =>
          SyncMaintenance(lastSync),
        EgovApiException(kind: final k) =>
          SyncError('e-Gov からの応答が異常です（${k.name}）', lastSync),
        FormatException() ||
        TypeError() =>
          SyncError('一覧の形式を解釈できませんでした', lastSync),
        _ when isStorageFull(e) =>
          SyncError('端末の空き容量が足りず、法令一覧を保存できませんでした', lastSync),
        _ => SyncError('同期に失敗しました: $e', lastSync),
      });
    }
  }

  /// 端末に一覧が 1 件も無ければ、同梱の一覧で埋める。
  ///
  /// 起動処理で同期と別に埋めないのは、バナーからの手動更新と並走すると、取得した
  /// 最新の一覧を古い同梱の一覧で上書きしうるため（同期の中なら `_syncOnce` の
  /// 相乗りに乗る）。取得の後に埋めないのは、e-Gov がメンテナンス中や圏外のときに
  /// 一覧が空のまま何もできなくなるため。最終同期の時刻を進めないのは、同梱の
  /// 一覧は古いことがあり、10 分抑制で取り直しが遅れるため。
  Future<void> _seedIfEmpty() async {
    final load = loadBundledCatalog;
    if (load == null || (await db.localLawStates()).isNotEmpty) return;
    try {
      final snap = CatalogSnapshot.fromJson(
          jsonDecode(await load()) as Map<String, dynamic>);
      await db.applyCatalogChanges(
        present: [
          for (final l in snap.laws)
            if (scope.reasonFor(l) case final reason?)
              (summary: l, scopeReason: reason),
        ],
        missing: const [],
        at: snap.generatedAt,
      );
    } catch (e) {
      // 失敗を投げ直さないのは、同梱の一覧は予備にすぎず、e-Gov から取れれば
      // 足りるため
      debugPrint('bundled catalog not loaded: $e');
    }
  }

  Future<void> _recordFailure(int runId, Object error) async {
    final failures = await _consecutiveFailures() + 1;
    await db.setMeta(_metaFailures, '$failures');
    await db.finishSyncRun(runId,
        finishedAt: _clock().toIso8601String(),
        status: SyncRunStatus.error,
        error: error.toString());
    debugPrint('sync failed ($failures consecutive): $error');
  }

  SyncState _emit(SyncState s) => state.value = s;

  Future<DateTime?> _metaDate(String key) async {
    final v = await db.getMeta(key);
    return v == null ? null : DateTime.tryParse(v);
  }

  Future<int> _consecutiveFailures() async =>
      int.tryParse(await db.getMeta(_metaFailures) ?? '0') ?? 0;

  /// 連続失敗回数に応じた自動同期の間隔。
  /// 失敗のたびに即再試行しないのは、e-Gov 側の障害時に全端末が起動のたびに
  /// 叩き続けるのを避けるため。手動の「今すぐ更新」はこの抑制を受けない。
  static Duration backoffFor(int consecutiveFailures) =>
      switch (consecutiveFailures) {
        < 2 => Duration.zero,
        2 => const Duration(hours: 1),
        3 => const Duration(hours: 6),
        _ => const Duration(hours: 24),
      };
}
