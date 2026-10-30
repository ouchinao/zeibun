import 'normalize.dart';

/// テーマの索引に載せる条。
class TopicArticle {
  const TopicArticle({
    required this.lawId,
    required this.lawTitle,
    required this.articleNum,
    required this.articleTitle,
    required this.caption,
  });

  final String lawId;
  final String lawTitle;

  /// `Article@Num` 形式（`57_2`）。
  final String articleNum;
  final String articleTitle;

  /// 条見出し（括弧を除く）。
  final String caption;
}

/// 実務のテーマと、よく参照する条。
///
/// どの条が当てはまるかの判断は載せない。載せるのは「よく参照する条の案内」まで
/// （税理士法上の税務相談に踏み込まないため）。
class Topic {
  const Topic(
      {required this.name, required this.keywords, required this.articles});

  final String name;

  /// 検索語にこのどれかが含まれると、このテーマを出す。
  final List<String> keywords;
  final List<TopicArticle> articles;
}

const _hojin = '340AC0000000034';
const _shotoku = '340AC0000000033';
const _shohi = '363AC0000000108';
const _sochi = '332AC0000000026';

TopicArticle _a(String lawId, String lawTitle, String num, String title,
        String caption) =>
    TopicArticle(
        lawId: lawId,
        lawTitle: lawTitle,
        articleNum: num,
        articleTitle: title,
        caption: caption);

/// 条番号と見出しは、2026-10 時点の e-Gov の本文で確かめてある。手で見直すだけに
/// しないのは、法令が廃止されても気づかず古い案内を出し続けるため（アプリ側の
/// テストで、法令が同梱一覧にあり廃止されていないことを確かめる）。
final List<Topic> builtInTopics = List.unmodifiable([
  Topic(name: 'インボイス（適格請求書）', keywords: const [
    'インボイス',
    '適格請求書'
  ], articles: [
    _a(_shohi, '消費税法', '30', '第三十条', '仕入れに係る消費税額の控除'),
    _a(_shohi, '消費税法', '57_2', '第五十七条の二', '適格請求書発行事業者の登録等'),
    _a(_shohi, '消費税法', '57_4', '第五十七条の四', '適格請求書発行事業者の義務'),
  ]),
  Topic(name: '簡易課税', keywords: const [
    '簡易課税'
  ], articles: [
    _a(_shohi, '消費税法', '37', '第三十七条', '中小事業者の仕入れに係る消費税額の控除の特例'),
  ]),
  Topic(name: '給与', keywords: const [
    '給与',
    '給料',
    'ボーナス',
    '賞与'
  ], articles: [
    _a(_shotoku, '所得税法', '28', '第二十八条', '給与所得'),
    _a(_shotoku, '所得税法', '183', '第百八十三条', '源泉徴収義務'),
    _a(_shotoku, '所得税法', '190', '第百九十条', '年末調整'),
  ]),
  Topic(name: '年末調整', keywords: const [
    '年末調整'
  ], articles: [
    _a(_shotoku, '所得税法', '190', '第百九十条', '年末調整'),
  ]),
  Topic(name: '退職金', keywords: const [
    '退職金',
    '退職手当',
    '退職所得'
  ], articles: [
    _a(_shotoku, '所得税法', '30', '第三十条', '退職所得'),
  ]),
  Topic(name: '役員報酬（役員給与）', keywords: const [
    '役員報酬',
    '役員給与'
  ], articles: [
    _a(_hojin, '法人税法', '34', '第三十四条', '役員給与の損金不算入'),
  ]),
  Topic(name: '交際費', keywords: const [
    '交際費'
  ], articles: [
    _a(_sochi, '租税特別措置法', '61_4', '第六十一条の四', '交際費等の損金不算入'),
  ]),
  Topic(name: '減価償却', keywords: const [
    '減価償却'
  ], articles: [
    _a(_hojin, '法人税法', '31', '第三十一条', '減価償却資産の償却費の計算及びその償却の方法'),
    _a(_shotoku, '所得税法', '49', '第四十九条', '減価償却資産の償却費の計算及びその償却の方法'),
  ]),
  Topic(name: '住宅ローン控除', keywords: const [
    '住宅ローン',
    '住宅借入金'
  ], articles: [
    _a(_sochi, '租税特別措置法', '41', '第四十一条', '住宅借入金等を有する場合の所得税額の特別控除'),
  ]),
  Topic(name: '医療費控除', keywords: const [
    '医療費'
  ], articles: [
    _a(_shotoku, '所得税法', '73', '第七十三条', '医療費控除'),
  ]),
  Topic(name: '扶養控除', keywords: const [
    '扶養控除'
  ], articles: [
    _a(_shotoku, '所得税法', '84', '第八十四条', '扶養控除'),
  ]),
  Topic(name: '青色申告', keywords: const [
    '青色申告'
  ], articles: [
    _a(_shotoku, '所得税法', '143', '第百四十三条', '青色申告'),
    _a(_hojin, '法人税法', '121', '第百二十一条', '青色申告'),
  ]),
]);

/// 検索語のどれかがテーマのキーワードを含むテーマを返す。
///
/// 語の完全一致にしないのは、「インボイス制度」「給与所得」のように実務の言葉が
/// キーワードに一言足した形で入力されることが多いため。
List<Topic> topicsFor(String input, {List<Topic>? topics}) {
  final terms = splitSearchTerms(input);
  if (terms.isEmpty) return const [];
  return [
    for (final topic in topics ?? builtInTopics)
      if (topic.keywords.any((k) {
        final key = normalizeForSearch(k);
        return terms.any((t) => t.contains(key));
      }))
        topic,
  ];
}
