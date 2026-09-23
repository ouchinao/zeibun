import 'package:flutter/painting.dart';
import 'package:zeibun_core/zeibun_core.dart';

/// 照合に `normalizeForSearch` ではなく `normalizeForMatch` を使うのは、
/// 文字数を変えないので一致位置を元の文字列にそのまま使えるため。
List<InlineSpan> highlightSpans(String text, List<String> terms,
    {required TextStyle style}) {
  if (terms.isEmpty || text.isEmpty) return [TextSpan(text: text)];
  final norm = normalizeForMatch(text);
  final marks = List<bool>.filled(text.length, false);
  for (final t in terms) {
    if (t.isEmpty) continue;
    var i = norm.indexOf(t);
    while (i >= 0) {
      marks.fillRange(i, i + t.length, true);
      i = norm.indexOf(t, i + t.length);
    }
  }
  final spans = <InlineSpan>[];
  var start = 0;
  for (var i = 1; i <= text.length; i++) {
    if (i == text.length || marks[i] != marks[start]) {
      spans.add(TextSpan(
          text: text.substring(start, i), style: marks[start] ? style : null));
      start = i;
    }
  }
  return spans;
}
