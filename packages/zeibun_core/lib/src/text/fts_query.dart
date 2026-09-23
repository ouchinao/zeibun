import 'normalize.dart';

/// 語をダブルクォートで囲むのは、`OR` `NOT` `*` や括弧を FTS5 の演算子として
/// 解釈させないため。3 文字未満の語を MATCH 式に入れないのは、trigram 索引が
/// 3 文字未満の語にはどの行も一致させないため。その語は LIKE で絞る（設計書 §6）。
class FtsQuery {
  FtsQuery._(this.terms);

  factory FtsQuery.parse(String input) => FtsQuery._(splitSearchTerms(input));

  static const minMatchLength = 3;

  final List<String> terms;

  bool get isEmpty => terms.isEmpty;

  List<String> get matchTerms => [
        for (final t in terms)
          if (t.runes.length >= minMatchLength) t
      ];

  List<String> get likeTerms => [
        for (final t in terms)
          if (t.runes.length < minMatchLength) t
      ];

  String? get matchExpression => matchTerms.isEmpty
      ? null
      : matchTerms.map((t) => '"${t.replaceAll('"', '""')}"').join(' AND ');

  /// `%` と `_` をエスケープせず取り除くのは、法令の本文に現れない文字で、
  /// drift の `like()` が ESCAPE 句を出せないため。
  List<String> get likePatterns => [
        for (final t in likeTerms)
          if (t.replaceAll(RegExp('[%_]'), '') case final c when c.isNotEmpty)
            '%$c%',
      ];
}
