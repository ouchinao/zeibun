import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:zeibun/app.dart';
import 'package:zeibun/features/settings/settings_controller.dart';
import 'package:zeibun/providers.dart';
import 'package:zeibun/router.dart';

import 'support/fake_egov_api.dart';

/// ブラウザを開かず、開こうとした URL を記録する。
class _RecordingLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final launched = <String>[];

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}

void main() {
  late _RecordingLauncher launcher;
  late ProviderContainer container;

  setUp(() async {
    launcher = _RecordingLauncher();
    UrlLauncherPlatform.instance = launcher;
    SharedPreferences.setMockInitialValues({'disclaimer_shown_v1': true});
    PackageInfo.setMockInitialValues(
        appName: 'zeibun',
        packageName: 'io.github.ouchinao.zeibun',
        version: '1.0.0',
        buildNumber: '4',
        buildSignature: '');
    final db = inMemoryDatabase();
    addTearDown(db.close);
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider
          .overrideWithValue(await SharedPreferences.getInstance()),
      egovApiProvider.overrideWithValue(FakeEgovApi()),
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
  });

  Future<void> tapInSettings(WidgetTester tester, String label) async {
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const ZeibunApp(runSyncOnLaunch: false)));
    container.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(label), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('settings opens the support page in the browser', (tester) async {
    await tapInSettings(tester, 'サポート・お問い合わせ');
    expect(launcher.launched, ['https://ouchinao.github.io/zeibun/support']);
  });

  testWidgets('settings opens the privacy policy in the browser',
      (tester) async {
    await tapInSettings(tester, 'プライバシーポリシー');
    expect(launcher.launched, ['https://ouchinao.github.io/zeibun/privacy']);
  });
}
