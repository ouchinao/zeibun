import 'search_synonyms.dart';

/// 語をダブルクォートで囲むのは、`OR` `NOT` `*` や括弧を FTS5 の演算子として
/// 解釈させないため。3 文字未満の語を MATCH 式に入れないのは、trigram 索引が
/// 3 文字未満の語にはどの行も一致させないため。その語は LIKE で絞る（設計書 §6）。
///
/// 入力した語ごとに、言い換えの語（[expandSearchTerms]）とまとめた組を持つ。
/// 組の中は OR、組どうしは AND。組の中に 3 文字未満の語が 1 つでもあれば、組ごと
/// LIKE に回す。語ごとに MATCH と LIKE に分けないのは、組の中の OR が書けなくなるため。
class FtsQuery {
  FtsQuery._(this.groups);

  factory FtsQuery.parse(String input) =>
      FtsQuery._(List.unmodifiable(expandSearchTerms(input)));

  static const minMatchLength = 3;

  /// 入力した語ごとの組。各組の先頭が入力した語。
  final List<List<String>> groups;

  /// 入力した語。
  List<String> get terms => [for (final g in groups) g.first];

  /// 強調する語。言い換えの語も含める。
  List<String> get highlightTerms => {for (final g in groups) ...g}.toList();

  bool get isEmpty => groups.isEmpty;

  static bool _indexable(List<String> g) =>
      g.every((t) => t.runes.length >= minMatchLength);

  List<List<String>> get matchGroups => [
        for (final g in groups)
          if (_indexable(g)) g
      ];

  List<List<String>> get likeGroups => [
        for (final g in groups)
          if (!_indexable(g)) g
      ];

  List<String> get matchTerms => [for (final g in matchGroups) ...g];

  List<String> get likeTerms => [for (final g in likeGroups) ...g];

  String? get matchExpression {
    if (matchGroups.isEmpty) return null;
    String quote(String t) => '"${t.replaceAll('"', '""')}"';
    return matchGroups
        .map((g) =>
            g.length == 1 ? quote(g.first) : '(${g.map(quote).join(' OR ')})')
        .join(' AND ');
  }

  /// `%` と `_` をエスケープせず取り除くのは、法令の本文に現れない文字で、
  /// drift の `like()` が ESCAPE 句を出せないため。
  List<List<String>> get likePatternGroups => [
        for (final g in likeGroups)
          if ([
            for (final t in g)
              if (t.replaceAll(RegExp('[%_]'), '') case final c
                  when c.isNotEmpty)
                '%$c%',
          ]
              case final ps when ps.isNotEmpty)
            ps,
      ];
}
