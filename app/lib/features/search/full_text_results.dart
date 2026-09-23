import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/database.dart';
import '../../data/repositories/search_repository.dart';
import '../../providers.dart';
import '../../util/highlight.dart';

/// 検索条件。レコードにするのは、値が同じなら同じ Provider インスタンスを共有し、
/// フィルタを戻したときに再検索しないため。
typedef _Criteria = ({String query, bool includeSuppl, String? lawId});

final _fullTextProvider = FutureProvider.autoDispose
    .family<FullTextResult, _Criteria>((ref, c) => ref
        .watch(searchRepositoryProvider)
        .searchFullText(c.query, includeSuppl: c.includeSuppl, lawId: c.lawId));

class FullTextResults extends ConsumerStatefulWidget {
  const FullTextResults({super.key, required this.query});
  final String query;

  @override
  ConsumerState<FullTextResults> createState() => _FullTextResultsState();
}

class _FullTextResultsState extends ConsumerState<FullTextResults> {
  late _Criteria _criteria =
      (query: widget.query, includeSuppl: false, lawId: null);

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(_fullTextProvider(_criteria));
    return Column(children: [
      _Filters(
        criteria: _criteria,
        laws: result.valueOrNull?.laws ?? const [],
        onChanged: (c) => setState(() => _criteria = c),
      ),
      Expanded(
        child: result.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('検索エラー: $e')),
          data: (r) => r.hits.isEmpty
              ? const _Empty()
              : ListView.separated(
                  itemCount: r.hits.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) =>
                      _HitTile(r.hits[i], terms: r.query.terms),
                ),
        ),
      ),
    ]);
  }
}

class _Filters extends StatelessWidget {
  const _Filters(
      {required this.criteria, required this.laws, required this.onChanged});
  final _Criteria criteria;
  final List<LawHitCount> laws;
  final ValueChanged<_Criteria> onChanged;

  @override
  Widget build(BuildContext context) {
    final (:query, :includeSuppl, :lawId) = criteria;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: [
        FilterChip(
          label: const Text('附則も検索'),
          selected: includeSuppl,
          onSelected: (v) =>
              onChanged((query: query, includeSuppl: v, lawId: lawId)),
        ),
        if (laws.isNotEmpty) ...[
          const SizedBox(width: 12),
          ChoiceChip(
            label: const Text('すべて'),
            selected: lawId == null,
            onSelected: (_) => onChanged(
                (query: query, includeSuppl: includeSuppl, lawId: null)),
          ),
          for (final l in laws) ...[
            const SizedBox(width: 6),
            ChoiceChip(
              label: Text('${l.title} ${l.count}'),
              selected: lawId == l.lawId,
              onSelected: (_) => onChanged((
                query: query,
                includeSuppl: includeSuppl,
                lawId: lawId == l.lawId ? null : l.lawId,
              )),
            ),
          ],
        ],
      ]),
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile(this.hit, {required this.terms});
  final FullTextHit hit;
  final List<String> terms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final where = [
      hit.lawTitle,
      if (hit.isSuppl) '附則',
      if (hit.articleTitle case final t?) t,
      if (hit.caption case final c?) c,
    ].join(' ');
    return ListTile(
      title: Text(where, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text.rich(
        TextSpan(
            children: highlightSpans(hit.snippet, terms,
                style: TextStyle(
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    fontWeight: FontWeight.bold))),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      onTap: () => context.push(_locationOf(hit, terms)),
    );
  }
}

/// 条番号の無いヒット（附則の仮想条）を附則タブで開くのは、本則のリストには
/// その条が無く、条番号ジャンプでは着地できないため。
String _locationOf(FullTextHit hit, List<String> terms) {
  final q = Uri.encodeQueryComponent(terms.join(' '));
  return switch (hit.articleNum) {
    final n? => '/law/${hit.lawId}/article/$n?q=$q',
    null when hit.isSuppl => '/law/${hit.lawId}?tab=suppl&q=$q',
    null => '/law/${hit.lawId}?q=$q',
  };
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '該当する条文がありません。\n\n'
          '本文の検索は端末に保存した法令（一度開いた法令）が対象です。'
          '開いたことのない法令の条文は見つかりません。',
          textAlign: TextAlign.center,
        ),
      );
}
