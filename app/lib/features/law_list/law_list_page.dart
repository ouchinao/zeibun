import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../providers.dart';
import '../../util/format.dart';
import 'law_tile.dart';

/// 法令一覧。分類・種別でグルーピングし、末尾に「廃止・失効（参考）」（設計書 §8）。
class LawListPage extends ConsumerWidget {
  const LawListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laws = ref.watch(lawsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('法令一覧')),
      body: laws.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みエラー: $e')),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(
                child: Text('法令一覧がまだありません。\nオンラインで起動すると e-Gov から取得します。',
                    textAlign: TextAlign.center));
          }
          final groups = <String, List<Law>>{};
          final reference = <Law>[];
          for (final l in rows) {
            if (l.isReference) {
              reference.add(l);
              continue;
            }
            final key = '${l.category ?? 'その他'} / ${lawTypeLabel(l.lawType)}';
            groups.putIfAbsent(key, () => []).add(l);
          }
          final keys = groups.keys.toList()..sort();
          for (final k in keys) {
            groups[k]!.sort((a, b) => a.title.compareTo(b.title));
          }
          reference.sort((a, b) => a.title.compareTo(b.title));
          return ListView(
            children: [
              for (final k in keys)
                ExpansionTile(
                  title: Text('$k（${groups[k]!.length}）'),
                  children: [for (final l in groups[k]!) LawTile(law: l)],
                ),
              if (reference.isNotEmpty)
                ExpansionTile(
                  title: Text('廃止・失効（参考）（${reference.length}）'),
                  subtitle: const Text('現在は効力のない法令。本文は閲覧できます'),
                  children: [for (final l in reference) LawTile(law: l)],
                ),
            ],
          );
        },
      ),
    );
  }
}
