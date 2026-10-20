/// 文を、全角の丸括弧（`（` `）`）で囲まれた括弧書きの入れ子に分ける。
///
/// 半角の丸括弧を区切りに使わないのは、法令の本文の括弧書きは全角で、半角は
/// 「(1)」のような号細分の番号に使われるため。
sealed class ParenSegment {
  const ParenSegment();
}

class PlainSegment extends ParenSegment {
  const PlainSegment(this.text);
  final String text;

  @override
  bool operator ==(Object other) => other is PlainSegment && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'Plain($text)';
}

/// 括弧書き。[children] は括弧の内側で、括弧そのものは含めない。
class ParenGroup extends ParenSegment {
  const ParenGroup(this.children);
  final List<ParenSegment> children;

  @override
  bool operator ==(Object other) =>
      other is ParenGroup &&
      other.children.length == children.length &&
      [
        for (var i = 0; i < children.length; i++)
          children[i] == other.children[i]
      ].every((e) => e);

  @override
  int get hashCode => Object.hashAll(children);

  @override
  String toString() => 'Group($children)';
}

/// 閉じていない `（` から後ろを括弧書きとして扱わないのは、本文の途中で切れた
/// 文（抜粋など）で、文の残り全体が畳まれて読めなくなるため。そのときは平文に戻す。
/// 対になる `（` の無い `）` も平文として残す。
List<ParenSegment> splitParenGroups(String text) {
  final stack = <List<ParenSegment>>[[]];
  final opens = <int>[];
  final buf = StringBuffer();

  void flush() {
    if (buf.isEmpty) return;
    stack.last.add(PlainSegment(buf.toString()));
    buf.clear();
  }

  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (c == '（') {
      flush();
      stack.add([]);
      opens.add(i);
    } else if (c == '）' && stack.length > 1) {
      flush();
      final children = stack.removeLast();
      opens.removeLast();
      stack.last.add(ParenGroup(List.unmodifiable(children)));
    } else {
      buf.write(c);
    }
  }
  flush();
  if (stack.length == 1) return _merge(stack.single);
  final cut = opens.first;
  return _merge([
    ...splitParenGroups(text.substring(0, cut)),
    PlainSegment(text.substring(cut)),
  ]);
}

/// 隣り合う平文を 1 つにまとめる。
List<ParenSegment> _merge(List<ParenSegment> segs) {
  final out = <ParenSegment>[];
  for (final s in segs) {
    if (s is PlainSegment && out.isNotEmpty && out.last is PlainSegment) {
      out[out.length - 1] =
          PlainSegment((out.last as PlainSegment).text + s.text);
    } else {
      out.add(s);
    }
  }
  return List.unmodifiable(out);
}
