import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeibun/app.dart';
import 'package:zeibun/data/egov/egov_api.dart';
import 'package:zeibun/features/settings/settings_controller.dart';
import 'package:zeibun/providers.dart';

import 'support/fake_egov_api.dart';

/// App Review で起きた状況（新規インストール直後に e-Gov がメンテナンス中）。
void main() {
  testWidgets(
      'a fresh install opened while e-Gov is under maintenance still lists '
      'the laws and says why it could not update', (tester) async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    final api = FakeEgovApi()
      ..onPathPrefix(
          '/api/2/',
          (u) => throw EgovApiException(EgovErrorKind.maintenance, u,
              statusCode: 403));
    SharedPreferences.setMockInitialValues({'disclaimer_shown_v1': true});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      egovApiProvider.overrideWithValue(api),
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const ZeibunApp()));
    for (var i = 0;
        i < 50 && find.textContaining('メンテナンス中').evaluate().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('e-Gov 法令検索がメンテナンス中'), findsOneWidget);
    expect(find.text('法人税法'), findsWidgets);
    expect(await tester.runAsync(() async => (await db.allLaws()).length),
        greaterThan(300));
  });
}
