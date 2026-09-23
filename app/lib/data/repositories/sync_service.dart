import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:zeibun_core/zeibun_core.dart';

import '../db/database.dart';
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

class SyncDownloading extends SyncState {
  const SyncDownloading(this.done, this.total, this.currentTitle);
  final int done;
  final int total;
  final String currentTitle;
}

class SyncSuccess extends SyncState {
  const SyncSuccess({
    required this.at,
    required this.revised,
    required this.pending,
    required this.checked,
    this.skipped = false,
  });
  final DateTime at;
  final int revised;
  final int pending;
  final int checked;

  /// 10 分以内の再起動でカタログ取得を省略したとき。
  final bool skipped;
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

  static const _metaLastSync = 'last_catalog_sync_at';
  static const _metaBackoff = 'backoff_level';
  static const _metaFailures = 'consecutive_failures';

  /// 起動時に呼ぶ。`force` なら 10 分抑制とバックオフを無視する。
  Future<SyncState> runOnLaunch({bool force = false}) async {
    final lastSync = await _lastSyncAt();
    if (!force && lastSync != null) {
      final backoff = await _currentBackoff();
      final wait = backoff > minInterval ? backoff : minInterval;
      if (_clock().difference(lastSync) < wait) {
        final s = SyncSuccess(
            at: lastSync, revised: 0, pending: 0, checked: 0, skipped: true);
        state.value = s;
        return s;
      }
    }
    state.value = const SyncChecking();
    final startedAt = _clock();
    final runId = await db.startSyncRun(startedAt.toIso8601String());
    try {
      final remote = await _fetchCatalog();
      final local = await db.localLawStates();
      final diff = diffCatalog(remote: remote.values, local: local);
      final now = _clock().toIso8601String();
      var updated = 0;
      for (final c in diff.changes) {
        switch (c.kind) {
          case CatalogChangeKind.added:
          case CatalogChangeKind.revised:
          case CatalogChangeKind.corrected:
          case CatalogChangeKind.unchanged:
            final s = c.remote!;
            await db.upsertLawFromCatalog(s, scope.reasonFor(s)!);
            if (c.kind != CatalogChangeKind.unchanged) updated++;
          case CatalogChangeKind.missing:
            await db.markMissing(c.lawId, now);
        }
      }
      final refetch = diff.needsRefetch.toList();
      if (prefetch != null && refetch.isNotEmpty) {
        await prefetch!(refetch);
      }
      await db.setMeta(_metaLastSync, now);
      await db.setMeta(_metaFailures, '0');
      await db.setMeta(_metaBackoff, '0');
      await db.finishSyncRun(runId,
          finishedAt: now,
          status: 'success',
          lawsChecked: diff.changes.length,
          lawsUpdated: updated);
      final s = SyncSuccess(
        at: _clock(),
        revised: diff.revised + diff.corrected,
        pending: diff.pending,
        checked: remote.length,
      );
      state.value = s;
      return s;
    } catch (e) {
      final failures = await _bumpFailures();
      await db.finishSyncRun(runId,
          finishedAt: _clock().toIso8601String(),
          status: 'error',
          error: e.toString());
      final s = e is EgovApiException && e.statusCode == null
          ? SyncOffline(lastSync)
          : SyncError(e.toString(), lastSync);
      state.value = s;
      debugPrint('sync failed ($failures consecutive): $e');
      return s;
    }
  }

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
      final lacksCurrent = rows.any((r) => r['current_revision_info'] is! Map);
      final currentById = <String, Map<String, dynamic>>{};
      if (lacksCurrent) {
        for (final r in await _fetchAllPages(q, asOf: null)) {
          final id = (r['law_info'] as Map?)?['law_id'];
          if (id is String) currentById[id] = r;
        }
      }
      for (final row in rows) {
        var m = row;
        if (m['current_revision_info'] is! Map) {
          final id = (m['law_info'] as Map?)?['law_id'];
          final cur = currentById[id];
          if (cur != null) {
            m = {...m, 'current_revision_info': cur['revision_info']};
          }
        }
        final s = LawSummary.fromApiRow(m);
        if (scope.reasonFor(s) == null) continue;
        out.putIfAbsent(s.lawId, () => s);
      }
    }
    return out;
  }

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

  Future<DateTime?> _lastSyncAt() async {
    final v = await db.getMeta(_metaLastSync);
    return v == null ? null : DateTime.tryParse(v);
  }

  /// 連続失敗回数に応じた自動同期の間隔。
  /// 失敗のたびに即再試行しないのは、e-Gov 側の障害時に全端末が起動のたびに
  /// 叩き続けるのを避けるため。手動の「今すぐ更新」はこの抑制を受けない。
  Future<Duration> _currentBackoff() async {
    final failures = int.tryParse(await db.getMeta(_metaFailures) ?? '0') ?? 0;
    return backoffFor(failures);
  }

  static Duration backoffFor(int consecutiveFailures) {
    if (consecutiveFailures < 2) return Duration.zero;
    return switch (consecutiveFailures) {
      2 => const Duration(hours: 1),
      3 => const Duration(hours: 6),
      _ => const Duration(hours: 24),
    };
  }

  Future<int> _bumpFailures() async {
    final n = (int.tryParse(await db.getMeta(_metaFailures) ?? '0') ?? 0) + 1;
    await db.setMeta(_metaFailures, '$n');
    await db.setMeta(_metaBackoff, '${backoffFor(n).inMinutes}');
    return n;
  }
}
