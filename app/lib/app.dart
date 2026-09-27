import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/settings/settings_controller.dart';
import 'providers.dart';
import 'router.dart';

class ZeibunApp extends ConsumerStatefulWidget {
  const ZeibunApp({super.key, this.runSyncOnLaunch = true});

  /// テストでは起動時同期を止める。
  final bool runSyncOnLaunch;

  @override
  ConsumerState<ZeibunApp> createState() => _ZeibunAppState();
}

class _ZeibunAppState extends ConsumerState<ZeibunApp> {
  @override
  void initState() {
    super.initState();
    if (widget.runSyncOnLaunch) {
      // 画面表示をブロックしない（設計書 §4.1）
      Future.microtask(() => ref
          .read(syncServiceProvider)
          .runOnLaunch(skipRecent: ref.read(settingsProvider).skipRecentSync));
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    const seed = Color(0xFF1F4E79);
    ThemeData themeOf(Brightness b, {double contrast = 0}) => ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: seed, brightness: b, contrastLevel: contrast),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: false),
        );
    return MaterialApp.router(
      title: 'zeibun',
      debugShowCheckedModeBanner: false,
      // 暗い配色も用意するのは、端末をダークモードや色反転にしている人に白い
      // 全面を出さないため（光に敏感な人には明るい全面がつらい）
      theme: themeOf(Brightness.light),
      darkTheme: themeOf(Brightness.dark),
      // 通常の配色で済ませないのは、「コントラストを上げる」を選ぶ人には標準の差でも読みにくいため
      highContrastTheme: themeOf(Brightness.light, contrast: 1),
      highContrastDarkTheme: themeOf(Brightness.dark, contrast: 1),
      // 日本語に固定するのは、既定の英語のままだと「戻る」などの部品の文言が
      // 英語になり、Flutter 3.38 以降は読み上げの声も英語になるため
      locale: const Locale('ja', 'JP'),
      supportedLocales: const [Locale('ja', 'JP')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    );
  }
}
