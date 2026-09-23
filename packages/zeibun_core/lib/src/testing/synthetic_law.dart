import 'dart:convert';

import '../law/law_node.dart';

/// 実 API に届かない環境でも規模感を測るための、税法に似た構造の合成法令。
///
/// 1 条あたり: 見出し・条名・3 項（うち 1 項は号 5 つ、1 項は表 1 つ）・ルビ 1 箇所。
/// 実測（法人税法など）の代わりにはならないが、`json.decode` と XML パースの
/// 相対比較と、条数に対する線形性の確認に使う。
class SyntheticLaw {
  SyntheticLaw({
    required this.articles,
    this.supplProvisions = 3,
    this.title = '合成税法',
  });

  final int articles;
  final int supplProvisions;
  final String title;

  static const _sentence =
      '内国法人の各事業年度の所得の金額は、当該事業年度の益金の額から当該事業年度の損金の額を控除した金額とする。';

  LawNode build() {
    final chapters = <LawNode>[];
    const perChapter = 50;
    var articleNum = 0;
    for (var c = 0; articleNum < articles; c++) {
      final arts = <LawNode>[];
      for (var i = 0; i < perChapter && articleNum < articles; i++) {
        articleNum++;
        arts.add(_article(articleNum, branch: i % 7 == 0 ? '4' : null));
      }
      chapters.add(LawNode('Chapter', {
        'Num': '${c + 1}'
      }, [
        LawNode('ChapterTitle', const {}, ['第${c + 1}章　各事業年度の所得の金額の計算']),
        ...arts,
      ]));
    }
    final suppl = <LawNode>[
      for (var s = 0; s < supplProvisions; s++)
        LawNode('SupplProvision', {
          'AmendLawNum': '令和${s + 1}年法律第${10 + s}号',
          'Extract': 'true',
        }, [
          LawNode('SupplProvisionLabel', const {}, ['附　則']),
          _paragraph(1, caption: '（施行期日）'),
          _paragraph(2, oldNum: true),
          LawNode('Article', const {
            'Num': '3'
          }, [
            LawNode('ArticleTitle', const {}, ['第三条']),
            _paragraph(1),
          ]),
        ]),
    ];
    return LawNode('Law', const {
      'Era': 'Showa',
      'Lang': 'ja',
      'LawType': 'Act',
      'Num': '34',
      'Year': '40',
    }, [
      LawNode('LawNum', const {}, ['昭和四十年法律第三十四号']),
      LawNode('LawBody', const {}, [
        LawNode('LawTitle', const {'Kana': 'ごうせいぜいほう'}, [title]),
        LawNode('MainProvision', const {}, [
          LawNode('Part', const {
            'Num': '1'
          }, [
            LawNode('PartTitle', const {}, ['第一編　総則']),
            ...chapters,
          ]),
        ]),
        ...suppl,
        LawNode('AppdxTable', const {
          'Num': '1'
        }, [
          LawNode('AppdxTableTitle', const {}, ['別表第一']),
          LawNode('RelatedArticleNum', const {}, ['（第二条関係）']),
          _table(),
        ]),
      ]),
    ]);
  }

  LawNode _article(int num, {String? branch}) {
    final n = branch == null ? '$num' : '${num}_$branch';
    final title = branch == null ? '第$num条' : '第$num条の$branch';
    return LawNode('Article', {
      'Num': n,
      'Delete': 'false',
      'Hide': 'false'
    }, [
      LawNode('ArticleCaption', const {}, ['（各事業年度の所得の金額の計算の通則）']),
      LawNode('ArticleTitle', const {}, [title]),
      _paragraph(1, ruby: true),
      _paragraph(2, items: 5),
      _paragraph(3, table: true),
    ]);
  }

  LawNode _paragraph(int num,
      {String? caption,
      bool oldNum = false,
      int items = 0,
      bool table = false,
      bool ruby = false}) {
    final sentenceChildren = <Object>[
      if (ruby) ...[
        '内国法人の各事業年度の所得の金額は、当該事業年度の',
        LawNode('Ruby', const {}, [
          '益',
          LawNode('Rt', const {}, ['えき']),
        ]),
        '金の額から損金の額を控除した金額とする。',
      ] else
        _sentence,
    ];
    return LawNode('Paragraph', {
      'Num': '$num',
      'Hide': 'false',
      if (oldNum) 'OldNum': 'true',
    }, [
      if (caption != null) LawNode('ParagraphCaption', const {}, [caption]),
      LawNode(
          'ParagraphNum', const {}, [if (num > 1 && !oldNum) _fullWidth(num)]),
      LawNode('ParagraphSentence', const {}, [
        LawNode('Sentence', const {'Num': '1', 'WritingMode': 'vertical'},
            sentenceChildren),
      ]),
      for (var i = 1; i <= items; i++)
        LawNode('Item', {
          'Num': '$i'
        }, [
          LawNode('ItemTitle', const {}, [_kanjiNum(i)]),
          LawNode('ItemSentence', const {}, [
            LawNode('Sentence', const {'WritingMode': 'vertical'},
                ['当該事業年度の収益の額で第$i号に掲げるもの']),
          ]),
        ]),
      if (table) LawNode('TableStruct', const {}, [_table()]),
    ]);
  }

  LawNode _table() => LawNode('Table', const {
        'WritingMode': 'vertical'
      }, [
        for (var r = 0; r < 3; r++)
          LawNode('TableRow', const {}, [
            for (var c = 0; c < 3; c++)
              LawNode('TableColumn', const {
                'BorderTop': 'solid'
              }, [
                LawNode('Sentence', const {}, ['区分$r-$c']),
              ]),
          ]),
      ]);

  static String _fullWidth(int n) => n
      .toString()
      .split('')
      .map((d) => String.fromCharCode(0xFF10 + int.parse(d)))
      .join();

  static String _kanjiNum(int n) {
    const k = ['〇', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];
    return n <= 10 ? k[n] : '$n';
  }

  /// 実 API の `/law_file/json` と同じ形の JSON 文字列。
  String toJsonString() => jsonEncode(build().toJson());

  /// 実 API の `/law_file/xml` に近い XML 文字列（整形なし）。
  String toXmlString() {
    final buf = StringBuffer('<?xml version="1.0" encoding="UTF-8"?>\n');
    _writeXml(build(), buf);
    return buf.toString();
  }

  static void _writeXml(LawNode n, StringBuffer buf) {
    buf.write('<${n.tag}');
    n.attr.forEach((k, v) => buf.write(' $k="${_esc(v)}"'));
    if (n.children.isEmpty) {
      buf.write('/>');
      return;
    }
    buf.write('>');
    for (final c in n.children) {
      if (c is String) {
        buf.write(_esc(c));
      } else if (c is LawNode) {
        _writeXml(c, buf);
      }
    }
    buf.write('</${n.tag}>');
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
