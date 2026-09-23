/// 検索用の正規化と条番号の解釈。
///
/// `unorm_dart` で NFKC 全体をかけないのは、法令テキストで揺れるのが全角英数字と
/// スペースにほぼ限られ、依存を増やさずに Web でも同じ挙動を保ちたいから。
/// 文字数を変えない変換だけにしているので、正規化後の一致位置を元の文字列の
/// ハイライトにそのまま使える。
library;

/// 全角英数字・記号（U+FF01〜U+FF5E）を半角に、全角スペースを半角スペースにする。
String normalizeWidth(String s) {
  final buf = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0xFF01 && r <= 0xFF5E) {
      buf.writeCharCode(r - 0xFEE0);
    } else if (r == 0x3000) {
      buf.write(' ');
    } else {
      buf.writeCharCode(r);
    }
  }
  return buf.toString();
}

/// 検索キーの正規化: 幅の統一 → 小文字化 → 前後空白除去。
String normalizeForSearch(String s) => normalizeForMatch(s).trim();

/// 照合用の正規化: 幅の統一 → 小文字化。文字数を変えないので、この結果で
/// 見つけた一致位置を元の文字列のハイライトにそのまま使える（trim しない）。
String normalizeForMatch(String s) => normalizeWidth(s).toLowerCase();

const Map<String, int> _kanjiDigits = {
  '〇': 0,
  '零': 0,
  '一': 1,
  '二': 2,
  '三': 3,
  '四': 4,
  '五': 5,
  '六': 6,
  '七': 7,
  '八': 8,
  '九': 9,
};
const Map<String, int> _kanjiUnits = {'十': 10, '百': 100, '千': 1000};

/// 漢数字（十進位取り・単位付きの両方）を整数にする。数字でなければ null。
///
/// `二十二` → 22、`百三` → 103、`一〇二` → 102、`22` / `２２` → 22。
int? parseJapaneseNumber(String s) {
  final t = normalizeWidth(s).trim();
  if (t.isEmpty) return null;
  final asInt = int.tryParse(t);
  if (asInt != null) return asInt;

  var total = 0;
  var current = 0;
  var sawUnit = false;
  var positional = true;
  for (final ch in t.split('')) {
    if (_kanjiDigits.containsKey(ch)) {
      current = current * 10 + _kanjiDigits[ch]!;
    } else if (_kanjiUnits.containsKey(ch)) {
      positional = false;
      sawUnit = true;
      total += (current == 0 ? 1 : current) * _kanjiUnits[ch]!;
      current = 0;
    } else {
      return null;
    }
  }
  if (!sawUnit && positional) return current; // 一〇二 のような位取り
  return total + current;
}

/// 条番号ジャンプの解釈結果。
class ArticleReference {
  const ArticleReference({
    required this.lawQuery,
    required this.articleNum,
    this.paragraph,
  });

  /// 法令名または略称の部分（例 `法人税法`、`法法`、`措法`）。
  final String lawQuery;

  /// API の `Article@Num` 形式（`22`、`42_12_5`）。
  final String articleNum;

  /// 項（あれば）。
  final int? paragraph;

  String get display => articleNumDisplay(articleNum);

  @override
  String toString() => 'ArticleReference($lawQuery $articleNum ¶$paragraph)';
}

final RegExp _num = RegExp('[0-9０-９〇零一二三四五六七八九十百千]+');
final RegExp _articleRef = RegExp(
  '^(.*?)\\s*第?(${_num.pattern})\\s*条?((?:の${_num.pattern})*)\\s*(?:第?(${_num.pattern})項)?\\s*\$',
);

/// `法人税法22条` `法法２２` `措法42の12の5` `所得税法第二十二条第一項` のような
/// 入力を解釈する。条番号が取れなければ null。
ArticleReference? parseArticleReference(String input) {
  final s = normalizeWidth(input).trim();
  final m = _articleRef.firstMatch(s);
  if (m == null) return null;
  final lawQuery = m.group(1)!.trim();
  final main = parseJapaneseNumber(m.group(2)!);
  if (main == null || lawQuery.isEmpty) return null;
  final branches = <int>[];
  for (final b in _num.allMatches(m.group(3) ?? '')) {
    final n = parseJapaneseNumber(b.group(0)!);
    if (n == null) return null;
    branches.add(n);
  }
  final para = m.group(4) == null ? null : parseJapaneseNumber(m.group(4)!);
  return ArticleReference(
    lawQuery: lawQuery,
    articleNum: [main, ...branches].join('_'),
    paragraph: para,
  );
}

/// `42_12_5` → `第42条の12の5`。枝番ごとに「条」を付けないのは、実務の表記が
/// 「第42条の12の5」であって「第42条の第12条…」ではないため。
String articleNumDisplay(String num) {
  final parts = num.split('_');
  return '第${parts.first}条${parts.skip(1).map((p) => 'の$p').join()}';
}

/// `ArticleTitle`（`第二十二条の四`）を `Article@Num` 形式（`22_4`）にする。
/// 変換できなければ null。
String? articleNumFromTitle(String title) {
  final t = normalizeWidth(title).replaceAll(RegExp(r'\s'), '');
  final m =
      RegExp('^第(${_num.pattern})条((?:の${_num.pattern})*)\$').firstMatch(t);
  if (m == null) return null;
  final main = parseJapaneseNumber(m.group(1)!);
  if (main == null) return null;
  final parts = [main];
  for (final b in _num.allMatches(m.group(2) ?? '')) {
    final n = parseJapaneseNumber(b.group(0)!);
    if (n == null) return null;
    parts.add(n);
  }
  return parts.join('_');
}
