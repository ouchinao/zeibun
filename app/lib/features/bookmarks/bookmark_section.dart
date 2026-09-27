import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeibun_core/zeibun_core.dart';

import '../../data/db/database.dart';
import '../../providers.dart';
import '../home/section_widgets.dart';
import 'bookmark_providers.dart';

class BookmarkSection extends ConsumerWidget {
  const BookmarkSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('ブックマーク'),
      bookmarks.when(
        data: (rows) => rows.isEmpty
            ? const SectionHint('条を長押し、または法令画面のしおりで追加できます。')
            : Column(children: [for (final b in rows) _BookmarkTile(b)]),
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => const SectionHint('ブックマークを読み込めませんでした'),
      ),
    ]);
  }
}

class _BookmarkTile extends ConsumerWidget {
  const _BookmarkTile(this.b);
  final BookmarkEntry b;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final num = b.articleNum;
    return ListTile(
      dense: true,
      leading: Icon(num == null ? Icons.menu_book : Icons.bookmark),
      title: Text(num == null
          ? b.lawTitle
          : '${b.lawTitle} ${b.articleTitle ?? articleNumDisplay(num)}'),
      subtitle: b.caption == null ? null : Text(b.caption!),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        tooltip: '外す',
        onPressed: () => _remove(context, ref),
      ),
      onTap: () => context.push(
          num == null ? '/law/${b.lawId}' : '/law/${b.lawId}/article/$num'),
    );
  }

  /// 確認のダイアログを挟まず、外した後に取り消しを出すのは、外すたびに
  /// 確認されると手間で、誤操作のときだけ戻せれば足りるため。
  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(bookmarkRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    await repo.remove(b.id);
    messenger.showSnackBar(SnackBar(
      content: const Text('ブックマークを外しました'),
      action: SnackBarAction(label: '元に戻す', onPressed: () => repo.restore(b)),
    ));
  }
}
