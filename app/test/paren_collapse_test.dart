import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeibun/features/law_viewer/law_node_renderer.dart';
import 'package:zeibun/features/law_viewer/paren_collapse.dart';
import 'package:zeibun_core/zeibun_core.dart';

LawNode _sentence(List<Object> children) =>
    LawNode('Sentence', const {}, children);

Future<void> _pump(WidgetTester tester, LawNode node,
    {bool collapse = true, List<String> highlight = const []}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: ParenCollapse(
        enabled: collapse,
        child: LawNodeRenderer(node, highlight: highlight),
      ),
    ),
  ));
}

String _shown(WidgetTester tester) => tester
    .widget<RichText>(find.byType(RichText).last)
    .text
    .toPlainText(includeSemanticsLabels: false);

void main() {
  final nested = _sentence(['内国法人（公益法人等（別表第二に掲げるもの）を除く。）は、納める']);

  testWidgets('parentheticals are folded to （…） and the rest stays readable',
      (tester) async {
    await _pump(tester, nested);
    expect(_shown(tester), '内国法人（…）は、納める');
  });

  testWidgets(
      'tapping （…） opens only that parenthetical, inner ones stay folded',
      (tester) async {
    await _pump(tester, nested);
    // 文字位置を指して押さないのは、（…）が読み上げ用の名前に置き換わった文で
    // 探され、位置が見つからないため。押したときと同じ処理を直接呼ぶ
    TapGestureRecognizer? tap;
    tester.widget<RichText>(find.byType(RichText).last).text.visitChildren((s) {
      if (s is TextSpan && s.recognizer is TapGestureRecognizer) {
        tap ??= s.recognizer! as TapGestureRecognizer;
      }
      return true;
    });
    tap!.onTap!();
    await tester.pump();
    expect(_shown(tester), '内国法人（公益法人等（…）を除く。）は、納める');
  });

  testWidgets('with folding off the whole sentence is shown', (tester) async {
    await _pump(tester, nested, collapse: false);
    expect(_shown(tester), '内国法人（公益法人等（別表第二に掲げるもの）を除く。）は、納める');
  });

  testWidgets('while searching, nothing is folded so matches stay visible',
      (tester) async {
    await _pump(tester, nested, highlight: const ['別表']);
    expect(_shown(tester), contains('別表第二に掲げるもの'));
  });

  testWidgets('a ruby reading is not mistaken for a parenthetical',
      (tester) async {
    await _pump(
        tester,
        _sentence([
          '次の',
          LawNode('Ruby', const {}, [
            '佃',
            LawNode('Rt', const {}, ['つくだ']),
          ]),
          'の区域（特別区を除く。）',
        ]));
    expect(_shown(tester), '次の佃（つくだ）の区域（…）');
  });

  testWidgets('a folded parenthetical is read aloud as omitted, not as dots',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, nested);
    final labels = <String>[];
    void collect(SemanticsNode n) {
      labels.add(n.label);
      n.visitChildren((c) {
        collect(c);
        return true;
      });
    }

    collect(tester.getSemantics(find.byType(RichText).last));
    expect(labels.join(), contains('括弧書き省略'));
    expect(labels.join(), isNot(contains('…')));
    handle.dispose();
  });
}
