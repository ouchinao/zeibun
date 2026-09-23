import 'package:flutter/material.dart';

import 'law_text.dart';

class TocDrawer extends StatelessWidget {
  const TocDrawer(this.articles, {super.key, required this.onSelect});
  final List<ArticleItem> articles;

  /// 条の index（本文リストの index ではない）。
  final void Function(int articleIndex) onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: articles.isEmpty
            ? const Center(child: Text('目次はまだありません'))
            : ListView.builder(
                itemCount: articles.length,
                itemBuilder: (context, i) {
                  final a = articles[i];
                  final crumb = a.breadcrumb;
                  final newCrumb = crumb != null &&
                      (i == 0 || articles[i - 1].breadcrumb != crumb);
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (newCrumb)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(crumb,
                                style: Theme.of(context).textTheme.labelLarge),
                          ),
                        ListTile(
                          dense: true,
                          title: Text(
                              '${a.articleTitle ?? ''} ${a.caption ?? ''}'
                                  .trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          onTap: () {
                            Navigator.pop(context);
                            onSelect(i);
                          },
                        ),
                      ]);
                },
              ),
      ),
    );
  }
}
