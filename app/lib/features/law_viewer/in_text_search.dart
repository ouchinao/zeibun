import 'package:zeibun_core/zeibun_core.dart';

import 'law_text.dart';

enum TextPart { main, suppl }

/// 附則の一致を条の通し番号でなくグループと条の組で指すのは、附則タブが
/// 改正ごとの折りたたみで、条へ寄せる前に開くべきグループが要るため。
typedef TextHit = ({TextPart part, int group, int index});

/// 閉じているときは画面側で null にして、開閉フラグと語・一致位置を
/// 別々の変数で持たない。
class InTextSearch {
  const InTextSearch({
    this.terms = const [],
    this.includeSuppl = false,
    this.hits = const [],
    this.cursor = 0,
  });

  final List<String> terms;
  final bool includeSuppl;
  final List<TextHit> hits;
  final int cursor;

  TextHit? get current => hits.isEmpty ? null : hits[cursor];

  String? get counter => hits.isEmpty
      ? (terms.isEmpty ? null : '0 件')
      : '${cursor + 1}/${hits.length}';

  InTextSearch step(int delta) => InTextSearch(
        terms: terms,
        includeSuppl: includeSuppl,
        hits: hits,
        cursor: (cursor + delta) % hits.length,
      );

  /// 附則を既定で含めないのは、所得税法の全文で附則が 1,000 件を超え、
  /// 本則を探しているときの一致がその中に埋もれるため（設計書 §6）。
  /// 現在位置を先頭の一致に固定しないのは、検索結果から条を指定して開いたとき、
  /// その条より前の一致へ飛び戻らないため（[startAt] 以降で最初の一致にする）。
  static InTextSearch run(
    LawText text,
    String query, {
    required bool includeSuppl,
    int startAt = 0,
  }) {
    final terms = splitSearchTerms(query);
    bool matches(ArticleItem a) =>
        terms.every(normalizeForMatch(a.plainText).contains);
    final hits = <TextHit>[
      if (terms.isNotEmpty) ...[
        for (var i = 0; i < text.main.length; i++)
          if (matches(text.main[i])) (part: TextPart.main, group: 0, index: i),
        if (includeSuppl)
          for (var g = 0; g < text.supplGroups.length; g++)
            for (var i = 0; i < text.supplGroups[g].articles.length; i++)
              if (matches(text.supplGroups[g].articles[i]))
                (part: TextPart.suppl, group: g, index: i),
      ],
    ];
    final cursor =
        hits.indexWhere((h) => h.part == TextPart.suppl || h.index >= startAt);
    return InTextSearch(
      terms: terms,
      includeSuppl: includeSuppl,
      hits: hits,
      cursor: cursor < 0 ? 0 : cursor,
    );
  }
}
