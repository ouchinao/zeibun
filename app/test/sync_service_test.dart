import 'package:flutter_test/flutter_test.dart';
import 'package:zeibun/data/db/database.dart';
import 'package:zeibun/data/egov/egov_api.dart';
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
    expect(await service().runOnLaunch(), isA<SyncSkipped>());
    expect(api.calls.length, calls);
    // 設定で省略を切っていれば取りに行く
    await service().runOnLaunch(skipRecent: false);
    expect(api.calls.length, greaterThan(calls));
  });

  test('concurrent refresh requests share one run', () async {
    api.onPath('/api/2/laws', catalogHandler());
    final s = service();
    final results = await Future.wait([s.refreshNow(), s.refreshNow()]);
    expect(results, everyElement(isA<SyncSuccess>()));
    expect(api.calls.length, 2 + LawScope.tax.explicitLawIds.length);
    expect((await db.recentSyncRuns()).length, 1);
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
    expect(after.bodyCache, BodyCache.outdated);
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
    now = now.add(const Duration(minutes: 1));
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

  test(
      'after two failures the next automatic launch within 1h makes no request',
      () async {
    api.offline = true;
    await service().runOnLaunch();
    now = now.add(const Duration(minutes: 1));
    await service().runOnLaunch();
    final calls = api.calls.length;

    // 一度も成功していなくても、最後の試行から 1 時間は自動同期しない
    now = now.add(const Duration(minutes: 30));
    final held = await service().runOnLaunch();
    expect(held, isA<SyncBackingOff>());
    expect(api.calls.length, calls, reason: 'バックオフ中はリクエストしない');

    // 手動更新は抑制を受けない（失敗すればカウンタは 3 になり、待機は 6 時間に伸びる）
    await service().refreshNow();
    expect(api.calls.length, greaterThan(calls));
    expect(await db.getMeta('consecutive_failures'), '3');
    now = now.add(const Duration(hours: 2));
    expect(await service().runOnLaunch(), isA<SyncBackingOff>());

    // バックオフが明けたら再試行し、成功でカウンタが戻る
    api.offline = false;
    api.onPath('/api/2/laws', catalogHandler());
    now = now.add(const Duration(hours: 5));
    expect(await service().runOnLaunch(), isA<SyncSuccess>());
    expect(await db.getMeta('consecutive_failures'), '0');
  });

  test('a 4xx from the API is an error (not offline), and recovery resets',
      () async {
    api.onPath(
        '/api/2/laws',
        (u) => throw EgovApiException(EgovErrorKind.clientError, u,
            statusCode: 404));
    expect(await service().runOnLaunch(), isA<SyncError>());
    api.onPath('/api/2/laws', catalogHandler());
    now = now.add(const Duration(hours: 2));
    expect(await service().refreshNow(), isA<SyncSuccess>());
    expect(await db.getMeta('consecutive_failures'), '0');
  });

  test('an unparseable catalog is an error state, and is recorded', () async {
    api.onPath('/api/2/laws', (u) => '{"laws": "not a list"}');
    expect(await service().runOnLaunch(), isA<SyncError>());
    expect((await db.recentSyncRuns()).single.status, 'error');
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
