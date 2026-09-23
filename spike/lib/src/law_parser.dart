import 'law_node.dart';

/// 条を単位にした本文レコード（設計書 §5 `articles` テーブルの 1 行に対応）。
class ArticleRecord {
  ArticleRecord({
    required this.seq,
    required this.section,
    required this.path,
    required this.plainText,
    required this.body,
    this.supplAmendLawNum,
    this.articleNum,
    this.articleTitle,
    this.caption,
    this.breadcrumb,
  });

  /// 法令内の表示順（0 始まり）。
  final int seq;

  /// `main` / `suppl` / `appdx`。
  final String section;

  /// 附則の場合の改正法令番号（`SupplProvision@AmendLawNum`）。
  final String? supplAmendLawNum;

  /// 例: `main/Article_22`、`suppl[令和八年法律第十二号]/Article_3`。
  final String path;

  /// `Article@Num`（"22", "66_4" など）。仮想条（条を持たない附則の項など）は null。
  final String? articleNum;

  /// 第二十二条
  final String? articleTitle;

  /// （各事業年度の所得の金額の計算の通則）
  final String? caption;

  /// 第二編 > 第一章 > 第一節
  final String? breadcrumb;

  /// 検索用の平文（項・号・表を改行区切りで平文化）。
  final String plainText;

  /// 表示用サブツリー（`Article` 要素など）。
  final LawNode body;

  Map<String, dynamic> toJson() => {
        'seq': seq,
        'section': section,
        if (supplAmendLawNum != null) 'suppl_amend_law_num': supplAmendLawNum,
        'path': path,
        'article_num': articleNum,
        'article_title': articleTitle,
        'caption': caption,
        'breadcrumb': breadcrumb,
        'plain_text': plainText,
      };
}

/// 法令メタ情報（`Law` 要素の属性と題名）。
class LawHeader {
  LawHeader({required this.lawNum, required this.title, required this.attr});

  final String? lawNum;
  final String? title;
  final Map<String, String> attr;
}

/// 法令の `LawNode` ツリーを条レコード列に変換する（設計書 §7）。
class LawParser {
  const LawParser();

  static const _structureTags = {
    'Part',
    'Chapter',
    'Section',
    'Subsection',
    'Division',
  };

  static const _appdxPrefix = 'Appdx';

  LawHeader header(LawNode law) {
    final body = law.firstChild('LawBody');
    return LawHeader(
      lawNum: law.firstChild('LawNum')?.text,
      title: body?.firstChild('LawTitle')?.text,
      attr: law.attr,
    );
  }

  List<ArticleRecord> parse(LawNode law) {
    final lawBody = law.tag == 'LawBody' ? law : law.firstChild('LawBody');
    if (lawBody == null) return const [];

    final out = <ArticleRecord>[];
    var appdxIndex = 0;
    for (final node in lawBody.elements) {
      switch (node.tag) {
        case 'MainProvision':
          _walkSection(node, 'main', null, 'main', out);
        case 'SupplProvision':
          final amend = node.attr['AmendLawNum'];
          final prefix =
              amend == null || amend.isEmpty ? 'suppl' : 'suppl[$amend]';
          _walkSection(node, 'suppl', amend, prefix, out);
        default:
          if (node.tag.startsWith(_appdxPrefix)) {
            appdxIndex++;
            final title = _appdxTitle(node);
            out.add(ArticleRecord(
              seq: out.length,
              section: 'appdx',
              path: 'appdx/${node.tag}_$appdxIndex',
              articleNum: null,
              articleTitle: title,
              caption: _relatedArticleNum(node),
              breadcrumb: null,
              plainText: PlainText.of(node),
              body: node,
            ));
          }
        // TOC, LawTitle, EnactStatement, Preamble はレコード化しない
      }
    }
    return out;
  }

