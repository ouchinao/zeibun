import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/prefetch_service.dart';
import '../../providers.dart';
import '../../util/format.dart';

/// 設計書 §4.4、§8。
class PrefetchPage extends ConsumerWidget {
  const PrefetchPage({super.key});

  /// Wi-Fi でも確認を出さないのは、毎回出る確認は読まれずに押されるため。
  /// 回線が分からないときも確認を出すのは、分からないまま数百 MB を流さないため。
  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final network = await ref.read(networkKindProvider.future);
    if (!context.mounted) return;
    if (network != NetworkKind.unmetered) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(switch (network) {
            NetworkKind.metered => 'モバイル回線で保存しますか？',
            _ => '回線の種類を確認できませんでした',
          }),
          content: const Text('数十〜数百 MB の通信になります。Wi-Fi 接続時の実行をおすすめします。'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('やめる')),
            FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('このまま保存')),
          ],
        ),
      );
      if (ok != true) return;
    }
    ref.read(prefetchServiceProvider).start();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(prefetchTargetCountProvider);
    final state = ref.watch(prefetchStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('全法令を端末に保存')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '対象の税制法令すべての本文を端末に保存します。保存した法令はオフラインで開け、'
            '横断全文検索の対象になります。通信量は数十〜数百 MB になるため Wi-Fi をおすすめします。'
            '途中で中断しても、保存できた法令はそのまま残ります。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          switch (state) {
            PrefetchIdle() => _StartCard(
                remaining: remaining,
                onStart: () => _start(context, ref),
              ),
            PrefetchRunning() => _RunningCard(
                state,
                onCancel: ref.read(prefetchServiceProvider).cancel,
              ),
            PrefetchFinished() => _FinishedCard(
                state,
                remaining: remaining,
                onStart: () => _start(context, ref),
              ),
          },
        ],
      ),
    );
  }
}

String _progressLine(PrefetchProgress p) =>
    '${p.done} / ${p.total} 件、${formatBytes(p.bytes)}'
    '${p.failed > 0 ? '、失敗 ${p.failed} 件' : ''}';

class _StartCard extends StatelessWidget {
  const _StartCard({required this.remaining, required this.onStart});
  final AsyncValue<int> remaining;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final n = remaining.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(switch (n) {
        null => '対象を数えています…',
        0 => 'すべての法令が保存済みです。',
        _ => '未保存または改正後に取り直していない法令: $n 件',
      }),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: (n ?? 0) > 0 ? onStart : null,
        icon: const Icon(Icons.download),
        label: const Text('保存を始める'),
      ),
    ]);
  }
}

class _RunningCard extends StatelessWidget {
  const _RunningCard(this.s, {required this.onCancel});
  final PrefetchRunning s;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final p = s.progress;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      LinearProgressIndicator(value: p.total == 0 ? null : p.done / p.total),
      const SizedBox(height: 8),
      Text(_progressLine(p)),
      Text(s.currentTitle,
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: onCancel,
        icon: const Icon(Icons.stop),
        label: const Text('中断'),
      ),
    ]);
  }
}

class _FinishedCard extends StatelessWidget {
  const _FinishedCard(this.s, {required this.remaining, required this.onStart});
  final PrefetchFinished s;
  final AsyncValue<int> remaining;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final summary = _progressLine(s.progress);
    final headline = switch (s.outcome) {
      PrefetchOutcome.completed => '保存が完了しました（$summary）',
      PrefetchOutcome.cancelled => '中断しました（$summary）',
      PrefetchOutcome.offline => '通信できないため中断しました（$summary）',
      PrefetchOutcome.aborted => 'エラーのため中断しました（$summary）',
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(headline),
      if (s.progress.failed > 0 || s.outcome == PrefetchOutcome.aborted)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('取れなかった法令は次回の実行、または法令を開いたときに取り直します。',
              style: Theme.of(context).textTheme.bodySmall),
        ),
      const SizedBox(height: 12),
      _StartCard(remaining: remaining, onStart: onStart),
    ]);
  }
}
