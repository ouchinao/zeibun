import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/common.dart';
import 'package:zeibun/data/db/database.dart';
import 'package:zeibun/data/egov/egov_api.dart';
import 'package:zeibun/data/repositories/law_repository.dart';
import 'package:zeibun/data/repositories/prefetch_service.dart';
import 'package:zeibun/data/repositories/sync_service.dart';

import 'support/fake_egov_api.dart';

/// 端末の空き容量が尽きたときに SQLite が返す例外を、保存の段で起こす。
class _FullDiskRepository extends LawRepository {
  _FullDiskRepository({required super.api, required super.db});

  @override
  Future<int> fetchBody(String lawId, String revisionId,
          {required bool includeAmendSuppl}) async =>
      throw SqliteException(
          extendedResultCode: SqlError.SQLITE_FULL,
          message: 'database or disk is full');
}

void main() {
  late AppDatabase db;
  late FakeEgovApi api;
  late PrefetchService service;

  setUp(() async {
    db = inMemoryDatabase();
    api = FakeEgovApi()
      ..onPath('/api/2/laws', catalogHandler())
      ..onPathPrefix('/api/2/law_data/', lawDataHandler());
    await SyncService(api: api, db: db).runOnLaunch();
    api.calls.clear();
    service = PrefetchService(db: db, repo: LawRepository(api: api, db: db));
  });

  tearDown(() => db.close());

  Future<int> savedCount() async => (await db.allLaws())
      .where((l) => l.bodyCache == BodyCache.current)
      .length;

  test('saves every current law that has no body and reports progress',
      () async {
    final seen = <PrefetchState>[];
    service.state.addListener(() => seen.add(service.state.value));

    final result = await service.start() as PrefetchFinished;
    expect(result.outcome, PrefetchOutcome.completed);
    expect(result.progress.total, 12);
    expect(result.progress.done, 12);
    expect(result.progress.failed, 0);
    expect(result.progress.bytes, greaterThan(0));
    expect(await savedCount(), 12);
    expect(api.calls.length, 12);

    final running = seen.whereType<PrefetchRunning>().toList();
    expect(running.first.progress.total, 0, reason: '数え終わる前から実行中');
    expect(running.last.progress.done, 11);
    expect(
        running.map((s) => s.currentTitle).where((t) => t.isNotEmpty).toSet(),
        hasLength(12));
    expect(seen.last, isA<PrefetchFinished>());
  });

  test('laws whose body is already current are not fetched again', () async {
    await LawRepository(api: api, db: db).openLaw('426AC0000000011');
    api.calls.clear();
    final result = await service.start() as PrefetchFinished;
    expect(result.progress.total, 11);
    expect(api.calls.length, 11);
    expect(await savedCount(), 12);
  });

  test('cancel stops after the law being fetched, keeping what was saved',
      () async {
    service.state.addListener(() {
      final s = service.state.value;
      if (s is PrefetchRunning && s.currentTitle.isNotEmpty) service.cancel();
    });
    final result = await service.start() as PrefetchFinished;
    expect(result.outcome, PrefetchOutcome.cancelled);
    expect(result.progress.done, 1);
    expect(await savedCount(), 1);
    expect((await service.targets()).length, 11);
  });

  test('a law the API rejects is counted as failed and the rest continue',
      () async {
    final rejected = (await db.getLaw('340AC0000000034'))!.currentRevisionId!;
    api.onPath(
        '/api/2/law_data/$rejected',
        (u) => throw EgovApiException(EgovErrorKind.serverError, u,
            statusCode: 500));
    final result = await service.start() as PrefetchFinished;
    expect(result.outcome, PrefetchOutcome.completed);
    expect(result.progress.done, 11);
    expect(result.progress.failed, 1);
    expect((await db.getLaw('340AC0000000034'))!.bodyCache, BodyCache.none);
  });

  test('a run gives up after three consecutive offline failures', () async {
    api.offline = true;
    final result = await service.start() as PrefetchFinished;
    expect(result.outcome, PrefetchOutcome.offline);
    expect(result.progress.failed, 3);
    expect(result.progress.done, 0);
    expect(api.calls.length, 3);
  });

  test('an unexpected error ends the run as aborted instead of hanging',
      () async {
    final broken = (await db.getLaw('340AC0000000034'))!.currentRevisionId!;
    api.onPath('/api/2/law_data/$broken', (_) => throw StateError('boom'));
    final result = await service.start() as PrefetchFinished;
    expect(result.outcome, PrefetchOutcome.aborted);
    expect(service.state.value, isA<PrefetchFinished>());
    expect(result.progress.done, lessThan(12));
  });

  test('starting while a run is in progress joins that run', () async {
    final first = service.start();
    final second = service.start();
    expect(identical(await first, await second), isTrue);
    expect(api.calls.length, 12);
  });

  test('a full disk ends the run as storageFull, not as a generic abort',
      () async {
    final full =
        PrefetchService(db: db, repo: _FullDiskRepository(api: api, db: db));
    final result = await full.start() as PrefetchFinished;
    expect(result.outcome, PrefetchOutcome.storageFull);
    expect(result.progress.done, 0);
    expect(await savedCount(), 0);
  });

  group('keeps the screen on only while a run is in progress', () {
    late List<bool> screen;
    late PrefetchService withScreen;
    setUp(() {
      screen = [];
      withScreen = PrefetchService(
          db: db,
          repo: LawRepository(api: api, db: db),
          keepScreenOn: (on) async => screen.add(on));
    });

    test('for a completed run', () async {
      await withScreen.start();
      expect(screen, [true, false]);
    });

    test('for a cancelled run', () async {
      withScreen.state.addListener(() {
        if (withScreen.state.value is PrefetchRunning) withScreen.cancel();
      });
      await withScreen.start();
      expect(screen, [true, false]);
    });

    test('for an aborted run', () async {
      final broken = (await db.getLaw('340AC0000000034'))!.currentRevisionId!;
      api.onPath('/api/2/law_data/$broken', (_) => throw StateError('boom'));
      final result = await withScreen.start() as PrefetchFinished;
      expect(result.outcome, PrefetchOutcome.aborted);
      expect(screen, [true, false]);
    });

    test('a wakelock that fails does not stop the run', () async {
      final fragile = PrefetchService(
          db: db,
          repo: LawRepository(api: api, db: db),
          keepScreenOn: (_) async => throw UnsupportedError('no wakelock'));
      final result = await fragile.start() as PrefetchFinished;
      expect(result.outcome, PrefetchOutcome.completed);
      expect(result.progress.done, 12);
    });
  });
}