  void _walkSection(
    LawNode root,
    String section,
    String? amendLawNum,
    String pathPrefix,
    List<ArticleRecord> out,
  ) {
    final crumbs = <String>[];
    // 条を持たない項（附則に多い）を 1 レコードにまとめるためのバッファ
    final looseParagraphs = <LawNode>[];

    void flushLoose() {
      if (looseParagraphs.isEmpty) return;
      final virtual = LawNode('Article', const {}, List.of(looseParagraphs));
      out.add(ArticleRecord(
        seq: out.length,
        section: section,
        supplAmendLawNum: amendLawNum,
        path: '$pathPrefix/Paragraphs',
        articleNum: null,
        articleTitle: null,
        caption: null,
        breadcrumb: crumbs.isEmpty ? null : crumbs.join(' > '),
        plainText: PlainText.of(virtual),
        body: virtual,
      ));
      looseParagraphs.clear();
    }

    void visit(LawNode node) {
      for (final child in node.elements) {
        if (_structureTags.contains(child.tag)) {
          flushLoose();
          final title = child.firstChild('${child.tag}Title')?.text;
          if (title != null && title.isNotEmpty) crumbs.add(title);
          visit(child);
          if (title != null && title.isNotEmpty) crumbs.removeLast();
        } else if (child.tag == 'Article') {
          flushLoose();
          out.add(ArticleRecord(
            seq: out.length,
            section: section,
            supplAmendLawNum: amendLawNum,
            path: '$pathPrefix/Article_${child.attr['Num'] ?? ''}',
            articleNum: child.attr['Num'],
            articleTitle: child.firstChild('ArticleTitle')?.text,
            caption: child.firstChild('ArticleCaption')?.text,
            breadcrumb: crumbs.isEmpty ? null : crumbs.join(' > '),
            plainText: PlainText.of(child),
            body: child,
          ));
        } else if (child.tag == 'Paragraph') {
          looseParagraphs.add(child);
        } else if (child.tag.startsWith(_appdxPrefix) ||
            child.tag == 'SupplProvisionAppdxTable' ||
            child.tag == 'SupplProvisionAppdxStyle' ||
            child.tag == 'SupplProvisionAppdx') {
          // 附則内の別表等。附則の中にある位置を保ったまま 1 レコードにする
          flushLoose();
          out.add(ArticleRecord(
            seq: out.length,
            section: section,
            supplAmendLawNum: amendLawNum,
            path: '$pathPrefix/${child.tag}_${out.length}',
            articleNum: null,
            articleTitle: _appdxTitle(child),
            caption: _relatedArticleNum(child),
            breadcrumb: crumbs.isEmpty ? null : crumbs.join(' > '),
            plainText: PlainText.of(child),
            body: child,
          ));
        }
        // SupplProvisionLabel, ChapterTitle 等はここでは無視
      }
    }

    visit(root);
    flushLoose();
  }

  String? _appdxTitle(LawNode node) {
    for (final e in node.elements) {
      if (e.tag.endsWith('Title')) return e.text;
    }
    return null;
  }

  String? _relatedArticleNum(LawNode node) =>
      node.firstChild('RelatedArticleNum')?.text;
}

/// 検索用の平文化（設計書 §7-3）。
///
/// - `Sentence` を文書順に連結
/// - `Paragraph` は項番号（`ParagraphNum`。`OldNum="true"` で空なら `Num` 属性から補う）を先頭に
/// - `Item` / `Subitem*` は見出し（`ItemTitle` 等）を先頭に付け、改行区切り
/// - `TableStruct` はセルをタブ区切り、行を改行区切り
/// - `Rt`（ルビの読み）は除外
class PlainText {
  PlainText._();

  static const _blockTags = {
    'Paragraph',
    'Item',
    'Subitem1',
    'Subitem2',
    'Subitem3',
    'Subitem4',
    'Subitem5',
    'Subitem6',
    'Subitem7',
    'Subitem8',
    'Subitem9',
    'Subitem10',
    'List',
    'Sublist1',
    'Sublist2',
    'Sublist3',
    'TableRow',
    'Remarks',
    'Note',
    'ArticleCaption',
    'ArticleTitle',
    'SupplProvisionLabel',
    'AppdxTableTitle',
    'TableStructTitle',
    'RelatedArticleNum',
  };

  static String of(LawNode node) {
    final lines = <String>[];
    final current = StringBuffer();

    void flush() {
      final s = current.toString().trim();
      if (s.isNotEmpty) lines.add(s);
      current.clear();
    }

    void walk(LawNode n) {
      final isBlock = _blockTags.contains(n.tag);
      if (isBlock) flush();

      if (n.tag == 'Rt') return;

      if (n.tag == 'Paragraph') {
        // 項見出し（附則の「（施行期日）」など）は項番号の前に独立した行にする
        final caption = n.firstChild('ParagraphCaption')?.text.trim() ?? '';
        if (caption.isNotEmpty) {
          current.write(caption);
          flush();
        }
        final numNode = n.firstChild('ParagraphNum');
        var num = numNode?.text.trim() ?? '';
        if (num.isEmpty && n.attr['OldNum'] == 'true') {
          num = n.attr['Num'] ?? '';
        }
        if (num.isNotEmpty) current.write('$num　');
      }

      for (final c in n.children) {
        if (c is String) {
          current.write(c);
        } else if (c is LawNode) {
          if (c.tag == 'ParagraphNum' || c.tag == 'ParagraphCaption') {
            continue; // 先頭で処理済み
          }
          if (c.tag == 'TableColumn') {
            if (!current.toString().endsWith('\t') && current.isNotEmpty) {
              current.write('\t');
            }
            walk(c);
            continue;
          }
          if (c.tag.endsWith('Title') && _blockTags.contains(n.tag)) {
            // ItemTitle / Subitem1Title などは見出しとして本文の先頭に
            current.write('${c.text}　');
            continue;
          }
          walk(c);
        }
      }
      if (isBlock) flush();
    }

    walk(node);
    flush();
    return lines.join('\n');
  }
}
