import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:zeibun_core/zeibun_core.dart';

import '../../providers.dart';
import 'article_menu.dart';
import 'law_body_controller.dart';
import 'law_text.dart';
import 'main_tab.dart';
import 'revisions_tab.dart';
import 'suppl_tab.dart';
import 'toc_drawer.dart';

/// 法令閲覧。本文 / 附則 / 改正履歴のタブ、目次ドロワー、本文内検索。
///
/// 附則を本文と同じリストに並べないのは、所得税法の全文で附則が 1,000 件を超え、
/// 本則を読む邪魔になるから（改正法令ごとに折りたたむ）。
class LawPage extends ConsumerStatefulWidget {
  const LawPage({
    super.key,
    required this.lawId,
    this.articleNum,
    this.initialTab,
    this.initialQuery,
  });

  final String lawId;

  /// 開いたときにスクロールする条（`Article@Num` 形式）。
  final String? articleNum;
  final String? initialTab;
  final String? initialQuery;

  @override
  ConsumerState<LawPage> createState() => _LawPageState();
}

/// 本文内検索の状態。閉じているときは null にして、開閉フラグと語・一致位置を
/// 別々の bool と変数で持たない。
class _TextSearch {
  const _TextSearch(
      {this.terms = const [], this.matches = const [], this.cursor = 0});

  final List<String> terms;
  final List<int> matches;
  final int cursor;

  int? get currentMatch => matches.isEmpty ? null : matches[cursor];
  String? get counter => matches.isEmpty
      ? (terms.isEmpty ? null : '0 件')
      : '${cursor + 1}/${matches.length}';

  _TextSearch step(int delta) => _TextSearch(
      terms: terms,
      matches: matches,
      cursor: (cursor + delta) % matches.length);
}

class _LawPageState extends ConsumerState<LawPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _mainScroll = ItemScrollController();
  final _searchController = TextEditingController();
  _TextSearch? _search;

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

  /// [articleIndex] は本文の条の index（0 始まり）。
  void _scrollTo(int articleIndex, {bool animate = true}) {
    if (!_mainScroll.isAttached) return;
    final index = articleIndex + MainTab.headerItems;
    if (animate) {
      _mainScroll.scrollTo(
          index: index, duration: const Duration(milliseconds: 250));
    } else {
      _mainScroll.jumpTo(index: index);
    }
  }

  void _jumpToInitialArticle(LawText text) {
    final num = widget.articleNum;
    if (num == null) return;
    final i = text.main.indexWhere((a) => a.articleNum == num);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (i >= 0) {
        _scrollTo(i, animate: false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${articleNumDisplay(num)} は見つかりませんでした')));
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      if (_search == null) {
        _search = const _TextSearch();
      } else {
        _search = null;
        _searchController.clear();
      }
    });
  }

  /// 現在位置を先頭の一致に固定しないのは、検索結果から条を指定して開いたとき、
  /// その条より前の一致へ飛び戻らないため（[startAt] 以降で最初の一致にする）。
  void _runSearch(String q, List<ArticleItem> main,
      {bool scroll = true, int startAt = 0}) {
    final terms = splitSearchTerms(q);
    final matches = [
      if (terms.isNotEmpty)
        for (var i = 0; i < main.length; i++)
          if (terms.every(normalizeForMatch(main[i].plainText).contains)) i,
    ];
    var cursor = matches.indexWhere((i) => i >= startAt);
    if (cursor < 0) cursor = 0;
    setState(() =>
        _search = _TextSearch(terms: terms, matches: matches, cursor: cursor));
    if (scroll && matches.isNotEmpty) _scrollTo(matches[cursor]);
  }

  /// ここでスクロールしないのは、条番号ジャンプと合わせて 2 回動くと目が迷うため。
  void _applyInitialQuery(LawText text) {
    final q = widget.initialQuery;
    if (q == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchController.text = q;
      final at = text.main.indexWhere((a) => a.articleNum == widget.articleNum);
      _runSearch(q, text.main, scroll: false, startAt: at < 0 ? 0 : at);
    });
  }

  void _stepMatch(int delta) {
    final s = _search;
    if (s == null || s.matches.isEmpty) return;
    final next = s.step(delta);
    setState(() => _search = next);
    _scrollTo(next.currentMatch!);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(lawBodyProvider(widget.lawId), (prev, next) {
      final text = next.valueOrNull;
      if (prev?.valueOrNull == null && text != null) {
        _jumpToInitialArticle(text);
        _applyInitialQuery(text);
      }
    });
    final law = ref.watch(lawStreamProvider(widget.lawId)).valueOrNull;
    final textAsync = ref.watch(lawBodyProvider(widget.lawId));
    final text = textAsync.valueOrNull;
    final main = text?.main ?? const <ArticleItem>[];
    final search = _search;

    return Scaffold(
      appBar: AppBar(
        title: Text(law?.title ?? '読み込み中…', overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(search == null ? Icons.search : Icons.search_off),
            tooltip: '本文内検索',
            onPressed: _toggleSearch,
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
          preferredSize: Size.fromHeight(search == null ? 48 : 104),
          child: Column(children: [
            if (search != null)
              _SearchBar(
                controller: _searchController,
                counter: search.counter,
                onSubmitted: (q) => _runSearch(q, main),
                onStep: _stepMatch,
              ),
            TabBar(controller: _tabs, tabs: const [
              Tab(text: '本文'),
              Tab(text: '附則'),
              Tab(text: '改正履歴'),
            ]),
          ]),
        ),
      ),
      endDrawer: law == null ? null : TocDrawer(main, onSelect: _scrollTo),
      body: law == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabs, children: [
              MainTab(
                law: law,
                text: textAsync,
                highlight: search?.terms ?? const [],
                scrollController: _mainScroll,
                onLongPress: (a) =>
                    showArticleMenu(context, law: law, article: a),
                onRetry: () =>
                    ref.read(lawBodyProvider(widget.lawId).notifier).refresh(),
              ),
              SupplTab(
                law: law,
                groups: text?.supplGroups ?? const [],
                loading: textAsync.isLoading,
                highlight: search?.terms ?? const [],
                onLoadAmendSuppl: () => ref
                    .read(lawBodyProvider(widget.lawId).notifier)
                    .loadAmendSuppl(),
              ),
              RevisionsTab(law: law),
            ]),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.counter,
    required this.onSubmitted,
    required this.onStep,
  });
  final TextEditingController controller;
  final String? counter;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 4, 4),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'この法令内を検索',
                border: const OutlineInputBorder(),
                suffixText: counter,
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: () => onStep(-1)),
          IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => onStep(1)),
        ]),
      );
}
