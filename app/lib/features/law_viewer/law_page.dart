import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zeibun_core/zeibun_core.dart';

import '../../data/db/database.dart';
import '../../data/repositories/law_repository.dart';
import '../../providers.dart';
import '../../util/format.dart';
import 'law_body_controller.dart';
import 'law_node_renderer.dart';

/// 法令閲覧。本文 / 附則 / 改正履歴のタブ、目次ドロワー、本文内検索。
///
/// 本文に `ListView` ではなく `ScrollablePositionedList` を使うのは、地方税法の
/// 1,348 条のように未構築の遠い条へ条番号ジャンプする必要があるため。
/// 附則を本文と同じリストに並べないのは、所得税法の全文で附則が 1,000 件を超え、
/// 本則を読む邪魔になるから（改正法令ごとに折りたたむ）。
class LawPage extends ConsumerStatefulWidget {
  const LawPage(
      {super.key, required this.lawId, this.articleNum, this.initialTab});

  final String lawId;

  /// 開いたときにスクロールする条（`Article@Num` 形式）。
  final String? articleNum;
  final String? initialTab;

  @override
  ConsumerState<LawPage> createState() => _LawPageState();
}

class _LawPageState extends ConsumerState<LawPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _mainScroll = ItemScrollController();
  final _mainListener = ItemPositionsListener.create();
  final _searchController = TextEditingController();
  bool _searchOpen = false;
  String _query = '';
  List<int> _matches = const [];
  int _matchCursor = 0;
  bool _jumped = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 3,
        vsync: this,
        initialIndex: switch (widget.initialTab) {
          'suppl' => 1,
          'revisions' => 2,
          _ => 0,
        });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ helpers

  List<Article> _mainArticles(List<Article> all) =>
      all.where((a) => a.section == 'main' || a.section == 'appdx').toList();

  void _jumpToInitialArticle(List<Article> main) {
    if (_jumped || widget.articleNum == null) return;
    final i = main.indexWhere((a) => a.articleNum == widget.articleNum);
    _jumped = true;
    if (i >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mainScroll.isAttached) _mainScroll.jumpTo(index: i);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '第${widget.articleNum!.replaceAll('_', '条の')}条 は見つかりませんでした')));
      });
    }
  }

  void _runSearch(String q, List<Article> main) {
    final n = normalizeForSearch(q);
    final matches = <int>[];
    if (n.isNotEmpty) {
      for (var i = 0; i < main.length; i++) {
        if (main[i].plainText.toLowerCase().contains(n)) matches.add(i);
      }
    }
    setState(() {
      _query = n;
      _matches = matches;
      _matchCursor = 0;
    });
    if (matches.isNotEmpty) _scrollTo(matches.first);
  }

  void _stepMatch(int delta) {
    if (_matches.isEmpty) return;
    setState(() {
      _matchCursor = (_matchCursor + delta) % _matches.length;
      if (_matchCursor < 0) _matchCursor += _matches.length;
    });
    _scrollTo(_matches[_matchCursor]);
  }

  void _scrollTo(int index) {
    if (_mainScroll.isAttached) {
      _mainScroll.scrollTo(
          index: index, duration: const Duration(milliseconds: 250));
    }
  }

  Future<void> _articleMenu(Law law, Article a) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('条文をコピー'),
              onTap: () => Navigator.pop(c, 'copy')),
          ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('e-Gov で開く'),
              onTap: () => Navigator.pop(c, 'egov')),
        ]),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'copy') {
      final text = '${law.title} ${a.articleTitle ?? ''}${a.caption ?? ''}\n'
          '${a.plainText}\n'
          '（出典: e-Gov法令検索 ${law.bodyRevisionId ?? ''} 取得 ${formatIso(law.bodySyncedAt)}）';
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('コピーしました')));
      }
    } else if (choice == 'egov') {
      await launchUrl(EgovRequests.egovLawPage(law.lawId),
          mode: LaunchMode.externalApplication);
    }
  }

  // -------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final lawAsync = ref.watch(lawStreamProvider(widget.lawId));
    final bodyAsync = ref.watch(lawBodyProvider(widget.lawId));
    final law = lawAsync.valueOrNull;
    final body = bodyAsync.valueOrNull;
    final all = body?.articles ?? const <Article>[];
    final main = _mainArticles(all);
    if (body != null) _jumpToInitialArticle(main);

    return Scaffold(
      appBar: AppBar(
        title: Text(law?.title ?? '読み込み中…', overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(_searchOpen ? Icons.search_off : Icons.search),
            tooltip: '本文内検索',
            onPressed: () => setState(() {
              _searchOpen = !_searchOpen;
              if (!_searchOpen) {
                _query = '';
                _matches = const [];
                _searchController.clear();
              }
            }),
          ),
          Builder(
            builder: (c) => IconButton(
              icon: const Icon(Icons.toc),
              tooltip: '目次',
              onPressed: () => Scaffold.of(c).openEndDrawer(),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_searchOpen ? 104 : 48),
          child: Column(children: [
            if (_searchOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 4, 4),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'この法令内を検索',
                        border: const OutlineInputBorder(),
                        suffixText: _matches.isEmpty
                            ? (_query.isEmpty ? null : '0 件')
                            : '${_matchCursor + 1}/${_matches.length}',
                      ),
                      onSubmitted: (q) => _runSearch(q, main),
                    ),
                  ),
                  IconButton(
                      icon: const Icon(Icons.keyboard_arrow_up),
                      onPressed: () => _stepMatch(-1)),
                  IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      onPressed: () => _stepMatch(1)),
                ]),
              ),
            TabBar(controller: _tabs, tabs: const [
              Tab(text: '本文'),
              Tab(text: '附則'),
              Tab(text: '改正履歴'),
            ]),
          ]),
        ),
      ),
      endDrawer: law == null ? null : _TocDrawer(main, onSelect: _scrollTo),
      body: law == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabs, children: [
              _MainTab(
                law: law,
                bodyAsync: bodyAsync,
                articles: main,
                highlight: _query.isEmpty ? null : _query,
                scrollController: _mainScroll,
                positionsListener: _mainListener,
                onLongPress: (a) => _articleMenu(law, a),
                onRetry: () =>
                    ref.read(lawBodyProvider(widget.lawId).notifier).refresh(),
              ),
              _SupplTab(
                law: law,
                articles: all.where((a) => a.section == 'suppl').toList(),
                loading: bodyAsync.isLoading,
                highlight: _query.isEmpty ? null : _query,
                onLoadAmendSuppl: () => ref
                    .read(lawBodyProvider(widget.lawId).notifier)
                    .loadAmendSuppl(),
              ),
              _RevisionsTab(lawId: widget.lawId, law: law),
            ]),
    );
  }
}

