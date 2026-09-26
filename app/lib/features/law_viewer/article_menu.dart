import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeibun_core/zeibun_core.dart';

import '../../data/db/database.dart';
import '../../util/external_link.dart';
import '../../util/format.dart';
import 'law_text.dart';

enum ArticleAction { copy, openInEgov, toggleBookmark }

/// 条を長押ししたときのメニュー。選ばれた項目を返すだけで、実行は
/// [performArticleAction] が行う（表示と副作用を 1 関数に混ぜない）。
///
/// [bookmarked] が null の条（条番号の無い仮想条）にはブックマークの項目を
/// 出さない。条番号が無いと再訪先を指せないため。
Future<ArticleAction?> showArticleMenu(BuildContext context,
        {required bool? bookmarked}) =>
    showModalBottomSheet<ArticleAction>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (bookmarked != null)
            ListTile(
                leading:
                    Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
                title: Text(bookmarked ? 'ブックマークを外す' : 'ブックマークに追加'),
                onTap: () => Navigator.pop(c, ArticleAction.toggleBookmark)),
          ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('条文をコピー'),
              onTap: () => Navigator.pop(c, ArticleAction.copy)),
          ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('e-Gov で開く'),
              onTap: () => Navigator.pop(c, ArticleAction.openInEgov)),
        ]),
      ),
    );

Future<void> performArticleAction(
  BuildContext context,
  ArticleAction action, {
  required Law law,
  required ArticleItem article,
  required Future<bool> Function() toggleBookmark,
}) async {
  switch (action) {
    case ArticleAction.toggleBookmark:
      final added = await toggleBookmark();
      if (!context.mounted) return;
      _notify(context, added ? 'ブックマークに追加しました' : 'ブックマークを外しました');
    case ArticleAction.copy:
      await Clipboard.setData(ClipboardData(text: _citation(law, article)));
      if (!context.mounted) return;
      _notify(context, 'コピーしました');
    case ArticleAction.openInEgov:
      await openExternal(context, EgovRequests.egovLawPage(law.lawId));
  }
}

void _notify(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

String _citation(Law law, ArticleItem a) =>
    '${law.title} ${a.articleTitle ?? ''}${a.caption ?? ''}\n'
    '${a.plainText}\n'
    '（出典: e-Gov法令検索 ${law.bodyRevisionId ?? ''} 取得 ${formatIso(law.bodySyncedAt)}）';
