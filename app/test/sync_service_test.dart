import 'package:flutter_test/flutter_test.dart';
import 'package:zeibun/data/db/database.dart';
import 'package:zeibun/data/repositories/sync_service.dart';
import 'package:zeibun_core/zeibun_core.dart';

import 'support/fake_egov_api.dart';

void main() {
  late AppDatabase db;
  late FakeEgovApi api;
  var now = DateTime(2026, 9, 23, 9, 0);

  setUp(() {
    db = inMemoryDatabase();
    api = FakeEgovApi();
    now = DateTime(2026, 9, 23, 9, 0);
  });

  tearDown(() => db.close());

  SyncService service({Future<void> Function(List<CatalogChange>)? prefetch}) =>
      SyncService(api: api, db: db, clock: () => now, prefetch: prefetch);

  test('first launch: catalog rows become laws with pending flags', () async {
    api.onPath('/api/2/laws', catalogHandler());
    final s = await service().runOnLaunch();
    expect(s, isA<SyncSuccess>());
    final success = s as SyncSuccess;
    expect(success.checked, 12);
    expect(success.pending, greaterThanOrEqualTo(10));
    final laws = await db.allLaws();
    expect(laws.length, 12);
    final sotoku = laws.firstWhere((l) => l.title == '租税特別措置法');
    expect(sotoku.pendingRevisionId, isNotNull);
    expect(sotoku.scopeReason, 'category:013');
    expect(sotoku.bodyRevisionId, isNull);
    // 一覧のクエリは asof 付き・repeal_status 絞り込みなし
    final first = api.calls.first;
    expect(first.queryParameters['asof'], '2099-12-31');
    expect(first.queryParameters.containsKey('repeal_status'), isFalse);
    // 国税 + 地方財政 + 明示 12 件 = 14 リクエスト
    expect(api.calls.length, 2 + LawScope.tax.explicitLawIds.length);
    final runs = await db.recentSyncRuns();
    expect(runs.single.status, 'success');
    expect(runs.single.lawsChecked, 12);
  });

  test('second launch within 10 minutes skips the catalog fetch', () async {
    api.onPath('/api/2/laws', catalogHandler());
    await service().runOnLaunch();
    final calls = api.calls.length;
    now = now.add(const Duration(minutes: 5));
    final s = await service().runOnLaunch();
    expect((s as SyncSuccess).skipped, isTrue);
    expect(api.calls.length, calls);
    // force なら取りに行く
    await service().runOnLaunch(force: true);
    expect(api.calls.length, greaterThan(calls));
  });

  test('revised law is detected and reported for refetch', () async {
    api.onPath('/api/2/laws', catalogHandler());
    await service().runOnLaunch();
    // 法人税法の本文をキャッシュ済みにしておく
    final houjin = (await db.allLaws()).firstWhere((l) => l.title == '法人税法');
    await db.replaceArticles(
      lawId: houjin.lawId,
      revisionId: houjin.currentRevisionId!,
      rows: const [],
      includesAmendSuppl: false,
      syncedAt: now.toIso8601String(),
    );
    // 次回の一覧では法人税法の現行リビジョンが変わっている
    api.onPath('/api/2/laws', catalogHandler(transform: (row) {
      final info = row['law_info'] as Map;
      if (info['law_id'] == houjin.lawId) {
        final cur =
            Map<String, dynamic>.from(row['current_revision_info'] as Map);
        cur['law_revision_id'] = '${houjin.lawId}_20270401_509AC0000000001';
        cur['updated'] = '2027-04-01T00:00:00+09:00';
        row['current_revision_info'] = cur;
      }
      return row;
    }));
    now = now.add(const Duration(hours: 1));
    List<CatalogChange>? refetched;
    final s = await service(prefetch: (c) async => refetched = c).runOnLaunch();
    expect((s as SyncSuccess).revised, 1);
    expect(refetched!.single.lawId, houjin.lawId);
    expect(refetched!.single.kind, CatalogChangeKind.revised);
    final after = await db.getLaw(houjin.lawId);
    expect(after!.currentRevisionId, endsWith('_20270401_509AC0000000001'));
    // 本文キャッシュの列は触らない → 「改正あり（未取得）」の状態
    expect(after.bodyRevisionId, houjin.currentRevisionId);
  });

  test('a law that disappears from the catalog is flagged, not deleted',
      () async {
    api.onPath('/api/2/laws', catalogHandler());
    await service().runOnLaunch();
    api.onPath('/api/2/laws', catalogHandler(transform: (row) {
      final info = row['law_info'] as Map;
      return info['law_id'] == '426AC0000000011' ? null : row;
    }));
    now = now.add(const Duration(hours: 1));
    await service().runOnLaunch();
    final chihou = await db.getLaw('426AC0000000011');
    expect(chihou, isNotNull);
    expect(chihou!.missingSince, isNotNull);
  });

  test('offline: state is SyncOffline and failures back off', () async {
    api.offline = true;
    final s1 = await service().runOnLaunch();
    expect(s1, isA<SyncOffline>());
    final s2 = await service().runOnLaunch();
    expect(s2, isA<SyncOffline>());
    expect(await db.getMeta('consecutive_failures'), '2');
    expect(SyncService.backoffFor(2), const Duration(hours: 1));
    expect(SyncService.backoffFor(3), const Duration(hours: 6));
    expect(SyncService.backoffFor(9), const Duration(hours: 24));
    final runs = await db.recentSyncRuns();
    expect(runs.length, 2);
    expect(runs.first.status, 'error');
  });

  test('4xx from the API is an error state, and recovery resets failures',
      () async {
    api.onPath('/api/2/laws', (u) => throw StateError('boom'));
    expect(await service().runOnLaunch(), isA<SyncError>());
    api.onPath('/api/2/laws', catalogHandler());
    now = now.add(const Duration(hours: 2));
    expect(await service().runOnLaunch(force: true), isA<SyncSuccess>());
    expect(await db.getMeta('consecutive_failures'), '0');
  });

  test('rows without current_revision_info trigger a plain (no asof) refetch',
      () async {
    // asof 付きでは current_revision_info を落として返し、asof なしでは通常どおり返す
    api.onPath('/api/2/laws', (uri) {
      final handler = catalogHandler(transform: (row) {
        if (uri.queryParameters.containsKey('asof')) {
          row.remove('current_revision_info');
        } else {
          // asof なしの一覧: revision_info が現行
          row['revision_info'] = row['current_revision_info'];
          row.remove('current_revision_info');
        }
        return row;
      });
      return handler(uri);
    });
    final s = await service().runOnLaunch();
    expect(s, isA<SyncSuccess>());
    final withAsof =
        api.calls.where((u) => u.queryParameters.containsKey('asof'));
    final plain =
        api.calls.where((u) => !u.queryParameters.containsKey('asof'));
    expect(withAsof.length, 2 + LawScope.tax.explicitLawIds.length);
    expect(plain.length, 1, reason: '国税のクエリだけ取り直す（他は行が無い）');
    final sotoku = (await db.allLaws()).firstWhere((l) => l.title == '租税特別措置法');
    // 現行は asof なし側から、未施行は asof 側から
    expect(sotoku.pendingRevisionId, isNotNull);
    expect(sotoku.currentRevisionId, isNot(sotoku.pendingRevisionId));
    expect(sotoku.currentRevisionId, contains('_2026'));
  });
}
