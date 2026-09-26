import 'package:zeibun_core/zeibun_core.dart';

import '../db/database.dart';

/// 検索結果の 1 件。法令名検索と条番号ジャンプを 1 つの窓で扱う（設計書 §6.1）。
class SearchHit {
  const SearchHit(this.law, {this.article});
  final Law law;

  /// 条番号ジャンプのとき、飛び先の条番号（`Article@Num` 形式）。
  final ArticleReference? article;
}

/// 組み込みの実務略称（法法・措法）だけにしないのは、API の `abbrev`（租特法）が
/// 実務の略し方と一致しないことがあるため。
LawAbbrevIndex abbrevIndexFor(Iterable<Law> laws) =>
    LawAbbrevIndex().withApiAbbrevs([
      for (final l in laws)
        if (l.abbrev case final a? when a.isNotEmpty) MapEntry(a, l.title),
    ]);

class FullTextResult {
  const FullTextResult(this.query, this.hits, this.laws);
  final FtsQuery query;
  final List<FullTextHit> hits;
  final List<LawHitCount> laws;

  /// 一致した条の総数。[hits] は表示用に件数を絞るので、法令別件数から足す。
  int get totalHits => laws.fold(0, (n, l) => n + l.count);
}

class SearchRepository {
  SearchRepository({required this.db, required this.abbrevs});

  final AppDatabase db;
  final LawAbbrevIndex abbrevs;

  /// 法令別件数を [lawId] で絞らないのは、1 法令に絞った状態でも他の法令の
  /// 件数が見え、そこからフィルタを切り替えられるようにするため。
  Future<FullTextResult> searchFullText(String input,
      {bool includeSuppl = false, String? lawId}) async {
    final q = FtsQuery.parse(input);
    if (q.isEmpty) return FullTextResult(q, const [], const []);
    final (hits, laws) = await (
      db.searchFullText(q, includeSuppl: includeSuppl, lawId: lawId),
      db.fullTextLawCounts(q, includeSuppl: includeSuppl),
    ).wait;
    return FullTextResult(q, hits, laws);
  }

  /// 入力を解釈して検索する。
  /// 1. 条番号を含めば「法令 + 条」のジャンプ候補
  /// 2. それ以外は法令名・略称・読みの部分一致
  Future<List<SearchHit>> search(String input) async {
    final q = normalizeForSearch(input);
    if (q.isEmpty) return const [];

    final ref = parseArticleReference(q);
    if (ref == null) {
      final laws = await db.searchLawsByName(abbrevs.candidates(q));
      return [for (final l in laws) SearchHit(l)];
    }
    final laws = await db.searchLawsByName(abbrevs.candidates(ref.lawQuery));
    // DB の並び（題名の短い順）に任せないのは、候補語の部分一致では略称が指す
    // 法令（法法 → 法人税法）が施行令・施行規則と同列になり得るため
    final full = abbrevs.expand(ref.lawQuery);
    laws.sort((a, b) => (a.title == full ? 0 : 1) - (b.title == full ? 0 : 1));
    return [for (final l in laws) SearchHit(l, article: ref)];
  }
}
