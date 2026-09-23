import 'package:flutter_test/flutter_test.dart';
import 'package:zeibun/data/db/database.dart';
import 'package:zeibun/data/repositories/law_repository.dart';
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
    search =
        SearchRepository(db: db, abbrevs: abbrevIndexFor(await db.allLaws()));
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

  test('LIKE wildcards in the input are not interpreted', () async {
    expect(await search.search('%'), isEmpty);
    expect(await search.search('_'), isEmpty);
  });

  group('full-text search over cached bodies', () {
    const chihou = '426AC0000000011'; // 地方法人税法

    setUp(() async {
      final api = FakeEgovApi()
        ..onPath('/api/2/laws', catalogHandler())
        ..onPath(
            '/api/2/law_data/${(await db.getLaw(chihou))!.currentRevisionId}',
            (uri) => fixture('law_data_426AC0000000011_地方法人税法.xml').replaceFirst(
                RegExp('<law_revision_id>[^<]+</law_revision_id>'),
                '<law_revision_id>${uri.pathSegments.last}</law_revision_id>'));
      await LawRepository(api: api, db: db).openLaw(chihou);
    });

    test('a term of 3+ characters is found through the index with a snippet',
        () async {
      final r = await search.searchFullText('課税標準');
      expect(r.hits, isNotEmpty);
      expect(r.hits.first.lawTitle, '地方法人税法');
      expect(r.hits.first.snippet, contains('課税標準'));
      expect(r.hits.every((h) => h.section != 'suppl'), isTrue);
      expect(r.laws.single.lawId, chihou);
      expect(r.laws.single.count, r.hits.length);
    });

    test('a term shorter than 3 characters still finds articles (LIKE)',
        () async {
      final r = await search.searchFullText('税率');
      expect(r.hits, isNotEmpty);
      expect(r.hits.first.snippet, contains('税率'));
    });

    test('all terms must appear in the same article', () async {
      final both = await search.searchFullText('課税標準 税率');
      final one = await search.searchFullText('課税標準');
      expect(both.hits.length, lessThan(one.hits.length));
      expect(both.hits, isNotEmpty);
    });

    test('supplementary provisions are searched only when asked', () async {
      final main = await search.searchFullText('この法律');
      final all = await search.searchFullText('この法律', includeSuppl: true);
      expect(main.hits.any((h) => h.section == 'suppl'), isFalse);
      expect(all.hits.any((h) => h.section == 'suppl'), isTrue);
    });

    test('filtering by law keeps the per-law counts of the whole result',
        () async {
      final r = await search.searchFullText('課税標準', lawId: '340AC0000000034');
      expect(r.hits, isEmpty);
      expect(r.laws.single.lawId, chihou);
    });

    test('FTS5 operators in the input are treated as plain words', () async {
      expect((await search.searchFullText('課税標準 NOT')).hits, isEmpty);
      expect((await search.searchFullText('OR')).hits, isEmpty);
      expect((await search.searchFullText('"課税')).hits, isEmpty);
    });
  });
}
