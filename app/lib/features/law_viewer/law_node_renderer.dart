import 'package:flutter/material.dart';
import 'package:zeibun_core/zeibun_core.dart';

/// 条のサブツリー（`body_json`）を Widget に変換する。
///
/// WebView や HTML 変換を使わないのは、外部由来のテキストをマークアップとして
/// 解釈させたくないため（設計書 §11 E）。ルビを本物のルビ組みにせず「本文（読み）」
/// と括弧書きにするのは、`Text.rich` にルビが無く `WidgetSpan` で組むと行間が
/// 崩れるから。未知のタグは子要素をそのまま描くだけで例外にしない。
class LawNodeRenderer extends StatelessWidget {
  const LawNodeRenderer(this.node, {super.key, this.highlight});

  final LawNode node;

  /// 本文内検索のハイライト語（幅正規化済み、小文字）。
  final String? highlight;

  @override
  Widget build(BuildContext context) =>
      _Renderer(context, highlight).block(node);
}

class _Renderer {
  _Renderer(this.context, this.highlight)
      : base = Theme.of(context).textTheme.bodyLarge!.copyWith(height: 1.7),
        scheme = Theme.of(context).colorScheme;

  final BuildContext context;
  final String? highlight;
  final TextStyle base;
  final ColorScheme scheme;

  static const _inlineTags = {
    'Sentence',
    'ParagraphSentence',
    'ItemSentence',
    'Subitem1Sentence',
    'Subitem2Sentence',
    'Subitem3Sentence',
    'Subitem4Sentence',
    'Subitem5Sentence',
    'Subitem6Sentence',
    'Subitem7Sentence',
    'Subitem8Sentence',
    'Subitem9Sentence',
    'Subitem10Sentence',
    'ListSentence',
    'Sublist1Sentence',
    'Sublist2Sentence',
    'Sublist3Sentence',
    'Column',
    'Ruby',
    'Line',
    'QuoteStruct',
    'ArithFormula',
  };

