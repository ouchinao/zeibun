import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeibun/app.dart';
import 'package:zeibun/data/db/database.dart';
import 'package:zeibun/data/repositories/sync_service.dart';
import 'package:zeibun/features/bookmarks/bookmark_providers.dart';
import 'package:zeibun/features/law_viewer/law_node_renderer.dart';
import 'package:zeibun/features/settings/settings_controller.dart';
import 'package:zeibun/providers.dart';
import 'package:zeibun_core/zeibun_core.dart';

import 'support/fake_egov_api.dart';

/// 画面のスモークテスト。DB と同期のロジックは sync_service_test 等で検証済みなので、
/// ここでは Provider を差し替えて（drift のストリームを使わずに）描画だけを見る。
void main() {
  Law law(String id, String title, {String? pending, String? body}) => Law(
        lawId: id,
        lawNum: '',
        lawType: 'Act',
        title: title,
        category: '国税',
        repealStatus: 'None',
        scopeReason: 'category:013',
        currentRevisionId: '${id}_20260401_000000000000000',
        pendingRevisionId: pending,
        bodyRevisionId: body,
        bodyIncludesAmendSuppl: false,
      );

  Future<Widget> app({
    required List<Law> laws,
    required ValueNotifier<SyncState> sync,
    bool disclaimerShown = true,
    List<BookmarkEntry> bookmarks = const [],
  }) async {
    SharedPreferences.setMockInitialValues(
        {if (disclaimerShown) 'disclaimer_shown_v1': true});
    final prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        egovApiProvider.overrideWithValue(FakeEgovApi()),
        lawsStreamProvider.overrideWith((ref) => Stream.value(laws)),
        bookmarksProvider.overrideWith((ref) => Stream.value(bookmarks)),
        syncStateListenableProvider.overrideWithValue(sync),
      ],
      child: const ZeibunApp(runSyncOnLaunch: false),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('first launch shows the disclaimer dialog once', (tester) async {
    await tester.pumpWidget(await app(
        laws: const [],
        sync: ValueNotifier(const SyncIdle()),
        disclaimerShown: false));
    await settle(tester);
    expect(find.text('ご利用にあたって'), findsOneWidget);
    await tester.tap(find.text('確認しました'));
    await settle(tester);
    expect(find.text('ご利用にあたって'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('disclaimer_shown_v1'), isTrue);
  });

  testWidgets('home renders with an empty catalog and the footer disclaimer',
      (tester) async {
    await tester.pumpWidget(
        await app(laws: const [], sync: ValueNotifier(const SyncIdle())));
    await settle(tester);
    expect(find.text('ご利用にあたって'), findsNothing);
    expect(find.text('zeibun 税法検索'), findsOneWidget);
    expect(find.textContaining('公式アプリではありません'), findsOneWidget);
    expect(find.text('法令一覧'), findsOneWidget);
    expect(find.text('同期待ち'), findsOneWidget);
  });

  testWidgets('sync banner and major-law shortcuts reflect state',
      (tester) async {
    final sync = ValueNotifier<SyncState>(const SyncChecking());
    await tester.pumpWidget(await app(
      laws: [
        law('340AC0000000034', '法人税法', pending: 'x', body: 'old'),
        law('340AC0000000033', '所得税法'),
      ],
      sync: sync,
    ));
    await settle(tester);
    expect(find.text('法令一覧を確認中…'), findsOneWidget);
    expect(find.text('法人税法'), findsWidgets);
    expect(find.text('所得税法'), findsWidgets);
    // 本文が古い法人税法には「更新あり」のアイコン
    expect(find.byIcon(Icons.update), findsOneWidget);

    sync.value = SyncSuccess(
        at: DateTime(2026, 9, 23, 9, 12),
        revised: 3,
        pending: 55,
        checked: 300);
    await tester.pump();
    expect(find.textContaining('改正あり 3 件'), findsOneWidget);
    expect(find.textContaining('施行予定あり 55 件'), findsOneWidget);

    sync.value = const SyncOffline(null);
    await tester.pump();
    expect(find.textContaining('オフライン'), findsOneWidget);

    sync.value = const SyncBackingOff(3, null);
    await tester.pump();
    expect(find.textContaining('連続 3 回失敗'), findsOneWidget);
  });

  testWidgets('home lists bookmarks with the article title when known',
      (tester) async {
    await tester.pumpWidget(await app(
      laws: const [],
      sync: ValueNotifier(const SyncIdle()),
      bookmarks: const [
        BookmarkEntry(
            id: 1,
            lawId: '340AC0000000034',
            lawTitle: '法人税法',
            createdAt: '2026-09-23T12:00:00',
            articleNum: '22',
            articleTitle: '第二十二条',
            caption: '（各事業年度の所得の金額の計算の通則）'),
        BookmarkEntry(
            id: 2,
            lawId: '426AC0000000011',
            lawTitle: '地方法人税法',
            createdAt: '2026-09-23T11:00:00',
            articleNum: '66_4'),
      ],
    ));
    await settle(tester);
    expect(find.text('法人税法 第二十二条'), findsOneWidget);
    expect(find.text('地方法人税法 第66条の4'), findsOneWidget);
  });

  testWidgets('LawNodeRenderer renders a real article with highlight',
      (tester) async {
    final lawNode =
        LawNode.parseXmlString(fixture('law_data_426AC0000000011_地方法人税法.xml'));
    final article = const LawParser().parse(lawNode).first;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LawNodeRenderer(article.body, highlight: const ['地方法人税']),
        ),
      ),
    ));
    expect(find.textContaining('第一条'), findsOneWidget);
    expect(find.textContaining('地方法人税'), findsWidgets);
    expect(find.textContaining('<Rt>'), findsNothing);
  });
}
