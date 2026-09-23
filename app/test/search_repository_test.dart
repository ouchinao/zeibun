import 'package:flutter_test/flutter_test.dart';
import 'package:zeibun/data/db/database.dart';
import 'package:zeibun/data/repositories/search_repository.dart';
import 'package:zeibun/data/repositories/sync_service.dart';

import 'support/fake_egov_api.dart';

void main() {
  late AppDatabase db;
  late SearchRepository search;

  setUp(() async {
    db = inMemoryDatabase();
    final api = FakeEgovApi()..onPath('/api/2/laws', catalogHandler());
    await SyncService(api: api, db: db).runOnLaunch();
    search = SearchRepository(db: db);
  });

  tearDown(() => db.close());

  test('partial title match, current laws first', () async {
    final hits = await search.search('税法');
    expect(hits.map((h) => h.law.title), contains('法人税法'));
    expect(hits.every((h) => h.article == null), isTrue);
  });

  test('practitioner abbreviation expands to the full title', () async {
    final hits = await search.search('法法');
    expect(hits.first.law.title, '法人税法');
  });

  test('API abbrev (租特法) is searchable', () async {
    final hits = await search.search('租特法');
    expect(hits.map((h) => h.law.title), contains('租税特別措置法'));
  });

  test('article reference yields jump hits with the exact law first', () async {
    final hits = await search.search('法法２２');
    expect(hits, isNotEmpty);
    expect(hits.first.law.title, '法人税法');
    expect(hits.first.article!.articleNum, '22');
    final branch = await search.search('措法42の12の5');
    expect(branch.first.law.title, '租税特別措置法');
    expect(branch.first.article!.articleNum, '42_12_5');
  });

  test('full-width and kana input', () async {
    expect((await search.search('しょうひぜい')).map((h) => h.law.title),
        contains('消費税法'));
    expect((await search.search('　所得税法　')).first.law.title, '所得税法');
    expect(await search.search(''), isEmpty);
  });
}
