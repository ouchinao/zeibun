import 'package:zeibun_core/zeibun_core.dart';

import '../db/database.dart';

/// 検索結果の 1 件。法令名検索と条番号ジャンプを 1 つの窓で扱う（設計書 §6.1）。
class SearchHit {
  const SearchHit(this.law, {this.article});
  final Law law;

  /// 条番号ジャンプのとき、飛び先の条番号（`Article@Num` 形式）。
  final ArticleReference? article;
}

class SearchRepository {
  SearchRepository({required this.db, LawAbbrevIndex? abbrevs})
      : _builtin = abbrevs ?? LawAbbrevIndex();

  final AppDatabase db;
  final LawAbbrevIndex _builtin;
  LawAbbrevIndex? _merged;

  /// API の略称（`laws.abbrev`）を取り込んだ索引。
  Future<LawAbbrevIndex> _index() async {
    if (_merged != null) return _merged!;
    final rows = await db.allLaws();
    _merged = _builtin.withApiAbbrevs([
      for (final r in rows)
        if (r.abbrev != null && r.abbrev!.isNotEmpty)
          MapEntry(r.abbrev!, r.title),
    ]);
    return _merged!;
  }

  void invalidate() => _merged = null;

  /// 入力を解釈して検索する。
  /// 1. 条番号を含めば「法令 + 条」のジャンプ候補
  /// 2. それ以外は法令名・略称・読みの部分一致
  Future<List<SearchHit>> search(String input) async {
    final q = normalizeForSearch(input);
    if (q.isEmpty) return const [];
    final index = await _index();

    final ref = parseArticleReference(q);
    if (ref != null) {
      final laws = await db.searchLawsByName(index.candidates(ref.lawQuery));
      // 略称の完全一致（法法 → 法人税法）は先頭に
      final full = index.expand(ref.lawQuery);
      laws.sort((a, b) {
        final ea = a.title == full ? 0 : 1;
        final eb = b.title == full ? 0 : 1;
        return ea - eb;
      });
      return [for (final l in laws) SearchHit(l, article: ref)];
    }

    final laws = await db.searchLawsByName(index.candidates(q));
    return [for (final l in laws) SearchHit(l)];
  }
}
