import 'package:flutter/material.dart';

/// タブの見出し。文字の拡大に上限を付ける。
///
/// 端末の文字サイズにそのまま合わせないのは、タブの高さが固定で、最大の文字では
/// 下が切れ、3 つのタブが横に収まらず「改正履歴」が途中で切れるため。iOS 標準の
/// タブバーも大きな文字では拡大しない。上限は幅 375pt の端末で 3 つ並べて収まる値。
class TabLabel extends StatelessWidget {
  const TabLabel(this.text, {super.key});

  static const maxScale = 1.5;

  final String text;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: maxScale,
        child: Text(text, softWrap: false, overflow: TextOverflow.fade),
      );
}
