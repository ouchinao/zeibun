import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zeibun_core/zeibun_core.dart';

import '../../data/db/database.dart';
import '../../util/format.dart';
import 'law_text.dart';

enum ArticleAction { copy, openInEgov }

Future<void> showArticleMenu(BuildContext context,
    {required Law law, required ArticleItem article}) async {
  final action = await showModalBottomSheet<ArticleAction>(
    context: context,
    builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
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
  if (!context.mounted) return;
  switch (action) {
    case null:
      return;
    case ArticleAction.copy:
      await Clipboard.setData(ClipboardData(text: _citation(law, article)));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('コピーしました')));
      }
    case ArticleAction.openInEgov:
      await launchUrl(EgovRequests.egovLawPage(law.lawId),
          mode: LaunchMode.externalApplication);
  }
}

String _citation(Law law, ArticleItem a) =>
    '${law.title} ${a.articleTitle ?? ''}${a.caption ?? ''}\n'
    '${a.plainText}\n'
    '（出典: e-Gov法令検索 ${law.bodyRevisionId ?? ''} 取得 ${formatIso(law.bodySyncedAt)}）';
