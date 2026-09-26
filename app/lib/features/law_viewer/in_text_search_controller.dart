import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'in_text_search.dart';
import 'law_text.dart';

/// LawPage の State に持たせないのは、描画・スクロール・検索の遷移が 1 クラスに
/// 集まって 300 行を超え、遷移だけを試せなくなったため。null は検索バーが閉じている
/// 状態で、開閉フラグを別に持たない。
class InTextSearchController extends Notifier<InTextSearch?> {
  InTextSearchController(this.lawId);

  final String lawId;

  @override
  InTextSearch? build() => null;

  bool get isOpen => state != null;

  void toggle() => state = state == null ? const InTextSearch() : null;

  /// 検索して新しい状態を返す。返すのは、画面が現在の一致へスクロールするか
  /// どうかを呼び出しごとに決めるため（初回クエリでは動かさない）。
  InTextSearch run(LawText text, String query,
          {required bool includeSuppl, int startAt = 0}) =>
      state = InTextSearch.run(text, query,
          includeSuppl: includeSuppl, startAt: startAt);

  InTextSearch? step(int delta) {
    final s = state;
    if (s == null || s.hits.isEmpty) return null;
    return state = s.step(delta);
  }
}

/// autoDispose なのは、画面を離れたら検索語と一致位置を残さないため。
final inTextSearchProvider = NotifierProvider.autoDispose
    .family<InTextSearchController, InTextSearch?, String>(
        InTextSearchController.new);
