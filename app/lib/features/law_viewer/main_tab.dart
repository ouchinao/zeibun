import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../data/db/database.dart';
import '../../data/repositories/law_repository.dart';
import '../../util/format.dart';
import 'law_node_renderer.dart';
import 'law_text.dart';

/// `ListView` ではなく `ScrollablePositionedList` を使うのは、地方税法の
/// 1,348 条のように未構築の遠い条へ条番号ジャンプする必要があるため。
class MainTab extends StatelessWidget {
  const MainTab({
    super.key,
    required this.law,
    required this.text,
    required this.highlight,
    required this.scrollController,
    required this.onLongPress,
    required this.onRetry,
  });

  /// 条の index → リストの index の変換に使う。ジャンプ・検索・目次で
  /// 個別に +1 していたときに 1 条ずれる不具合を出したため、ここに集約する。
  static const headerItems = 1;

  final Law law;
  final AsyncValue<LawText> text;
  final List<String> highlight;
  final ItemScrollController scrollController;
  final void Function(ArticleItem) onLongPress;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final value = text.value;
    final articles = value?.main ?? const <ArticleItem>[];
    final header = _HeaderCard(law: law, text: value, loading: text.isLoading);
    if (articles.isEmpty) {
      return ListView(children: [
        header,
        if (text.isLoading)
          const _Skeleton()
        else
          _Unavailable(
            text.hasError
                ? '本文の読み込みでエラーが発生しました: ${text.error}'
                : '本文を取得できませんでした。オンラインで再試行してください。',
            onRetry: onRetry,
          ),
      ]);
    }
    return ScrollablePositionedList.builder(
      itemScrollController: scrollController,
      itemCount: articles.length + headerItems,
      itemBuilder: (context, i) {
        if (i == 0) return header;
        final a = articles[i - headerItems];
        return _ArticleCard(
          article: a,
          highlight: highlight,
          onLongPress: () => onLongPress(a),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard(
      {required this.law, required this.text, required this.loading});
  final Law law;
  final LawText? text;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(law.lawNum, style: small),
        Text(law.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Wrap(spacing: 12, runSpacing: 2, children: [
          Text('${lawTypeLabel(law.lawType)} · ${law.category ?? ''}',
              style: small),
          Text('施行 ${formatDate(law.currentEnforcedAt)}', style: small),
          if (law.amendmentLawTitle != null)
            Text('改正 ${law.amendmentLawTitle}', style: small),
        ]),
        Text(
          '取得 ${formatIso(law.bodySyncedAt)} · リビジョン ${law.bodyRevisionId ?? '—'}'
          '${law.bodyIncludesAmendSuppl ? ' · 改正附則込み' : ''}',
          style: small?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (law.isReference)
          _Notice(
              '${repealStatusLabel(law.repealStatus)}（${law.repealDate ?? '—'}）。現在は効力のない法令です（参考）',
              scheme.surfaceContainerHighest),
        if (law.pendingRevisionId != null)
          _Notice('未施行の改正があります。改正履歴タブで施行予定日を確認できます', scheme.tertiaryContainer),
        if (_fetchNotice() case final n?) _Notice(n, scheme.errorContainer),
        if (loading) const LinearProgressIndicator(),
        const Divider(),
      ]),
    );
  }

  String? _fetchNotice() {
    final t = text;
    if (t == null) return null;
    final why = switch (t.failure) {
      null => '',
      BodyFailure.offline => 'オフラインのため',
      BodyFailure.server => 'e-Gov から取得できず',
      BodyFailure.invalidData => '取得した本文を検証できず',
    };
    return switch (t.status) {
      BodyStatus.stale =>
        '${formatIso(law.bodySyncedAt)} 時点の内容です。$why最新（施行 ${law.currentEnforcedAt ?? '—'}）を取得できていません',
      BodyStatus.unavailable => '$why本文を取得できていません',
      BodyStatus.fresh || BodyStatus.fetched => null,
    };
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(8),
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        for (var i = 0; i < 8; i++)
          Container(
              height: 14,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 8),
        const Text('最新の条文を取得しています…'),
      ]),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable(this.message, {required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('再試行')),
        ]),
      );
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard(
      {required this.article,
      required this.highlight,
      required this.onLongPress});
  final ArticleItem article;
  final List<String> highlight;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (article.breadcrumb case final crumb?)
            Text(crumb,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          if (article.section == 'appdx' && article.articleTitle != null)
            Text(article.articleTitle!, style: theme.textTheme.titleMedium),
          LawNodeRenderer(article.body, highlight: highlight),
        ]),
      ),
    );
  }
}
