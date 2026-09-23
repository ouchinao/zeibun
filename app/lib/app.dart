import 'package:flutter/material.dart';
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
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1F4E79));
    return MaterialApp.router(
      title: 'zeibun',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      routerConfig: router,
    );
  }
}
