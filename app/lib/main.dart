import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    // 既定の自動再試行（失敗した Provider を最大 10 回）を切るのは、通信失敗の扱い
    // （オフライン / e-Gov 側 / データ異常）を Repository で種類ごとに決めていて、
    // その裏で e-Gov に同じ要求を繰り返させないため
    retry: (_, __) => null,
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const ZeibunApp(),
  ));
}
