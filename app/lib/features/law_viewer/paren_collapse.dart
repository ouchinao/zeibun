import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:zeibun_core/zeibun_core.dart';

/// 本文の括弧書きを畳むかどうか（設計書 §8）。
///
/// 本文・附則のタブへ引数で渡していかないのは、描画の `LawNodeRenderer` まで
/// 4 段のウィジェットを通すことになり、途中のどれもこの値を使わないため。
class ParenCollapse extends InheritedWidget {
  const ParenCollapse({super.key, required this.enabled, required super.child});

  final bool enabled;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ParenCollapse>()?.enabled ??
      false;

  @override
  bool updateShouldNotify(ParenCollapse old) => old.enabled != enabled;
}

/// 括弧書きを「（…）」に畳んだ文。押した括弧書きだけ開く。
///
/// 開いた状態をこのウィジェットに持たせ、画面全体の状態にしないのは、どの括弧書きを
/// 開いたかは読んでいる間だけ意味があり、残す必要が無いため。
class CollapsedParenText extends StatefulWidget {
  const CollapsedParenText({
    super.key,
    required this.segments,
    required this.style,
    this.prefix,
    this.restore = _identity,
  });

  final List<ParenSegment> segments;
  final TextStyle style;
  final InlineSpan? prefix;

  /// 平文に戻すときの置き換え（ルビの目印を括弧に戻すなど）。
  final String Function(String) restore;

  static String _identity(String s) => s;

  @override
  State<CollapsedParenText> createState() => _CollapsedParenTextState();
}

class _CollapsedParenTextState extends State<CollapsedParenText> {
  final _open = <String>{};
  final _recognizers = <String, TapGestureRecognizer>{};

  @override
  void didUpdateWidget(CollapsedParenText old) {
    super.didUpdateWidget(old);
    // 参照で比べないのは、親が描き直すたびに分け直した別のリストが渡り、開いた
    // 括弧書きがスクロールなどのたびに閉じてしまうため
    if (!listEquals(old.segments, widget.segments)) _open.clear();
  }

  @override
  void dispose() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _tap(String key) => _recognizers.putIfAbsent(
      key,
      () =>
          TapGestureRecognizer()..onTap = () => setState(() => _open.add(key)));

  List<InlineSpan> _spans(
          List<ParenSegment> segs, String path, TextStyle mark) =>
      [
        for (final (i, seg) in segs.indexed)
          switch (seg) {
            PlainSegment(:final text) => TextSpan(text: widget.restore(text)),
            ParenGroup(:final children) when _open.contains('$path/$i') =>
              TextSpan(children: [
                const TextSpan(text: '（'),
                ..._spans(children, '$path/$i', mark),
                const TextSpan(text: '）'),
              ]),
            ParenGroup() => TextSpan(
                text: '（…）',
                style: mark,
                // 「…」だけを読ませないのは、何が省かれているのか耳では分からないため
                semanticsLabel: '括弧書き省略',
                recognizer: _tap('$path/$i'),
              ),
          },
      ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mark = widget.style
        .copyWith(color: scheme.primary, fontWeight: FontWeight.w600);
    return Text.rich(
      TextSpan(children: [
        if (widget.prefix case final p?) p,
        ..._spans(widget.segments, '', mark),
      ]),
      style: widget.style,
    );
  }
}

/// 括弧書きを畳んでいることを常に見せる帯。畳んでいる間に消さないのは、括弧書きの
/// 中に定義や除外の条件が書かれていることが多く、畳んだまま読むと意味を取り違えるため。
class ParenCollapseNotice extends StatelessWidget {
  const ParenCollapseNotice(
      {super.key, required this.searching, required this.onOpenAll});
  final bool searching;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(children: [
          Icon(Icons.unfold_less, size: 16, color: scheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              searching ? '検索中は括弧書きを開いて表示しています' : '括弧書きを畳んでいます。（…）を押すと開きます',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSecondaryContainer),
            ),
          ),
          TextButton(onPressed: onOpenAll, child: const Text('すべて開く')),
        ]),
      ),
    );
  }
}