// ------------------------------------------------------------------ 本文

class _MainTab extends StatelessWidget {
  const _MainTab({
    required this.law,
    required this.bodyAsync,
    required this.articles,
    required this.highlight,
    required this.scrollController,
    required this.positionsListener,
    required this.onLongPress,
    required this.onRetry,
  });

  final Law law;
  final AsyncValue<BodyLoadResult> bodyAsync;
  final List<Article> articles;
  final String? highlight;
  final ItemScrollController scrollController;
  final ItemPositionsListener positionsListener;
  final void Function(Article) onLongPress;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final status = bodyAsync.valueOrNull?.status;
    final header =
        _HeaderCard(law: law, status: status, loading: bodyAsync.isLoading);
    if (bodyAsync.isLoading && articles.isEmpty) {
      return ListView(children: [header, const _Skeleton()]);
    }
    if (articles.isEmpty) {
      return ListView(children: [
        header,
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Text('本文を取得できませんでした。オンラインで再試行してください。'),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('再試行')),
          ]),
        ),
      ]);
    }
    return ScrollablePositionedList.builder(
      itemScrollController: scrollController,
      itemPositionsListener: positionsListener,
      itemCount: articles.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return header;
        final a = articles[i - 1];
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
      {required this.law, required this.status, required this.loading});
  final Law law;
  final BodyStatus? status;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.bodySmall;
    final isRef = law.repealStatus != 'None';
    final notice = switch (status) {
      BodyStatus.stale => (
          '${formatIso(law.bodySyncedAt)} 時点の内容です。最新（施行 ${law.currentEnforcedAt ?? '—'}）を取得できていません',
          scheme.errorContainer
        ),
      BodyStatus.unavailable => ('本文を取得できていません', scheme.errorContainer),
      _ => null,
    };
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
        if (isRef)
          _Notice(
              '${repealStatusLabel(law.repealStatus)}（${law.repealDate ?? '—'}）。現在は効力のない法令です（参考）',
              scheme.surfaceContainerHighest),
        if (law.pendingRevisionId != null)
          _Notice('未施行の改正があります。改正履歴タブで施行予定日を確認できます', scheme.tertiaryContainer),
        if (notice != null) _Notice(notice.$1, notice.$2),
        if (loading) const LinearProgressIndicator(),
        const Divider(),
      ]),
    );
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

