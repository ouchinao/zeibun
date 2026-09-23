import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/search_repository.dart';
import '../../providers.dart';
import '../law_list/law_tile.dart';
import 'full_text_results.dart';

/// autoDispose にし、`searchRepositoryProvider` 経由で一覧の変化を追う。
/// keep-alive だと同期前に検索した語が空のまま固定される。
final _lawSearchProvider = FutureProvider.autoDispose
    .family<List<SearchHit>, String>(
        (ref, q) => ref.watch(searchRepositoryProvider).search(q));

class SearchResultsPage extends StatelessWidget {
  const SearchResultsPage({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('「$query」の検索結果'),
          bottom: const TabBar(tabs: [Tab(text: '法令'), Tab(text: '本文')]),
        ),
        body: TabBarView(children: [
          _LawResults(query: query),
          FullTextResults(query: query),
        ]),
      ),
    );
  }
}

class _LawResults extends ConsumerWidget {
  const _LawResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(_lawSearchProvider(query));
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('検索エラー: $e')),
      data: (hits) {
        if (hits.isEmpty) {
          return const Center(
              child: Text('該当する法令がありません。\n法令一覧の取得が済んでいるか、同期状態を確認してください。',
                  textAlign: TextAlign.center));
        }
        final jump = hits.first.article;
        return ListView.builder(
          itemCount: hits.length + (jump != null ? 1 : 0),
          itemBuilder: (context, i) {
            if (jump != null && i == 0) {
              return ListTile(
                leading: const Icon(Icons.subdirectory_arrow_right),
                title: Text('${jump.display} へジャンプ'),
                subtitle: Text('法令を選んでください（候補 ${hits.length} 件）'),
              );
            }
            final hit = hits[jump != null ? i - 1 : i];
            final art = hit.article;
            return LawTile(
              law: hit.law,
              subtitleSuffix: art?.display,
              onTap: () => context.push(art == null
                  ? '/law/${hit.law.lawId}'
                  : '/law/${hit.law.lawId}/article/${art.articleNum}'),
            );
          },
        );
      },
    );
  }
}
