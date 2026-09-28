import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/sync_service.dart';
import '../../providers.dart';
import '../../util/format.dart';

/// 設計書 §4.4。
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncStateProvider);
    final scheme = Theme.of(context).colorScheme;
    final (text, icon, color, onColor) = switch (state) {
      SyncIdle() => (
          '同期待ち',
          Icons.schedule,
          scheme.surfaceContainerHighest,
          scheme.onSurface
        ),
      SyncChecking() => (
          '法令一覧を確認中…',
          Icons.sync,
          scheme.surfaceContainerHighest,
          scheme.onSurface
        ),
      SyncSkipped(:final lastSyncAt) => (
          '最終同期 ${formatTime(lastSyncAt)}',
          Icons.check_circle_outline,
          scheme.secondaryContainer,
          scheme.onSecondaryContainer
        ),
      SyncSuccess(:final at, :final revised, :final pending) => (
          '最終同期 ${formatTime(at)} / 改正あり $revised 件 / 施行予定あり $pending 件',
          Icons.check_circle_outline,
          scheme.secondaryContainer,
          scheme.onSecondaryContainer
        ),
      SyncBackingOff(:final failures, :final lastSyncAt) => (
          '連続 $failures 回失敗したため自動同期を見送りました${_previous(lastSyncAt)}',
          Icons.pause_circle_outline,
          scheme.errorContainer,
          scheme.onErrorContainer
        ),
      SyncOffline(:final lastSyncAt) => (
          'オフライン。一覧を取得できませんでした${_previous(lastSyncAt)}',
          Icons.cloud_off,
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer
        ),
      SyncError(:final message, :final lastSyncAt) => (
          '$message${_previous(lastSyncAt)}',
          Icons.error_outline,
          scheme.errorContainer,
          scheme.onErrorContainer
        ),
    };
    // 文字色を既定のままにしないのは、「コントラストを上げる」で背景だけ
    // 明るくなり、文字との差が縮んで読めなくなるため
    return Material(
      color: color,
      // ボタンの形にせず読み上げのヒントで伝えるのは、見た目を変えないため。
      // 文言だけでは押すと更新できることが読み上げで分からない。onTapHint に
      // しないのは、iOS では無視されるため
      child: Semantics(
        hint: '押すと法令一覧を今すぐ更新します',
        child: InkWell(
          onTap: state is SyncChecking
              ? null
              : () => ref.read(syncServiceProvider).refreshNow(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(children: [
              Icon(icon, size: 16, color: onColor),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(text,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: onColor),
                      overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ),
      ),
    );
  }

  static String _previous(DateTime? at) =>
      at == null ? '' : '（前回 ${formatTime(at)}）';
}