class _ArticleCard extends StatelessWidget {
  const _ArticleCard(
      {required this.article,
      required this.highlight,
      required this.onLongPress});
  final Article article;
  final String? highlight;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final node =
        LawNode.fromJson(jsonDecode(article.bodyJson) as Map<String, dynamic>);
    return InkWell(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (article.breadcrumb != null)
            Text(article.breadcrumb!,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          if (article.section == 'appdx' && article.articleTitle != null)
            Text(article.articleTitle!,
                style: Theme.of(context).textTheme.titleMedium),
          LawNodeRenderer(node, highlight: highlight),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ 目次

class _TocDrawer extends StatelessWidget {
  const _TocDrawer(this.articles, {required this.onSelect});
  final List<Article> articles;
  final void Function(int index) onSelect;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    String? lastCrumb;
    for (var i = 0; i < articles.length; i++) {
      final a = articles[i];
      if (a.breadcrumb != lastCrumb && a.breadcrumb != null) {
        lastCrumb = a.breadcrumb;
        items.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(a.breadcrumb!,
              style: Theme.of(context).textTheme.labelLarge),
        ));
      }
      items.add(ListTile(
        dense: true,
        title: Text('${a.articleTitle ?? ''} ${a.caption ?? ''}'.trim(),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () {
          Navigator.pop(context);
          onSelect(i + 1); // 本文リストの 0 番目はヘッダカードなので 1 つずらす
        },
      ));
    }
    return Drawer(
      child: SafeArea(
        child: items.isEmpty
            ? const Center(child: Text('目次はまだありません'))
            : ListView(children: items),
      ),
    );
  }
}

// ------------------------------------------------------------------ 附則

class _SupplTab extends StatelessWidget {
  const _SupplTab({
    required this.law,
    required this.articles,
    required this.loading,
    required this.highlight,
    required this.onLoadAmendSuppl,
  });
  final Law law;
  final List<Article> articles;
  final bool loading;
  final String? highlight;
  final VoidCallback onLoadAmendSuppl;

  @override
  Widget build(BuildContext context) {
    // 改正法令番号ごとにまとめ、新しいもの（後ろにあるもの）から表示。制定時の附則は最後
    final groups = <String?, List<Article>>{};
    for (final a in articles) {
      groups.putIfAbsent(a.supplAmendLawNum, () => []).add(a);
    }
    final keys = groups.keys.where((k) => k != null).toList().reversed.toList();
    if (groups.containsKey(null)) keys.add(null);
    return ListView(
      children: [
        if (!law.bodyIncludesAmendSuppl)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '改正法令の附則（各改正の施行期日・経過措置）は既定では読み込んでいません。'
                    '必要なときに読み込むと、この法令は以後も改正附則込みで保存されます。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: loading ? null : onLoadAmendSuppl,
                    icon: const Icon(Icons.download),
                    label: const Text('改正附則を読み込む'),
                  ),
                  if (loading)
                    const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator()),
                ]),
          ),
        if (articles.isEmpty && !loading)
          const Padding(padding: EdgeInsets.all(16), child: Text('附則はありません')),
        for (final k in keys)
          ExpansionTile(
            initiallyExpanded: k == keys.first,
            title: Text(k ?? '附則（制定時）'),
            subtitle: Text('${groups[k]!.length} 項目'),
            children: [
              for (final a in groups[k]!)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: LawNodeRenderer(
                    LawNode.fromJson(
                        jsonDecode(a.bodyJson) as Map<String, dynamic>),
                    highlight: highlight,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// -------------------------------------------------------------- 改正履歴

final _revisionsProvider = FutureProvider.family
    .autoDispose<List<LawRevision>, String>((ref, lawId) =>
        ref.watch(lawRepositoryProvider).refreshRevisions(lawId));

class _RevisionsTab extends ConsumerWidget {
  const _RevisionsTab({required this.lawId, required this.law});
  final String lawId;
  final Law law;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revs = ref.watch(_revisionsProvider(lawId));
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return revs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('取得できませんでした: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return const Center(child: Text('改正履歴を取得できませんでした（オフライン？）'));
        }
        final scheme = Theme.of(context).colorScheme;
        return ListView.separated(
          itemCount: rows.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final r = rows[i];
            final future =
                r.enforcedAt.compareTo(today) > 0 || r.status == 'UnEnforced';
            final current = r.revisionId == law.currentRevisionId;
            return ListTile(
              leading: Icon(
                future
                    ? Icons.schedule
                    : current
                        ? Icons.check_circle
                        : Icons.history,
                color: future
                    ? scheme.tertiary
                    : current
                        ? scheme.primary
                        : scheme.outline,
              ),
              title: Text(
                future
                    ? '施行予定 ${formatDate(r.enforcedAt)}'
                    : '施行 ${formatDate(r.enforcedAt)}',
                style: future
                    ? TextStyle(
                        color: scheme.tertiary, fontWeight: FontWeight.w600)
                    : null,
              ),
              subtitle: Text([
                if (r.amendmentLawTitle != null) r.amendmentLawTitle!,
                if (r.amendmentLawNum != null) r.amendmentLawNum!,
                if (r.enforcementComment != null) r.enforcementComment!,
                if (current) '現行',
              ].join('\n')),
              isThreeLine: true,
            );
          },
        );
      },
    );
  }
}
