import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeibun/app.dart';
import 'package:zeibun/data/db/database.dart';
import 'package:zeibun/data/repositories/sync_service.dart';
import 'package:zeibun/features/law_viewer/law_node_renderer.dart';
import 'package:zeibun/providers.dart';
import 'package:zeibun_core/zeibun_core.dart';

import 'support/fake_egov_api.dart';

/// 画面のスモークテスト。DB と同期のロジックは sync_service_test 等で検証済みなので、
/// ここでは Provider を差し替えて（drift のストリームを使わずに）描画だけを見る。
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  Widget app({
    required List<Law> laws,
    required ValueNotifier<SyncState> sync,
  }) =>
      ProviderScope(
        overrides: [
          egovApiProvider.overrideWithValue(FakeEgovApi()),
          lawsStreamProvider.overrideWith((ref) => Stream.value(laws)),
          recentLawsProvider.overrideWith((ref) async => const []),
          syncStateListenableProvider.overrideWithValue(sync),
        ],
        child: const ZeibunApp(runSyncOnLaunch: false),
      );

  testWidgets('first launch shows the disclaimer dialog once', (tester) async {
    await tester
        .pumpWidget(app(laws: const [], sync: ValueNotifier(const SyncIdle())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ご利用にあたって'), findsOneWidget);
    await tester.tap(find.text('確認しました'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ご利用にあたって'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('disclaimer_shown_v1'), isTrue);
  });

  testWidgets('home renders with an empty catalog and the footer disclaimer',
      (tester) async {
    SharedPreferences.setMockInitialValues({'disclaimer_shown_v1': true});
    await tester
        .pumpWidget(app(laws: const [], sync: ValueNotifier(const SyncIdle())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ご利用にあたって'), findsNothing);
    expect(find.text('zeibun 税法検索'), findsOneWidget);
    expect(find.textContaining('公式アプリではありません'), findsOneWidget);
    expect(find.text('法令一覧'), findsOneWidget);
    expect(find.text('同期待ち'), findsOneWidget);
  });

  testWidgets('sync banner and major-law shortcuts reflect state',
      (tester) async {
    SharedPreferences.setMockInitialValues({'disclaimer_shown_v1': true});
    final sync = ValueNotifier<SyncState>(const SyncChecking());
    await tester.pumpWidget(app(
      laws: [
        law('340AC0000000034', '法人税法', pending: 'x', body: 'old'),
        law('340AC0000000033', '所得税法'),
      ],
      sync: sync,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('法令一覧を確認中…'), findsOneWidget);
    expect(find.text('法人税法'), findsWidgets);
    expect(find.text('所得税法'), findsWidgets);

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
  });

  testWidgets('LawNodeRenderer renders a real article with highlight',
      (tester) async {
    final lawNode =
        LawNode.parseXmlString(fixture('law_data_426AC0000000011_地方法人税法.xml'));
    final article = const LawParser().parse(lawNode).first;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LawNodeRenderer(article.body, highlight: '地方法人税'),
        ),
      ),
    ));
    expect(find.textContaining('第一条'), findsOneWidget);
    expect(find.textContaining('地方法人税'), findsWidgets);
    expect(find.textContaining('<Rt>'), findsNothing);
  });
}
