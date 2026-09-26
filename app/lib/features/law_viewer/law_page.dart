import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:zeibun_core/zeibun_core.dart';

import '../../data/db/database.dart';
import '../../providers.dart';
import '../bookmarks/bookmark_law_button.dart';
import 'article_menu.dart';
import 'in_text_search.dart';
import 'in_text_search_controller.dart';
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

class _LawPageState extends ConsumerState<LawPage>
    with SingleTickerProviderStateMixin {
  static const _mainTab = 0;
  static const _supplTab = 1;

  late final TabController _tabs;
  final _mainScroll = ItemScrollController();
  final _searchController = TextEditingController();

  InTextSearchController get _search =>
      ref.read(inTextSearchProvider(widget.lawId).notifier);

  /// 別の状態として持たず現在の一致から導く。持つと、検索を閉じたときや
  /// 本則側へ戻ったときに消し忘れる。
  static SupplFocus? _supplFocusOf(InTextSearch? s) => switch (s?.current) {
        (part: TextPart.suppl, :final group, :final index) => (
            group: group,
            article: index
          ),
        _ => null,
      };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 3,
        vsync: this,
        initialIndex: switch (widget.initialTab) {
          'suppl' => _supplTab,
          'revisions' => 2,
          _ => _mainTab,
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

  /// 本文タブへ切り替えた直後にそのままスクロールしないのは、本則のリストが
  /// 本文タブの表示まで組み立てられず、同じフレームでは動かせないため。
  void _reveal(TextHit hit) {
    switch (hit.part) {
      case TextPart.main:
        if (_tabs.index == _mainTab) {
          _scrollTo(hit.index);
        } else {
          _tabs.animateTo(_mainTab);
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollTo(hit.index));
        }
      case TextPart.suppl:
        _tabs.animateTo(_supplTab);
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

  /// ブックマークの現在値をメニューを開く前に一回だけ読むのは、メニューの
  /// 項目名を「追加」「外す」で出し分けるため。
  Future<void> _openArticleMenu(Law law, ArticleItem a) async {
    final num = a.articleNum;
    final repo = ref.read(bookmarkRepositoryProvider);
    final bookmarked = num == null
        ? null
        : await repo.isBookmarked(law.lawId, articleNum: num);
    if (!mounted) return;
    final action = await showArticleMenu(context, bookmarked: bookmarked);
    if (action == null || !mounted) return;
    await performArticleAction(
      context,
      action,
      law: law,
      article: a,
      toggleBookmark: () => repo.toggle(law.lawId, articleNum: num),
    );
  }

  void _toggleSearch() {
    _search.toggle();
    if (!_search.isOpen) _searchController.clear();
  }

  void _runSearch(LawText text, String q, {required bool includeSuppl}) {
    final next = _search.run(text, q, includeSuppl: includeSuppl);
    if (next.current case final hit?) _reveal(hit);
  }

  /// ここでスクロールしないのは、条番号ジャンプと合わせて 2 回動くと目が迷うため。
  void _applyInitialQuery(LawText text) {
    final q = widget.initialQuery;
    if (q == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchController.text = q;
      final at = text.main.indexWhere((a) => a.articleNum == widget.articleNum);
      _search.run(text, q, includeSuppl: false, startAt: at < 0 ? 0 : at);
    });
  }

  void _stepMatch(int delta) {
    if (_search.step(delta)?.current case final hit?) _reveal(hit);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(lawBodyProvider(widget.lawId), (prev, next) {
      final text = next.value;
      if (prev?.value == null && text != null) {
        _jumpToInitialArticle(text);
        _applyInitialQuery(text);
      }
    });
    final law = ref.watch(lawStreamProvider(widget.lawId)).value;
    final textAsync = ref.watch(lawBodyProvider(widget.lawId));
    final text = textAsync.value;
    final main = text?.main ?? const <ArticleItem>[];
    final search = ref.watch(inTextSearchProvider(widget.lawId));
    final highlight = search?.terms ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(law?.title ?? '読み込み中…', overflow: TextOverflow.ellipsis),
        actions: [
          BookmarkLawButton(lawId: widget.lawId),
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
                includeSuppl: search.includeSuppl,
                onSubmitted: text == null
                    ? null
                    : (q) =>
                        _runSearch(text, q, includeSuppl: search.includeSuppl),
                onIncludeSuppl: text == null
                    ? null
                    : (v) => _runSearch(text, _searchController.text,
                        includeSuppl: v),
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
                highlight: highlight,
                scrollController: _mainScroll,
                onLongPress: (a) => _openArticleMenu(law, a),
                onRetry: () =>
                    ref.read(lawBodyProvider(widget.lawId).notifier).refresh(),
              ),
              SupplTab(
                law: law,
                text: textAsync,
                highlight: highlight,
                focus: _supplFocusOf(search),
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
    required this.includeSuppl,
    required this.onSubmitted,
    required this.onIncludeSuppl,
    required this.onStep,
  });
  final TextEditingController controller;
  final String? counter;
  final bool includeSuppl;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<bool>? onIncludeSuppl;
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
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('附則'),
            tooltip: '附則も検索する',
            selected: includeSuppl,
            visualDensity: VisualDensity.compact,
            onSelected: onIncludeSuppl,
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
