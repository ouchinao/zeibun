import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zeibun_core/zeibun_core.dart';

/// 検索語に合うテーマと、よく参照する条の一覧（設計書 §6）。
///
/// テーマを別のタブにしないのは、「インボイス」のように法令名にも本文にも出てこない
/// 語では、先に見える法令タブが空になり、何も見つからないように見えるため。
class TopicSection extends StatelessWidget {
  const TopicSection({super.key, required this.topics});
  final List<Topic> topics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final topic in topics) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Semantics(
              header: true,
              child: Text('テーマ「${topic.name}」でよく参照する条',
                  style: theme.textTheme.titleSmall),
            ),
          ),
          for (final a in topic.articles)
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: Text('${a.lawTitle} ${a.articleTitle}'),
              subtitle: Text(a.caption),
              onTap: () =>
                  context.push('/law/${a.lawId}/article/${a.articleNum}'),
            ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'よく参照する条の案内です。どの規定が当てはまるかは、条文で確かめてください。',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
