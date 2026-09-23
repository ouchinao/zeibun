import 'package:flutter_test/flutter_test.dart';
import 'package:zeibun/data/db/database.dart';
import 'package:zeibun/data/repositories/law_repository.dart';
import 'package:zeibun/data/repositories/sync_service.dart';
import 'package:zeibun_core/zeibun_core.dart';

import 'support/fake_egov_api.dart';

void main() {
  late AppDatabase db;
  late FakeEgovApi api;
  const lawId = '426AC0000000011'; // 地方法人税法
  var now = DateTime(2026, 9, 23, 10, 0);

  setUp(() async {
    db = inMemoryDatabase();
    api = FakeEgovApi();
    now = DateTime(2026, 9, 23, 10, 0);
    api.onPath('/api/2/laws', catalogHandler());
    await SyncService(api: api, db: db, clock: () => now).runOnLaunch();
    api.calls.clear();
  });

  tearDown(() => db.close());

  LawRepository repo() => LawRepository(api: api, db: db, clock: () => now);

  final revTag = RegExp('<law_revision_id>[^<]+</law_revision_id>');

  /// フィクスチャの revision_info を要求 ID に合わせて返す。
  void serveBody(String revisionId) {
    api.onPath('/api/2/law_data/$revisionId', (uri) {
      return fixture('law_data_426AC0000000011_地方法人税法.xml').replaceFirst(revTag,
          '<law_revision_id>${uri.pathSegments.last}</law_revision_id>');
    });
  }

  test('first open fetches /law_data without amendment suppl, then caches',
      () async {
    final law = (await db.getLaw(lawId))!;
    serveBody(law.currentRevisionId!);

    final r1 = await repo().openLaw(lawId);
    expect(r1.status, BodyStatus.fetched);
    expect(r1.articles.where((a) => a.section == 'main').length,
        greaterThanOrEqualTo(20));
    final call = api.calls.single;
    expect(call.path, '/api/2/law_data/${law.currentRevisionId}');
    expect(call.queryParameters['omit_amendment_suppl_provision'], 'true');
    expect(call.queryParameters['response_format'], 'xml');

    final saved = (await db.getLaw(lawId))!;
    expect(saved.bodyCache, BodyCache.current);
    expect(saved.bodyIncludesAmendSuppl, isFalse);
    expect(saved.lastOpenedAt, isNotNull);

    // 2 回目は通信なし
    final r2 = await repo().openLaw(lawId);
    expect(r2.status, BodyStatus.fresh);
    expect(api.calls.length, 1);
  });

  test('loading amendment suppl refetches the full text and remembers it',
      () async {
    final law = (await db.getLaw(lawId))!;
    serveBody(law.currentRevisionId!);
    await repo().openLaw(lawId);
    final r = await repo().openLaw(lawId, includeAmendSuppl: true);
    expect(r.status, BodyStatus.fetched);
    final call = api.calls.last;
    expect(call.queryParameters.containsKey('omit_amendment_suppl_provision'),
        isFalse);
    expect((await db.getLaw(lawId))!.bodyIncludesAmendSuppl, isTrue);
    // 以後は「改正附則込み」がキャッシュ扱い
    expect((await repo().openLaw(lawId)).status, BodyStatus.fresh);
  });

  test('a revision mismatch in the envelope is rejected and nothing is saved',
      () async {
    final law = (await db.getLaw(lawId))!;
    api.onPath(
        '/api/2/law_data/${law.currentRevisionId}',
        (_) => fixture('law_data_426AC0000000011_地方法人税法.xml').replaceFirst(
            revTag,
            '<law_revision_id>426AC0000000011_20000101_000000000000000</law_revision_id>'));
    final r = await repo().openLaw(lawId);
    expect(r.status, BodyStatus.unavailable);
    expect(r.failure, BodyFailure.invalidData);
    expect((await db.getLaw(lawId))!.bodyCache, BodyCache.none);
    expect(await db.articlesOf(lawId), isEmpty);
  });

  test('offline with an old cache shows stale content, marked as offline',
      () async {
    final law = (await db.getLaw(lawId))!;
    serveBody(law.currentRevisionId!);
    await repo().openLaw(lawId);

    // 一覧側だけ新しいリビジョンになったとする（改正の施行）
    await db.upsertLawFromCatalog(
      LawSummary(
        lawId: law.lawId,
        lawNum: law.lawNum,
        lawType: law.lawType,
        title: law.title,
        category: law.category,
        updated: '2027-04-01T00:00:00+09:00',
        currentRevisionId: '${lawId}_20270401_509AC0000000001',
        currentEnforcedAt: '2027-04-01',
      ),
      'category:013',
    );
    api.offline = true;
    final r = await repo().openLaw(lawId);
    expect(r.status, BodyStatus.stale);
    expect(r.failure, BodyFailure.offline);
    expect(r.articles, isNotEmpty);
    final after = (await db.getLaw(lawId))!;
    expect(after.bodyRevisionId, law.currentRevisionId); // 古いまま
    expect(after.bodyCache, BodyCache.outdated);
  });

  test(
      'refreshRevisions stores the history, reuses it for 10 minutes, '
      'and falls back to it offline', () async {
    api.onPath('/api/2/law_revisions/340AC0000000034',
        (_) => fixture('law_revisions_340AC0000000034_法人税法.json'));
    final revs = await repo().refreshRevisions('340AC0000000034');
    expect(revs, isNotEmpty);
    expect(revs.where((r) => r.status == 'UnEnforced'), isNotEmpty);
    expect(revs.first.enforcedAt.compareTo(revs.last.enforcedAt),
        greaterThanOrEqualTo(0));
    final calls = api.calls.length;

    now = now.add(const Duration(minutes: 5));
    await repo().refreshRevisions('340AC0000000034');
    expect(api.calls.length, calls, reason: '直近に取ったものは取り直さない');

    now = now.add(const Duration(hours: 1));
    api.offline = true;
    final cached = await repo().refreshRevisions('340AC0000000034');
    expect(api.calls.length, calls + 1);
    expect(cached.length, revs.length);
  });
}
