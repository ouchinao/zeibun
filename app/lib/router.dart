import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeibun_core/zeibun_core.dart';

import 'features/home/home_page.dart';
import 'features/law_list/law_list_page.dart';
import 'features/law_viewer/law_page.dart';
import 'features/search/search_results_page.dart';
import 'features/prefetch/prefetch_page.dart';
import 'features/settings/settings_page.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// 画面遷移（設計書 §8、§11 のディープリンク検証）。
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _Shell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const HomePage(),
              routes: [
                GoRoute(
                  path: 'search',
                  builder: (_, state) => SearchResultsPage(
                      query: state.uri.queryParameters['q'] ?? ''),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/laws', builder: (_, __) => const LawListPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsPage(),
              routes: [
                GoRoute(
                    path: 'prefetch', builder: (_, __) => const PrefetchPage()),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/law/:lawId',
        redirect: _validateLawRoute,
        builder: (_, state) => LawPage(
          lawId: state.pathParameters['lawId']!,
          initialTab: state.uri.queryParameters['tab'],
          initialQuery: _searchQueryOf(state),
        ),
        routes: [
          GoRoute(
            path: 'article/:num',
            redirect: _validateLawRoute,
            builder: (_, state) => LawPage(
              lawId: state.pathParameters['lawId']!,
              articleNum: state.pathParameters['num'],
              initialQuery: _searchQueryOf(state),
            ),
          ),
        ],
      ),
    ],
  );
});

/// `q` を他のパラメータのように形式で検証しないのは、本文内検索の語にしか
/// 使わず SQL にも URL にも渡さないため。外部 URL からも来るので長さだけ抑える。
String? _searchQueryOf(GoRouterState state) {
  final q = state.uri.queryParameters['q']?.trim();
  if (q == null || q.isEmpty) return null;
  return q.length > 100 ? q.substring(0, 100) : q;
}

/// 外部から開かれる URL のパラメータを検証する。不正なら一覧へ戻す。
String? _validateLawRoute(BuildContext context, GoRouterState state) {
  final lawId = state.pathParameters['lawId'];
  if (lawId == null || !EgovRequests.isValidLawId(lawId)) return '/laws';
  final num = state.pathParameters['num'];
  if (num != null && !EgovRequests.isValidArticleNum(num)) {
    return '/law/$lawId';
  }
  return null;
}

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: '検索'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: '法令一覧'),
          NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}
