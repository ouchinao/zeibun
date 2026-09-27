import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeibun/app.dart';
import 'package:zeibun/data/db/database.dart';
import 'package:zeibun/data/services/sync_service.dart';
import 'package:zeibun/features/settings/settings_controller.dart';
import 'package:zeibun/data/repositories/bookmark_repository.dart';
import 'package:zeibun/providers.dart';
import 'package:zeibun/router.dart';

import 'support/fake_egov_api.dart';

/// Flutter 標準のアクセシビリティ・ガイドライン（タップ領域 48dp / 44pt、
/// タップ対象のラベル、文字のコントラスト比 4.5:1）と、文字サイズ 200% での
/// はみ出しを、主要な画面ごとに確かめる。
void main() {
  late AppDatabase db;
  late FakeEgovApi api;
  late ProviderContainer container;

  setUp(() async {
    db = inMemoryDatabase();
    api = FakeEgovApi()
      ..onPath('/api/2/laws', catalogHandler())
      ..onPathPrefix('/api/2/law_data/', lawDataHandler());
    await SyncService(api: api, db: db).runOnLaunch();
    SharedPreferences.setMockInitialValues({'disclaimer_shown_v1': true});
    PackageInfo.setMockInitialValues(
        appName: 'zeibun',
        packageName: 'io.github.ouchinao.zeibun',
        version: '0.1.0',
        buildNumber: '1',
        buildSignature: '');
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      egovApiProvider.overrideWithValue(api),
      databaseProvider.overrideWithValue(db),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// 読み込み表示が消えるまで待つ。固定時間だけ待たないのは、本文のパースが
  /// `compute`（別 isolate）で実時間を使い、遅い CI では終わらないことがあるため。
  Future<void> pumpAWhile(WidgetTester tester) async {
    bool loading() =>
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
        find.byType(LinearProgressIndicator).evaluate().isNotEmpty ||
        find.text('最新の条文を取得しています…').evaluate().isNotEmpty;
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
      if (i >= 2 && !loading()) {
        // 画面遷移のアニメーション途中の色でコントラストを測らないよう、終わるまで進める
        await tester.pump(const Duration(seconds: 1));
        return;
      }
    }
    fail('10 秒待っても読み込みが終わらなかった');
  }

  Future<void> open(WidgetTester tester, String location) async {
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const ZeibunApp(runSyncOnLaunch: false)));
    await tester.pump();
    container.read(routerProvider).go(location);
    await pumpAWhile(tester);
  }

  List<Object> exceptions(WidgetTester tester) {
    final out = <Object>[];
    while (true) {
      final e = tester.takeException();
      if (e == null) return out;
      out.add(e);
    }
  }

  /// 4 つの基準をすべて評価し、違反をまとめて返す（最初の 1 件で止めない）。
  Future<List<String>> violations(WidgetTester tester) async {
    final found = <String>[];
    for (final g in [
      androidTapTargetGuideline,
      iOSTapTargetGuideline,
      labeledTapTargetGuideline,
      textContrastGuideline,
    ]) {
      final r = await g.evaluate(tester);
      if (!r.passed) found.add('${g.description}: ${r.reason}');
    }
    return found;
  }

  final screens = <String, (String, Future<void> Function(WidgetTester)?)>{
    'home': ('/', null),
    'law list': ('/laws', null),
    'search results': ('/search?q=法人', null),
    'law page': (
      '/law/426AC0000000011',
      (tester) async {
        expect(find.textContaining('第一条'), findsWidgets, reason: '本文が描かれていること');
      }
    ),
    'law page with in-text search open': (
      '/law/426AC0000000011',
      (tester) async {
        await tester.tap(find.byTooltip('本文内検索'));
        await pumpAWhile(tester);
        await tester.enterText(find.byType(TextField).last, '法人');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await pumpAWhile(tester);
      }
    ),
    'settings': ('/settings', null),
    'prefetch': ('/settings/prefetch', null),
  };

  screens.forEach((name, screen) {
    final (location, prepare) = screen;

    testWidgets('$name meets the tap target, label and contrast guidelines',
        (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester, location);
      await prepare?.call(tester);
      expect(exceptions(tester), isEmpty);
      expect(await violations(tester), isEmpty);
      handle.dispose();
    });

    testWidgets('$name keeps text contrast in dark mode', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final handle = tester.ensureSemantics();
      await open(tester, location);
      await prepare?.call(tester);
      expect(exceptions(tester), isEmpty);
      expect(await violations(tester), isEmpty);
      handle.dispose();
    });

    testWidgets('$name lays out at 200% text scale without overflowing',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester, location);
      await prepare?.call(tester);
      expect(exceptions(tester), isEmpty);
    });
  });

  testWidgets('at 300% text the in-text search bar sits above the tabs',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 3.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, '/law/426AC0000000011');
    await screens['law page with in-text search open']!.$2!(tester);
    final field = tester.getRect(find.byType(TextField).last);
    final tabs = tester.getRect(find.byType(TabBar));
    expect(field.bottom, lessThanOrEqualTo(tabs.top));
    expect(exceptions(tester), isEmpty);
  });

  testWidgets(
      'a screen reader can bookmark an article from its actions, '
      'without the long-press menu, once even if triggered twice',
      (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, '/law/426AC0000000011');
    final article = find.textContaining('第一条').first;
    // 条の本文は項ごとに読まれるので、アクションはその親（条）の節点にある
    SemanticsNode? node = tester.getSemantics(article);
    CustomSemanticsAction? action;
    while (node != null && action == null) {
      action = node
          .getSemanticsData()
          .customSemanticsActionIds
          ?.map(CustomSemanticsAction.getAction)
          .where((a) => a?.label == 'ブックマークに追加・外す')
          .firstOrNull;
      if (action == null) node = node.parent;
    }
    expect(action, isNotNull);
// 続けて 2 回実行しても、追加と解除が続けて走って元に戻らないこと
    for (var i = 0; i < 2; i++) {
      tester.binding.performSemanticsAction(SemanticsActionEvent(
          type: SemanticsAction.customAction,
          viewId: tester.view.viewId,
          nodeId: node!.id,
          arguments: CustomSemanticsAction.getIdentifier(action!)));
    }
    await pumpAWhile(tester);
    expect(find.text('ブックマークに追加しました'), findsOneWidget);
    expect(await db.bookmarkedLawIds(), contains('426AC0000000011'));
    handle.dispose();
  });

  testWidgets('built-in labels are Japanese, so they are not read in English',
      (tester) async {
    await open(tester, '/law/426AC0000000011');
    final ctx = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(ctx), const Locale('ja', 'JP'));
    expect(MaterialLocalizations.of(ctx).backButtonTooltip, '戻る');
  });

  testWidgets('article captions and chapter breadcrumbs are headings',
      (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, '/law/426AC0000000011');
    expect(tester.getSemantics(find.text('（趣旨）')), isSemantics(isHeader: true));
    expect(tester.getSemantics(find.text('第一章　総則').first),
        isSemantics(isHeader: true));
    handle.dispose();
  });

  Future<void> searchInLaw(WidgetTester tester, String term) async {
    await tester.tap(find.byTooltip('本文内検索'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField).last, term);
    await tester.testTextInput.receiveAction(TextInputAction.done);
  }

  testWidgets('searching and stepping announce the position to the reader',
      (tester) async {
    final announced = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
        SystemChannels.accessibility, (message) async {
      final m = message! as Map<Object?, Object?>;
      if (m['type'] == 'announce') {
        announced
            .add((m['data']! as Map<Object?, Object?>)['message']! as String);
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(
            SystemChannels.accessibility, null));
    await open(tester, '/law/426AC0000000011');
    await searchInLaw(tester, '法人');
    await pumpAWhile(tester);
    await tester.tap(find.byTooltip('次の一致へ'));
    await pumpAWhile(tester);
    expect(announced, hasLength(2));
    expect(announced.first, startsWith('1件目、全'));
    expect(announced.last, startsWith('2件目、全'));
  });

  testWidgets('with high contrast on, the law page still meets the guidelines',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(highContrast: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final handle = tester.ensureSemantics();
    await open(tester, '/law/426AC0000000011');
    await screens['law page with in-text search open']!.$2!(tester);
    expect(exceptions(tester), isEmpty);
    expect(await violations(tester), isEmpty);
    handle.dispose();
  });

  testWidgets(
      'removing a bookmark from home can be undone, '
      'keeping its original place in the list', (tester) async {
    await BookmarkRepository(db: db, clock: () => DateTime(2026, 9, 1))
        .toggle('426AC0000000011', articleNum: '1');
    await open(tester, '/');
    expect(find.textContaining('地方法人税法'), findsWidgets);
    await tester.tap(find.byTooltip('外す'));
    await pumpAWhile(tester);
    // DB の読み取りは偽の時計の外（実時間）で待つ。中で待つと進まない
    expect(await tester.runAsync(db.bookmarkedLawIds), isEmpty);
    await tester.tap(find.text('元に戻す'));
    await pumpAWhile(tester);
    final restored = (await tester.runAsync(() => db.watchBookmarks().first))!;
    expect(restored.single.articleNum, '1');
    expect(restored.single.createdAt, DateTime(2026, 9, 1).toIso8601String());
  });
}
