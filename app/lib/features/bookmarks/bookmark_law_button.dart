import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import 'bookmark_providers.dart';

/// 条ではなく法令そのもの（`articleNum` なし）を対象にする。
/// 書き込み中はボタンを無効にする。連打で追加→解除と 2 回走り、押したのに
/// 何も付かなかったように見えるため。
class BookmarkLawButton extends ConsumerStatefulWidget {
  const BookmarkLawButton({super.key, required this.lawId});
  final String lawId;

  @override
  ConsumerState<BookmarkLawButton> createState() => _BookmarkLawButtonState();
}

class _BookmarkLawButtonState extends ConsumerState<BookmarkLawButton> {
  bool _pending = false;

  Future<void> _toggle() async {
    setState(() => _pending = true);
    try {
      await ref.read(bookmarkRepositoryProvider).toggle(widget.lawId);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final on = ref
            .watch(
                isBookmarkedProvider((lawId: widget.lawId, articleNum: null)))
            .value ??
        false;
    return IconButton(
      icon: Icon(on ? Icons.bookmark : Icons.bookmark_border),
      tooltip: on ? 'ブックマークを外す' : 'ブックマークに追加',
      onPressed: _pending ? null : _toggle,
    );
  }
}
