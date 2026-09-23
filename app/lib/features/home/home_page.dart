import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeibun_core/zeibun_core.dart';

import '../../app_notices.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../bookmarks/bookmark_section.dart';
import '../law_list/law_tile.dart';
import '../settings/settings_controller.dart';
import '../sync/sync_banner.dart';

/// 検索（ホーム）。検索窓、同期バナー、最近開いた法令、主要法令へのショートカット。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDisclaimerOnce());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 初回起動時だけ免責を表示する。設定画面にも同じ文言を常設しているので、
  /// 毎回出して読み飛ばされるより、一度だけ確実に目に入る形にする。
  Future<void> _showDisclaimerOnce() async {
    if (ref.read(settingsProvider).disclaimerShown || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('ご利用にあたって'),
        content: const Text('$sourceNotice\n\n$accuracyNotice'),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(c), child: const Text('確認しました')),
        ],
      ),
    );
    await ref.read(settingsProvider.notifier).markDisclaimerShown();
  }

  void _submit(String q) {
    final t = q.trim();
    if (t.isEmpty) return;
    context.go('/search?q=${Uri.encodeQueryComponent(t)}');
  }

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(recentLawsProvider);
    final laws = ref.watch(lawsStreamProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('zeibun 税法検索'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(30),
          child: SyncBanner(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: _submit,
            decoration: InputDecoration(
              hintText: '法令名・略称・条番号（例: 法人税法 / 措法42の12の5）',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => _submit(_controller.text),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('最近開いた法令'),
          recent.when(
            data: (rows) => rows.isEmpty
                ? const _Hint('まだ法令を開いていません。')
                : Column(children: [for (final l in rows) LawTile(law: l)]),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => _Hint('読み込みエラー: $e'),
          ),
          const SizedBox(height: 24),
          const BookmarkSection(),
          const SizedBox(height: 24),
          const _SectionTitle('主要な税法'),
          laws.when(
            data: (rows) => _MajorLawChips(rows),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => _Hint('読み込みエラー: $e'),
          ),
          const SizedBox(height: 32),
          Text(footerNotice, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MajorLawChips extends StatelessWidget {
  const _MajorLawChips(this.laws);
  final List<Law> laws;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final l in laws) l.lawId: l};
    final major = [
      for (final id in majorTaxLaws.keys)
        if (byId[id] case final l?) l,
    ];
    if (major.isEmpty) {
      return const _Hint('法令一覧を取得すると、ここに主要な税法が並びます。');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final l in major)
          ActionChip(
            label: Text(l.title),
            avatar: switch (l.bodyCache) {
              BodyCache.none => null,
              BodyCache.current => const Icon(Icons.offline_pin, size: 18),
              BodyCache.outdated => const Icon(Icons.update, size: 18),
            },
            onPressed: () => context.push('/law/${l.lawId}'),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      );
}
