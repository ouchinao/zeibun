import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import 'bookmark_providers.dart';

/// 条ではなく法令そのもの（`articleNum` なし）を対象にする。
class BookmarkLawButton extends ConsumerWidget {
  const BookmarkLawButton({super.key, required this.lawId});
  final String lawId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref
            .watch(isBookmarkedProvider((lawId: lawId, articleNum: null)))
            .valueOrNull ??
        false;
    return IconButton(
      icon: Icon(on ? Icons.bookmark : Icons.bookmark_border),
      tooltip: on ? 'ブックマークを外す' : 'ブックマークに追加',
      onPressed: () => ref.read(bookmarkRepositoryProvider).toggle(lawId),
    );
  }
}
