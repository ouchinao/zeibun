import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../providers.dart';

final bookmarksProvider = StreamProvider<List<BookmarkEntry>>(
    (ref) => ref.watch(bookmarkRepositoryProvider).watchAll());

/// `articleNum` が null なら法令そのもののブックマーク。
typedef BookmarkKey = ({String lawId, String? articleNum});

/// 画面を離れたら購読を止める（条ごとにストリームを残さない）。
final isBookmarkedProvider = StreamProvider.autoDispose
    .family<bool, BookmarkKey>((ref, k) => ref
        .watch(bookmarkRepositoryProvider)
        .watchIsBookmarked(k.lawId, articleNum: k.articleNum));
