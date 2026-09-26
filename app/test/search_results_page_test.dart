import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeibun/data/db/database.dart';
import 'package:zeibun/data/repositories/law_repository.dart';
import 'package:zeibun/data/repositories/search_repository.dart';
import 'package:zeibun/data/services/sync_service.dart';
import 'package:zeibun/features/search/search_results_page.dart';
import 'package:zeibun/providers.dart';
import 'package:zeibun_core/zeibun_core.dart';

import 'support/fake_egov_api.dart';

/// 条文の語で検索したとき、先に見える法令タブが「ヒット無し」に見えないことを
/// 確かめる。DB は実物（メモリ上）で、本文は 地方法人税法 だけ保存する。
void main() {
  late AppDatabase db;

  setUp(() async {
    db = inMemoryDatabase();
    final api = FakeEgovApi()
      ..onPath('/api/2/laws', catalogHandler())
      ..onPathPrefix('/api/2/law_data/', lawDataHandler());
    await SyncService(api: api, db: db).runOnLaunch();
    await LawRepository(api: api, db: db).openLaw('426AC0000000011');
  });

  tearDown(() => db.close());

  Future<void> pumpPage(WidgetTester tester, String query) async {
    final search =
        SearchRepository(db: db, abbrevs: abbrevIndexFor(await db.allLaws()));
    await tester.pumpWidget(ProviderScope(
      overrides: [searchRepositoryProvider.overrideWithValue(search)],
      child: MaterialApp(home: SearchResultsPage(query: query)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('law tab points to the full-text hits when no law title matches',
      (tester) async {
    await pumpPage(tester, '課税標準');
    final expected = (await db.fullTextLawCounts(FtsQuery.parse('課税標準')))
        .fold(0, (n, l) => n + l.count);
    expect(expected, greaterThan(0));
    expect(
        find.text('該当する法令がありません。\n本文タブに $expected 件の条文があります。'), findsOneWidget);
    expect(find.textContaining('同期状態'), findsNothing);

    await tester.tap(find.text('本文タブを開く'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('地方法人税法'), findsWidgets);
  });

  testWidgets('law tab keeps the sync hint when nothing matches anywhere',
      (tester) async {
    await pumpPage(tester, '存在しない語句');
    expect(find.textContaining('同期状態を確認してください'), findsOneWidget);
    expect(find.text('本文タブを開く'), findsNothing);
  });
}
