import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import 'law_text.dart';

/// 開いている法令の本文（設計書 §4.2 a〜b）。
///
/// 初回は前回の設定（改正附則を含むか）を引き継いで開き、
/// [loadAmendSuppl] で全文（改正附則込み）に切り替える。
class LawBodyController extends AsyncNotifier<LawText> {
  LawBodyController(this.lawId);

  final String lawId;

  /// 取得できる状況では古いキャッシュを先に出さない。読み始めた条文が途中で
  /// 差し替わるより、スケルトンで 1〜2 秒待ってもらう方が誤読が起きないため。
  /// キャッシュが現行と一致していれば通信せず即表示、取得に失敗したときだけ
  /// 古いキャッシュを注記付きで出す（`LawRepository.openLaw`）。
  @override
  Future<LawText> build() async =>
      LawText.from(await ref.read(lawRepositoryProvider).openLaw(lawId));

  Future<void> loadAmendSuppl() =>
      _reload(includeAmendSuppl: true, force: false);

  Future<void> refresh() => _reload(includeAmendSuppl: null, force: true);

  /// 読み込み中の再要求は無視する。ボタン連打で同じ 16MB を並行して取らないため。
  Future<void> _reload(
      {required bool? includeAmendSuppl, required bool force}) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => LawText.from(await ref
        .read(lawRepositoryProvider)
        .openLaw(lawId, includeAmendSuppl: includeAmendSuppl, force: force)));
  }
}

/// autoDispose なのは、画面を離れたら本文をメモリに残さず、次に開いたときに
/// 一覧側のリビジョンとキャッシュを比べ直すため（keep-alive だと改正後の再取得も
/// 「保存した本文を削除」の反映も起きない）。
final lawBodyProvider = AsyncNotifierProvider.autoDispose
    .family<LawBodyController, LawText, String>(LawBodyController.new);
