import 'dart:convert';

import 'package:xml/xml.dart';

/// 法令標準XMLの要素を表すツリーノード。
///
/// e-Gov 法令API v2 の `/law_file/json` と `/law_data`（`law_full_text`）が返す
/// `{tag, attr, children}` と同じ形。XML からも同じ形に変換できるので、
/// パーサ（[LawParser]）は取得形式に依存しない。
class LawNode {
  LawNode(this.tag, this.attr, this.children);

  final String tag;
  final Map<String, String> attr;

  /// 子要素。要素は [LawNode]、テキストは [String]。
  final List<Object> children;

  /// API の JSON ノードから変換する。
  ///
  /// 仕様書の例では属性が無い要素の `attr` が `""`（空文字列）で表現されることが
  /// あるため、Map 以外は空として扱う。
  static LawNode fromJson(Map<String, dynamic> json) {
    final rawAttr = json['attr'];
    final attr = <String, String>{};
    if (rawAttr is Map) {
      rawAttr.forEach((k, v) => attr[k.toString()] = v?.toString() ?? '');
    }
    final rawChildren = json['children'];
    final children = <Object>[];
    if (rawChildren is List) {
      for (final c in rawChildren) {
        if (c is String) {
          children.add(c);
        } else if (c is Map<String, dynamic>) {
          children.add(fromJson(c));
        } else if (c is Map) {
          children.add(fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }
    return LawNode(json['tag'] as String, attr, children);
  }

  /// JSON 文字列（`/law_file/json` のレスポンス全体）から変換する。
  static LawNode parseJsonString(String source) =>
      fromJson(json.decode(source) as Map<String, dynamic>);

  /// XML 要素から変換する。
  ///
  /// 空白のみのテキストノード（整形用の改行・インデント）は捨てる。
  /// それ以外のテキストは ASCII 空白（改行・タブ・半角スペース）だけを両端から
  /// 取り除く。全角スペース（U+3000）は「附　則」のように意味を持つので残す。
  static LawNode fromXml(XmlElement element) {
    final attr = <String, String>{
      for (final a in element.attributes) a.name.local: a.value,
    };
    final children = <Object>[];
    for (final node in element.children) {
      if (node is XmlElement) {
        children.add(fromXml(node));
      } else if (node is XmlText || node is XmlCDATA) {
        final text = _trimAscii(node.value ?? '');
        if (text.isNotEmpty) children.add(text);
      }
    }
    return LawNode(element.name.local, attr, children);
  }

  /// XML 文字列（`/law_file/xml` のレスポンス全体）から変換する。
  static LawNode parseXmlString(String source) =>
      fromXml(XmlDocument.parse(source).rootElement);

  /// `{tag, attr, children}` 形式の JSON に戻す（`body_json` の保存用）。
  Map<String, dynamic> toJson() => {
        'tag': tag,
        'attr': attr,
        'children': [
          for (final c in children) c is LawNode ? c.toJson() : c,
        ],
      };

  /// 直下の要素の子のみ。
  Iterable<LawNode> get elements => children.whereType<LawNode>();

  /// 指定タグの直下要素。
  Iterable<LawNode> childrenNamed(String name) =>
      elements.where((e) => e.tag == name);

  /// 指定タグの最初の直下要素。無ければ null。
  LawNode? firstChild(String name) {
    for (final e in elements) {
      if (e.tag == name) return e;
    }
    return null;
  }

  /// 配下のテキストを文書順に連結する。`Rt`（ルビの読み）は除外する。
  String get text {
    final buf = StringBuffer();
    _appendText(this, buf);
    return buf.toString();
  }

  static void _appendText(LawNode node, StringBuffer buf) {
    for (final c in node.children) {
      if (c is String) {
        buf.write(c);
      } else if (c is LawNode && c.tag != 'Rt') {
        _appendText(c, buf);
      }
    }
  }

  /// ノード数（要素のみ）。計測用。
  int get elementCount {
    var n = 1;
    for (final e in elements) {
      n += e.elementCount;
    }
    return n;
  }

  static String _trimAscii(String s) {
    var start = 0;
    var end = s.length;
    while (start < end && _isAsciiSpace(s.codeUnitAt(start))) {
      start++;
    }
    while (end > start && _isAsciiSpace(s.codeUnitAt(end - 1))) {
      end--;
    }
    return s.substring(start, end);
  }

  static bool _isAsciiSpace(int c) =>
      c == 0x20 || c == 0x0A || c == 0x0D || c == 0x09;

  @override
  String toString() => 'LawNode($tag, ${children.length} children)';
}
