import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_notices.dart';
import '../../data/db/database.dart';
import '../../data/services/prefetch_service.dart';
import '../../providers.dart';
import '../../util/external_link.dart';
import '../../util/format.dart';
import 'app_version.dart';
import 'settings_controller.dart';

final _syncRunsProvider = FutureProvider.autoDispose<List<SyncRun>>(
    (ref) => ref.watch(syncServiceProvider).recentRuns());

/// 設定（設計書 §8）: 今すぐ更新、先読み、キャッシュ削除、同期ログ、出典・免責・ライセンス。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static final Uri _egovUri = Uri.https('laws.e-gov.go.jp', '/');

  static String _statusLabel(SyncRun r) => switch (r.statusKind) {
        SyncRunStatus.running => '実行中',
        SyncRunStatus.success => '成功',
        SyncRunStatus.error => '失敗',
      };

  Future<void> _refreshNow(WidgetRef ref) async {
    await ref.read(syncServiceProvider).refreshNow();
    ref.invalidate(_syncRunsProvider);
  }

  Future<void> _confirmClearBodies(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('保存した本文を削除しますか？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('キャンセル')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true), child: const Text('削除')),
        ],
      ),
    );
    if (ok == true) await ref.read(lawRepositoryProvider).clearBodies();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final runs = ref.watch(_syncRunsProvider);
    final prefetch = ref.watch(prefetchStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('今すぐ更新'),
            subtitle: const Text('e-Gov から法令一覧を取り直します'),
            onTap: () => _refreshNow(ref),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('全法令を端末に保存'),
            subtitle: Text(switch (prefetch) {
              PrefetchRunning(:final progress) =>
                '保存中 ${progress.done} / ${progress.total} 件',
              _ => 'オフラインで開け、横断全文検索の対象になります',
            }),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/prefetch'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.download_for_offline),
            title: const Text('よく使う法令を先読みする'),
            subtitle: const Text('主要な税法・最近開いた法令に改正があったとき、起動時に本文を取り直します'),
            value: settings.prefetchEnabled,
            onChanged: notifier.setPrefetch,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.timer_outlined),
            title: const Text('10 分以内の再起動では一覧取得を省略'),
            value: settings.skipRecentSync,
            onChanged: notifier.setSkipRecentSync,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('保存した本文を削除'),
            subtitle: const Text('法令一覧は残ります。次に開くときに取り直します'),
            onTap: () => _confirmClearBodies(context, ref),
          ),
          const Divider(),
          ExpansionTile(
            leading: const Icon(Icons.history),
            title: const Text('同期ログ'),
            children: [
              runs.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => ListTile(title: Text('$e')),
                data: (rows) => rows.isEmpty
                    ? const ListTile(title: Text('まだ同期していません'))
                    : Column(children: [
                        for (final r in rows)
                          ListTile(
                            dense: true,
                            title: Text(
                                '${formatIso(r.startedAt)}  ${_statusLabel(r)}  確認 ${r.lawsChecked} / 更新 ${r.lawsUpdated}'),
                            subtitle: r.error == null ? null : Text(r.error!),
                          ),
                      ]),
              ),
            ],
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('出典と免責'),
            subtitle: Text('$sourceNotice$accuracyNotice'),
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('e-Gov法令検索を開く'),
            onTap: () => openExternal(context, _egovUri),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('オープンソースライセンス'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'zeibun',
              applicationLegalese: '© 2026 ouchinao\n'
                  '法令データ: e-Gov法令検索（公共データ利用規約 PDL1.0）',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.tag),
            title: const Text('バージョン'),
            subtitle: Text(switch (ref.watch(appVersionProvider)) {
              AsyncData(:final value) => formatVersion(value),
              AsyncError() => '取得できませんでした',
              _ => '…',
            }),
          ),
        ],
      ),
    );
  }
}
