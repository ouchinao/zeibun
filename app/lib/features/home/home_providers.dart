import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../providers.dart';

/// 最近開いた法令。一覧から導き、別クエリにしないのは、一覧の変更通知と
/// 二重に購読しないため。
final recentLawsProvider = Provider<AsyncValue<List<Law>>>((ref) => ref
    .watch(lawsStreamProvider)
    .whenData((rows) => (rows.where((l) => l.lastOpenedAt != null).toList()
          ..sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!)))
        .take(10)
        .toList()));
