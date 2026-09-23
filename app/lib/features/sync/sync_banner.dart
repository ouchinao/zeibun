import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/sync_service.dart';
import '../../providers.dart';
import '../../util/format.dart';

/// 検索画面上部の細いバナー（設計書 §4.4）。
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listenable = ref.watch(syncStateListenableProvider);
    return ValueListenableBuilder(
      valueListenable: listenable,
      builder: (context, state, _) {
        final scheme = Theme.of(context).colorScheme;
        final (text, icon, color) = switch (state) {
          SyncIdle() => (
              '同期待ち',
              Icons.schedule,
              scheme.surfaceContainerHighest
            ),
          SyncChecking() => (
              '法令一覧を確認中…',
              Icons.sync,
              scheme.surfaceContainerHighest
            ),
          SyncDownloading(:final done, :final total, :final currentTitle) => (
              '本文を更新中 $done/$total  $currentTitle',
              Icons.download,
              scheme.surfaceContainerHighest
            ),
          SyncSuccess(
            :final at,
            :final revised,
            :final pending,
            :final skipped
          ) =>
            (
              skipped
                  ? '最終同期 ${formatTime(at)}'
                  : '最終同期 ${formatTime(at)} / 改正あり $revised 件 / 施行予定あり $pending 件',
              Icons.check_circle_outline,
              scheme.secondaryContainer
            ),
          SyncOffline(:final lastSyncAt) => (
              'オフライン。一覧を取得できませんでした'
                  '${lastSyncAt == null ? '' : '（前回 ${formatTime(lastSyncAt)}）'}',
              Icons.cloud_off,
              scheme.tertiaryContainer
            ),
          SyncError(:final lastSyncAt) => (
              '同期に失敗しました'
                  '${lastSyncAt == null ? '' : '（前回 ${formatTime(lastSyncAt)}）'}',
              Icons.error_outline,
              scheme.errorContainer
            ),
        };
        return Material(
          color: color,
          child: InkWell(
            onTap: () => ref.read(syncServiceProvider).runOnLaunch(force: true),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                Icon(icon, size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(text,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ),
        );
      },
    );
  }
}
