import 'package:flutter_test/flutter_test.dart';
import 'package:zeibun/data/db/database.dart';
import 'package:zeibun/data/repositories/bookmark_repository.dart';
import 'package:zeibun/data/repositories/law_repository.dart';
import 'package:zeibun/data/services/sync_service.dart';

import 'support/fake_egov_api.dart';

void main() {
  late AppDatabase db;
  late FakeEgovApi api;
  late BookmarkRepository bookmarks;
  const chihou = '426AC0000000011'; // 地方法人税法
  const houjin = '340AC0000000034'; // 法人税法
  var now = DateTime(2026, 9, 23, 12, 0);

  setUp(() async {
    db = inMemoryDatabase();
    now = DateTime(2026, 9, 23, 12, 0);
    api = FakeEgovApi()
      ..onPath('/api/2/laws', catalogHandler())
      ..onPathPrefix('/api/2/law_data/', lawDataHandler());
    await SyncService(api: api, db: db, clock: () => now).runOnLaunch();
    bookmarks = BookmarkRepository(db: db, clock: () => now);
  });

  tearDown(() => db.close());

  test('toggling adds a bookmark and toggling again removes it', () async {
    expect(await bookmarks.toggle(chihou, articleNum: '1'), isTrue);
    expect(await bookmarks.watchIsBookmarked(chihou, articleNum: '1').first,
        isTrue);
    expect(await bookmarks.toggle(chihou, articleNum: '1'), isFalse);
    expect(await bookmarks.watchIsBookmarked(chihou, articleNum: '1').first,
        isFalse);
    expect(await bookmarks.watchAll().first, isEmpty);
  });

  test('a law bookmark and an article bookmark of the same law are separate',
      () async {
    await bookmarks.toggle(chihou);
    await bookmarks.toggle(chihou, articleNum: '1');
    expect(await bookmarks.watchIsBookmarked(chihou).first, isTrue);
    expect(await bookmarks.watchIsBookmarked(chihou, articleNum: '1').first,
        isTrue);
    await bookmarks.toggle(chihou);
    expect(await bookmarks.watchIsBookmarked(chihou).first, isFalse);
    expect(await bookmarks.watchIsBookmarked(chihou, articleNum: '1').first,
        isTrue);
  });

  test(
      'the list carries the law title, and the article title once the body '
      'is cached', () async {
    await bookmarks.toggle(houjin, articleNum: '22'); // 本文なし
    now = now.add(const Duration(minutes: 1));
    await bookmarks.toggle(chihou, articleNum: '1');
    await LawRepository(api: api, db: db, clock: () => now).openLaw(chihou);

    final rows = await bookmarks.watchAll().first;
    expect(rows.map((b) => b.lawId), [chihou, houjin], reason: '新しい順');
    final withBody = rows.first;
    expect(withBody.lawTitle, '地方法人税法');
    expect(withBody.articleTitle, '第一条');
    expect(withBody.caption, isNotNull);
    final withoutBody = rows.last;
    expect(withoutBody.lawTitle, '法人税法');
    expect(withoutBody.articleTitle, isNull);
  });

  test('removing by id and the list stream reflect each other', () async {
    await bookmarks.toggle(chihou);
    final id = (await bookmarks.watchAll().first).single.id;
    await bookmarks.remove(id);
    expect(await bookmarks.watchAll().first, isEmpty);
  });
}
