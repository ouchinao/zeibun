import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `main()` で読み込んだインスタンスに差し替える。起動時に同期的に読めるようにして、
/// 「設定が読み終わる前に既定値で起動時同期を判断してしまう」競合を無くすため。
final sharedPreferencesProvider = Provider<SharedPreferences>(
    (_) => throw UnimplementedError('main() で overrideWithValue する'));

/// 設定（設計書 §8 設定画面）。
class AppSettings {
  const AppSettings({
    this.prefetchEnabled = false,
    this.skipRecentSync = true,
    this.disclaimerShown = false,
  });

  final bool prefetchEnabled;
  final bool skipRecentSync;
  final bool disclaimerShown;

  AppSettings copyWith({
    bool? prefetchEnabled,
    bool? skipRecentSync,
    bool? disclaimerShown,
  }) =>
      AppSettings(
        prefetchEnabled: prefetchEnabled ?? this.prefetchEnabled,
        skipRecentSync: skipRecentSync ?? this.skipRecentSync,
        disclaimerShown: disclaimerShown ?? this.disclaimerShown,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kPrefetch = 'prefetch_enabled';
  static const _kSkipRecent = 'skip_recent_sync';
  static const _kDisclaimer = 'disclaimer_shown_v1';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() => AppSettings(
        prefetchEnabled: _prefs.getBool(_kPrefetch) ?? false,
        skipRecentSync: _prefs.getBool(_kSkipRecent) ?? true,
        disclaimerShown: _prefs.getBool(_kDisclaimer) ?? false,
      );

  Future<void> setPrefetch(bool v) {
    state = state.copyWith(prefetchEnabled: v);
    return _prefs.setBool(_kPrefetch, v);
  }

  Future<void> setSkipRecentSync(bool v) {
    state = state.copyWith(skipRecentSync: v);
    return _prefs.setBool(_kSkipRecent, v);
  }

  Future<void> markDisclaimerShown() {
    state = state.copyWith(disclaimerShown: true);
    return _prefs.setBool(_kDisclaimer, true);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
