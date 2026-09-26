import 'dart:convert';

import 'package:zeibun_core/zeibun_core.dart';

import '../../data/db/database.dart';
import '../../data/repositories/law_repository.dart';

/// 画面用の条。保存形式（`body_json`）の復元をここに閉じ込め、描画された条だけ復元する。
/// 1,348 条（地方税法）を開くたびに全条を復元すると数秒かかるため。
class ArticleItem {
  ArticleItem(this._row);
  final Article _row;

  ArticleSection get section => _row.sectionKind;
  String? get articleNum => _row.articleNum;
  String? get articleTitle => _row.articleTitle;
  String? get caption => _row.caption;
  String? get breadcrumb => _row.breadcrumb;
  String get plainText => _row.plainText;

  late final LawNode body =
      LawNode.fromJson(jsonDecode(_row.bodyJson) as Map<String, dynamic>);
}

/// [amendLawNum] が null なら制定時の附則。
class SupplGroup {
  const SupplGroup(this.amendLawNum, this.articles);
  final String? amendLawNum;
  final List<ArticleItem> articles;
}

/// 取得結果（DB 行）をそのまま画面に渡さないのは、附則のグループ化と JSON の
/// 復元を build のたびにやり直さないため。
class LawText {
  LawText._({
    required this.status,
    required this.failure,
    required this.main,
    required this.supplGroups,
  });

  factory LawText.from(BodyLoadResult r) {
    final main = <ArticleItem>[];
    final suppl = <String?, List<ArticleItem>>{};
    for (final a in r.articles) {
      final item = ArticleItem(a);
      if (a.sectionKind == ArticleSection.suppl) {
        suppl.putIfAbsent(a.supplAmendLawNum, () => []).add(item);
      } else {
        main.add(item);
      }
    }
    // XML の順（制定時 → 古い改正 → 新しい改正）のまま出さないのは、読みたいのは
    // ほぼ直近の改正の施行期日・経過措置だから
    final amendNums = suppl.keys.nonNulls.toList().reversed;
    return LawText._(
      status: r.status,
      failure: r.failure,
      main: main,
      supplGroups: [
        for (final k in amendNums) SupplGroup(k, suppl[k]!),
        if (suppl[null] case final original?) SupplGroup(null, original),
      ],
    );
  }

  final BodyStatus status;
  final FetchFailure? failure;

  /// 附則を含めないのは、条番号ジャンプ・目次・本文内検索が本則と別表を対象にするため。
  final List<ArticleItem> main;
  final List<SupplGroup> supplGroups;

  bool get hasSuppl => supplGroups.isNotEmpty;
}
