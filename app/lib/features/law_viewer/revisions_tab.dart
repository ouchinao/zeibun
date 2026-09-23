import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../providers.dart';
import '../../util/format.dart';

final _revisionsProvider = FutureProvider.autoDispose
    .family<List<LawRevision>, String>((ref, lawId) =>
        ref.watch(lawRepositoryProvider).refreshRevisions(lawId));

class RevisionsTab extends ConsumerWidget {
  const RevisionsTab({super.key, required this.law});
  final Law law;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revs = ref.watch(_revisionsProvider(law.lawId));
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return revs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('取得できませんでした: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return const Center(child: Text('改正履歴を取得できませんでした（オフライン？）'));
        }
        return ListView.separated(
          itemCount: rows.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) => _RevisionTile(rows[i],
              today: today, currentId: law.currentRevisionId),
        );
      },
    );
  }
}

enum _Timing { scheduled, current, past }

class _RevisionTile extends StatelessWidget {
  const _RevisionTile(this.r, {required this.today, required this.currentId});
  final LawRevision r;
  final String today;
  final String? currentId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timing = r.enforcedAt.compareTo(today) > 0 || r.status == 'UnEnforced'
        ? _Timing.scheduled
        : r.revisionId == currentId
            ? _Timing.current
            : _Timing.past;
    final (icon, color, label) = switch (timing) {
      _Timing.scheduled => (Icons.schedule, scheme.tertiary, '施行予定'),
      _Timing.current => (Icons.check_circle, scheme.primary, '施行'),
      _Timing.past => (Icons.history, scheme.outline, '施行'),
    };
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        '$label ${formatDate(r.enforcedAt)}',
        style: timing == _Timing.scheduled
            ? TextStyle(color: color, fontWeight: FontWeight.w600)
            : null,
      ),
      subtitle: Text([
        if (r.amendmentLawTitle != null) r.amendmentLawTitle!,
        if (r.amendmentLawNum != null) r.amendmentLawNum!,
        if (r.enforcementComment != null) r.enforcementComment!,
        if (timing == _Timing.current) '現行',
      ].join('\n')),
      isThreeLine: true,
    );
  }
}
