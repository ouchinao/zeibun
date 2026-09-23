import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeibun_core/zeibun_core.dart';

import '../../data/db/database.dart';
import '../../providers.dart';
import '../law_list/law_tile.dart';
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

  /// 初回起動時だけ免責を表示する。設定画面にも同じ文言を常設しているので、
  /// 毎回出して読み飛ばされるより、一度だけ確実に目に入る形にする。
  Future<void> _showDisclaimerOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kDisclaimerShown) == true || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('ご利用にあたって'),
        content: const Text(
          '法令データは e-Gov法令検索（デジタル庁）の法令API から取得しています。'
          '本アプリはデジタル庁・e-Gov の公式アプリではありません。\n\n'
          '表示内容の正確性・最新性は保証しません。正本は官報および e-Gov法令検索で確認してください。'
          '各法令の画面に取得日時とリビジョンを表示しています。',
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(c), child: const Text('確認しました')),
        ],
      ),
    );
    await prefs.setBool(_kDisclaimerShown, true);
  }

  static const _kDisclaimerShown = 'disclaimer_shown_v1';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          _SectionTitle('最近開いた法令'),
          recent.when(
            data: (rows) => rows.isEmpty
                ? const _Hint('まだ法令を開いていません。')
                : Column(children: [for (final l in rows) LawTile(law: l)]),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => _Hint('読み込みエラー: $e'),
          ),
          const SizedBox(height: 24),
          _SectionTitle('主要な税法'),
          laws.when(
            data: (rows) {
              final byId = {for (final l in rows) l.lawId: l};
              final major = [
                for (final id in majorTaxLaws.keys)
                  if (byId[id] != null) byId[id]!,
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
                      avatar: _badgeFor(l),
                      onPressed: () => context.push('/law/${l.lawId}'),
                    ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => _Hint('読み込みエラー: $e'),
          ),
          const SizedBox(height: 32),
          Text(
            '出典: e-Gov法令検索（https://laws.e-gov.go.jp/）。'
            '本アプリはデジタル庁・e-Gov の公式アプリではありません。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget? _badgeFor(Law l) {
    if (l.currentRevisionId != null &&
        l.bodyRevisionId == l.currentRevisionId) {
      return const Icon(Icons.offline_pin, size: 18);
    }
    if (l.bodyRevisionId != null) {
      return const Icon(Icons.update, size: 18);
    }
    return null;
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