  Widget block(LawNode n) {
    switch (n.tag) {
      case 'Article':
        return _article(n);
      case 'Paragraph':
        return _paragraph(n);
      case 'Item':
        return _numbered(n, 'ItemTitle', indent: 1);
      case 'Subitem1':
      case 'Subitem2':
      case 'Subitem3':
      case 'Subitem4':
      case 'Subitem5':
      case 'Subitem6':
      case 'Subitem7':
      case 'Subitem8':
      case 'Subitem9':
      case 'Subitem10':
        final level = int.tryParse(n.tag.substring('Subitem'.length)) ?? 1;
        return _numbered(n, '${n.tag}Title', indent: 1 + level);
      case 'List':
      case 'Sublist1':
      case 'Sublist2':
      case 'Sublist3':
        return Padding(
          padding: const EdgeInsets.only(left: 16),
          child: _children(n),
        );
      case 'TableStruct':
        return _tableStruct(n);
      case 'Table':
        return _table(n);
      case 'FigStruct':
      case 'Fig':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text('［図・画像は e-Gov で参照してください］',
              style: base.copyWith(color: scheme.onSurfaceVariant)),
        );
      case 'Remarks':
      case 'Note':
      case 'NoteStruct':
      case 'StyleStruct':
      case 'FormatStruct':
        return Padding(
          padding: const EdgeInsets.only(left: 16, top: 4),
          child: DefaultTextStyle.merge(
            style: base.copyWith(fontSize: (base.fontSize ?? 16) - 2),
            child: _children(n),
          ),
        );
      default:
        if (_inlineTags.contains(n.tag)) return _inlineText(n);
        if (n.tag.endsWith('Title') ||
            n.tag.endsWith('Caption') ||
            n.tag.endsWith('Label') ||
            n.tag == 'RelatedArticleNum') {
          return Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child:
                Text(n.text, style: base.copyWith(fontWeight: FontWeight.w600)),
          );
        }
        if (n.tag == 'Rt') return const SizedBox.shrink();
        return _children(n);
    }
  }

  Widget _children(LawNode n) {
    final widgets = <Widget>[];
    final inlineRun = <LawNode>[];
    void flushInline() {
      if (inlineRun.isEmpty) return;
      final combined = LawNode('Sentence', const {}, [...inlineRun]);
      widgets.add(_inlineText(combined));
      inlineRun.clear();
    }

    for (final c in n.children) {
      if (c is String) {
        inlineRun.add(LawNode('Sentence', const {}, [c]));
      } else if (c is LawNode) {
        if (_inlineTags.contains(c.tag)) {
          inlineRun.add(c);
        } else {
          flushInline();
          widgets.add(block(c));
        }
      }
    }
    flushInline();
    if (widgets.length == 1) return widgets.first;
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: widgets);
  }

  Widget _article(LawNode n) {
    final caption = n.firstChild('ArticleCaption')?.text;
    final title = n.firstChild('ArticleTitle')?.text;
    final rest = n.elements
        .where((e) => e.tag != 'ArticleCaption' && e.tag != 'ArticleTitle')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (caption != null && caption.isNotEmpty)
          Text(caption, style: base.copyWith(color: scheme.onSurfaceVariant)),
        for (var i = 0; i < rest.length; i++)
          if (i == 0 && rest[i].tag == 'Paragraph')
            _paragraph(rest[i], leadingTitle: title)
          else
            block(rest[i]),
        if (rest.isEmpty && title != null)
          Text(title, style: base.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// 項。第 1 項は条名を先頭に置き、2 項以降は項番号をぶら下げる。
  Widget _paragraph(LawNode n, {String? leadingTitle}) {
    var num = n.firstChild('ParagraphNum')?.text.trim() ?? '';
    if (num.isEmpty && n.attr['OldNum'] == 'true') num = n.attr['Num'] ?? '';
    final caption = n.firstChild('ParagraphCaption')?.text;
    final body = n.elements
        .where((e) => e.tag != 'ParagraphNum' && e.tag != 'ParagraphCaption')
        .toList();
    final lead = leadingTitle ?? (num.isEmpty ? null : num);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (caption != null && caption.isNotEmpty)
            Text(caption, style: base.copyWith(color: scheme.onSurfaceVariant)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: leadingTitle != null ? 0 : 28,
                child: leadingTitle != null
                    ? null
                    : Text(num,
                        style: base.copyWith(fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < body.length; i++)
                      if (i == 0 && lead != null && leadingTitle != null)
                        _inlineText(body[i], prefix: '$lead　', prefixBold: true)
                      else
                        block(body[i]),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 号・号細分: 見出し（一、イ、(1)）をぶら下げ。
  Widget _numbered(LawNode n, String titleTag, {required int indent}) {
    final title = n.firstChild(titleTag)?.text ?? '';
    final body = n.elements.where((e) => e.tag != titleTag).toList();
    return Padding(
      padding: EdgeInsets.only(left: 12.0 * indent, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 28, child: Text(title, style: base)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final b in body) block(b)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableStruct(LawNode n) {
    final title = n.firstChild('TableStructTitle')?.text;
    final table = n.firstChild('Table');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null && title.isNotEmpty)
            Text(title, style: base.copyWith(fontWeight: FontWeight.w600)),
          if (table != null) _table(table),
          for (final e in n.elements)
            if (e.tag != 'TableStructTitle' && e.tag != 'Table') block(e),
        ],
      ),
    );
  }

  Widget _table(LawNode n) {
    final rows = n.childrenNamed('TableRow').toList();
    if (rows.isEmpty) return _children(n);
    final maxCols = rows
        .map((r) => r.childrenNamed('TableColumn').length)
        .fold<int>(0, (a, b) => a > b ? a : b);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(minWidth: MediaQuery.sizeOf(context).width - 32),
        child: Table(
          border: TableBorder.all(color: scheme.outlineVariant),
          defaultColumnWidth: const IntrinsicColumnWidth(),
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          children: [
            for (final r in rows)
              TableRow(children: [
                for (final c in r.childrenNamed('TableColumn'))
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: _children(c),
                  ),
                for (var i = r.childrenNamed('TableColumn').length;
                    i < maxCols;
                    i++)
                  const SizedBox.shrink(),
              ]),
          ],
        ),
      ),
    );
  }

  /// インライン要素をまとめて 1 つの `Text.rich` に。ルビは「本文（読み）」。
  Widget _inlineText(LawNode n, {String? prefix, bool prefixBold = false}) {
    final buf = StringBuffer();
    _collect(n, buf);
    final text = buf.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text.rich(
        TextSpan(children: [
          if (prefix != null)
            TextSpan(
                text: prefix,
                style: prefixBold
                    ? base.copyWith(fontWeight: FontWeight.bold)
                    : base),
          ..._highlighted(text),
        ]),
        style: base,
      ),
    );
  }

  void _collect(LawNode n, StringBuffer buf) {
    if (n.tag == 'Rt') return;
    if (n.tag == 'Ruby') {
      final rt = n.firstChild('Rt')?.text;
      for (final c in n.children) {
        if (c is String) buf.write(c);
        if (c is LawNode && c.tag != 'Rt') _collect(c, buf);
      }
      if (rt != null && rt.isNotEmpty) buf.write('（$rt）');
      return;
    }
    var first = true;
    for (final c in n.children) {
      if (c is String) {
        buf.write(c);
      } else if (c is LawNode) {
        // Column（欄）は全角スペースで区切る
        if (c.tag == 'Column' && !first) buf.write('　');
        _collect(c, buf);
      }
      first = false;
    }
  }

  List<InlineSpan> _highlighted(String text) {
    final h = highlight;
    if (h == null || h.isEmpty) return [TextSpan(text: text)];
    final norm = normalizeForSearch(text);
    final spans = <InlineSpan>[];
    var start = 0;
    while (true) {
      final i = norm.indexOf(h, start);
      if (i < 0) break;
      if (i > start) spans.add(TextSpan(text: text.substring(start, i)));
      spans.add(TextSpan(
        text: text.substring(i, i + h.length),
        style: TextStyle(
            backgroundColor: scheme.tertiaryContainer,
            fontWeight: FontWeight.bold),
      ));
      start = i + h.length;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return spans;
  }
}
