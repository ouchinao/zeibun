import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
    required this.onToggleBookmark,
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
  final void Function(ArticleItem) onToggleBookmark;
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
            // 分類できる失敗は `LawText.failure` でヘッダに出る。ここに来るのは
            // Repository が分類できず投げ直した例外だけなので、文言は固定にする
            text.hasError
                ? '本文の読み込みで想定外のエラーが発生しました'
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
          onToggleBookmark:
              a.articleNum == null ? null : () => onToggleBookmark(a),
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
        Semantics(
            header: true,
            child:
                Text(law.title, style: Theme.of(context).textTheme.titleLarge)),
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
              scheme.surfaceContainerHighest,
              scheme.onSurface),
        if (law.pendingRevisionId != null)
          _Notice('未施行の改正があります。改正履歴タブで施行予定日を確認できます', scheme.tertiaryContainer,
              scheme.onTertiaryContainer),
        if (_fetchNotice() case final n?)
          _Notice(n, scheme.errorContainer, scheme.onErrorContainer),
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
      FetchFailure.offline => 'オフラインのため',
      FetchFailure.server => 'e-Gov から取得できず',
      FetchFailure.maintenance => 'e-Gov 法令検索のメンテナンス中のため',
      FetchFailure.invalidData => '取得した本文を検証できず',
      FetchFailure.storageFull => '端末の空き容量が足りず保存できず',
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
  const _Notice(this.text, this.color, this.onColor);
  final String text;
  final Color color;

  /// 背景と対になる文字色。本文の既定色にしないのは、「コントラストを上げる」で
  /// 背景だけ明るくなり、文字との差が 4.5:1 を割るため。
  final Color onColor;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(8),
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: onColor)),
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
      required this.onLongPress,
      required this.onToggleBookmark});
  final ArticleItem article;
  final List<String> highlight;
  final VoidCallback onLongPress;

  /// 仮想条で null にするのは、条番号が無く再訪先を指せないため（長押しメニューと同じ）。
  final VoidCallback? onToggleBookmark;

  /// onLongPressHint にしないのは、iOS では無視されるため。
  static const _longPressHint = '長押しでメニューを開きます';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ボタンを足さずに読み上げの操作一覧に出すのは、見た目を変えないため。
    // 長押しだけではスクリーンリーダーの利用者にメニューの存在が伝わらない。
    // 操作の名前を「ブックマークに追加・外す」だけにしないのは、項や号に
    // フォーカスしているとき、どの条をブックマークするのか分からないため
    final actions = {
      if (onToggleBookmark case final toggle?)
        CustomSemanticsAction(
            label: '${article.articleTitle ?? ''}をブックマークに追加・外す'): toggle,
    };
    return Semantics(
      // 条の名前を省かないのは、中の章見出しなどの名前を借りてしまうため。
      // 操作とヒントをここに付けないのは、項・号ごとの節点と重なり、読み上げで
      // 条の名前と操作が二重に出るため
      label: [article.articleTitle, article.caption].nonNulls.join(),
      child: InkWell(
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (article.breadcrumb case final crumb?)
              Semantics(
                  header: true,
                  child: Text(crumb,
                      style: theme.textTheme.labelSmall?.copyWith(
                          // outline は小さい文字でコントラスト 4.5:1 に届かない
                          color: theme.colorScheme.onSurfaceVariant))),
            if (article.section == ArticleSection.appdx &&
                article.articleTitle != null)
              Semantics(
                  hint: _longPressHint,
                  customSemanticsActions: actions,
                  child: Text(article.articleTitle!,
                      style: theme.textTheme.titleMedium)),
            LawNodeRenderer(article.body,
                highlight: highlight,
                semanticsActions: actions,
                semanticsHint: _longPressHint),
          ]),
        ),
      ),
    );
  }
}
