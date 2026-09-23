import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/law_repository.dart';
import '../../providers.dart';

/// 開いている法令の本文（設計書 §4.2 a〜b）。
///
/// 初回は前回の設定（改正附則を含むか）を引き継いで開き、
/// [loadAmendSuppl] で全文（改正附則込み）に切り替える。
class LawBodyController extends FamilyAsyncNotifier<BodyLoadResult, String> {
  /// 取得できる状況では古いキャッシュを先に出さない。読み始めた条文が途中で
  /// 差し替わるより、スケルトンで 1〜2 秒待ってもらう方が誤読が起きないため。
  /// キャッシュが現行と一致していれば通信せず即表示、取得に失敗したときだけ
  /// 古いキャッシュを注記付きで出す（[LawRepository.openLaw]）。
  @override
  Future<BodyLoadResult> build(String arg) =>
      ref.read(lawRepositoryProvider).openLaw(arg);

  Future<void> loadAmendSuppl() async {
    state = const AsyncLoading<BodyLoadResult>().copyWithPrevious(state);
    state = await AsyncValue.guard(() =>
        ref.read(lawRepositoryProvider).openLaw(arg, includeAmendSuppl: true));
  }

  Future<void> refresh() async {
    state = const AsyncLoading<BodyLoadResult>().copyWithPrevious(state);
    state = await AsyncValue.guard(
        () => ref.read(lawRepositoryProvider).openLaw(arg, force: true));
  }
}

final lawBodyProvider =
    AsyncNotifierProvider.family<LawBodyController, BodyLoadResult, String>(
        LawBodyController.new);
