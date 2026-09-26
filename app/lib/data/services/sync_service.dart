import 'dart:async';

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
    final startedAt = _clock();
    await db.setMeta(_metaLastAttempt, startedAt.toIso8601String());
    final runId = await db.startSyncRun(startedAt.toIso8601String());
    try {
      final remote = await _fetchCatalog();
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

  /// スコープの一覧を取り、法令 ID → LawSummary にまとめる。
  ///
  /// クエリを並列に投げないのは、5 req/s の自主制限を守るため。
  /// `asof=2099-12-31` を付けるのは、1 リクエストで現行（`current_revision_info`）と
  /// 未施行の履歴（`revision_info`）が同時に取れ、`/law_revisions` を全法令に
  /// 投げずに済むから。
  Future<Map<String, LawSummary>> _fetchCatalog() async {
    final out = <String, LawSummary>{};
    for (final q in scope.catalogQueries()) {
      final rows = await _fetchAllPages(q, asOf: EgovRequests.farFutureAsOf);
      // asof 付きの行に current_revision_info が無ければ、その行の revision_info は
      // 未施行側なので現行として使えない。同じクエリを asof なしで取り直して現行を得る
      final currentById = <String, Map<String, dynamic>>{};
      if (rows.any((r) => r['current_revision_info'] is! Map)) {
        for (final r in await _fetchAllPages(q, asOf: null)) {
          currentById[_lawIdOf(r)] = r;
        }
      }
      for (final row in rows) {
        final s =
            LawSummary.fromApiRow(row, currentRow: currentById[_lawIdOf(row)]);
        if (scope.reasonFor(s) == null) continue;
        out.putIfAbsent(s.lawId, () => s);
      }
    }
    return out;
  }

  static String _lawIdOf(Map<String, dynamic> row) =>
      (row['law_info'] as Map?)?['law_id'] as String? ?? '';

  Future<List<Map<String, dynamic>>> _fetchAllPages(Map<String, String> q,
      {required String? asOf}) async {
    final rows = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      final body =
          await api.getJson(requests.laws(q, asOf: asOf, offset: offset));
      final page = (body['laws'] as List? ?? const []);
      rows.addAll(page.map((r) => (r as Map).cast<String, dynamic>()));
      final next = body['next_offset'];
      if (next is int && page.isNotEmpty && next > offset) {
        offset = next;
      } else {
        return rows;
      }
    }
  }

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
