import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/repositories/law_repository.dart';
import '../../providers.dart';
import '../../util/format.dart';

final _revisionsProvider = FutureProvider.autoDispose
    .family<RevisionsResult, String>((ref, lawId) =>
        ref.watch(lawRepositoryProvider).refreshRevisions(lawId));

class RevisionsTab extends ConsumerWidget {
  const RevisionsTab({super.key, required this.law});
  final Law law;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(_revisionsProvider(law.lawId));
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return result.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('改正履歴の読み込みで想定外のエラーが発生しました')),
      data: (r) {
        if (r.revisions.isEmpty) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_emptyMessage(r.failure), textAlign: TextAlign.center),
          ));
        }
        return ListView.separated(
          itemCount: r.revisions.length + (r.failure == null ? 0 : 1),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            if (r.failure != null && i == 0) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.info_outline),
                title: Text('${_failureReason(r.failure!)}、前回取得した履歴を表示しています'),
              );
            }
            final row = r.revisions[r.failure == null ? i : i - 1];
            return _RevisionTile(row,
                timing: row.timingAt(today,
                    currentRevisionId: law.currentRevisionId));
          },
        );
      },
    );
  }

  static String _failureReason(FetchFailure f) => switch (f) {
        FetchFailure.offline => 'オフラインのため',
        FetchFailure.server => 'e-Gov から取得できず',
        FetchFailure.invalidData => '取得した履歴を解釈できず',
        FetchFailure.storageFull => '端末の空き容量が足りず保存できず',
      };

  static String _emptyMessage(FetchFailure? f) =>
      f == null ? '改正履歴はありません' : '${_failureReason(f)}、改正履歴を表示できません';
}

class _RevisionTile extends StatelessWidget {
  const _RevisionTile(this.r, {required this.timing});
  final LawRevision r;
  final RevisionTiming timing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color, label) = switch (timing) {
      RevisionTiming.scheduled => (Icons.schedule, scheme.tertiary, '施行予定'),
      RevisionTiming.current => (Icons.check_circle, scheme.primary, '施行'),
      RevisionTiming.past => (Icons.history, scheme.outline, '施行'),
    };
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        '$label ${formatDate(r.enforcedAt)}',
        style: timing == RevisionTiming.scheduled
            ? TextStyle(color: color, fontWeight: FontWeight.w600)
            : null,
      ),
      subtitle: Text([
        if (r.amendmentLawTitle != null) r.amendmentLawTitle!,
        if (r.amendmentLawNum != null) r.amendmentLawNum!,
        if (r.enforcementComment != null) r.enforcementComment!,
        if (timing == RevisionTiming.current) '現行',
      ].join('\n')),
      isThreeLine: true,
    );
  }
}
