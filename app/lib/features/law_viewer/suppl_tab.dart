import 'package:flutter/material.dart';

import '../../data/db/database.dart';
import 'law_node_renderer.dart';
import 'law_text.dart';

typedef SupplFocus = ({int group, int article});

class SupplTab extends StatefulWidget {
  const SupplTab({
    super.key,
    required this.law,
    required this.groups,
    required this.loading,
    required this.highlight,
    required this.onLoadAmendSuppl,
    this.focus,
  });
  final Law law;
  final List<SupplGroup> groups;
  final bool loading;
  final List<String> highlight;
  final VoidCallback onLoadAmendSuppl;
  final SupplFocus? focus;

  @override
  State<SupplTab> createState() => _SupplTabState();
}

class _SupplTabState extends State<SupplTab> {
  /// 見せる条に付ける鍵。`ScrollablePositionedList` を使わないのは、附則が
  /// 折りたたみの入れ子で、平らなリストの index では条を指せないため。
  final _focusKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.focus != null) _revealFocus();
  }

  @override
  void didUpdateWidget(SupplTab old) {
    super.didUpdateWidget(old);
    if (widget.focus != null && widget.focus != old.focus) _revealFocus();
  }

  /// 次のフレームまで待つのは、折りたたみを開いた直後はまだ条が組み立てられて
  /// いないため。
  void _revealFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _focusKey.currentContext;
      if (c != null) {
        Scrollable.ensureVisible(c,
            alignment: 0.1, duration: const Duration(milliseconds: 250));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.groups;
    final focus = widget.focus;
    return ListView(
      children: [
        if (!widget.law.bodyIncludesAmendSuppl)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '改正法令の附則（各改正の施行期日・経過措置）は既定では読み込んでいません。'
                    '必要なときに読み込むと、この法令は以後も改正附則込みで保存されます。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: widget.loading ? null : widget.onLoadAmendSuppl,
                    icon: const Icon(Icons.download),
                    label: const Text('改正附則を読み込む'),
                  ),
                  if (widget.loading)
                    const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator()),
                ]),
          ),
        if (groups.isEmpty && !widget.loading)
          const Padding(padding: EdgeInsets.all(16), child: Text('附則はありません')),
        for (var gi = 0; gi < groups.length; gi++)
          ExpansionTile(
            // 開閉を key に混ぜるのは、ExpansionTile が initiallyExpanded を
            // 最初の組み立てでしか見ず、あとから開かせる手が作り直ししかないため
            key: ValueKey((groups[gi].amendLawNum, gi == focus?.group)),
            initiallyExpanded: gi == focus?.group || (focus == null && gi == 0),
            title: Text(groups[gi].amendLawNum ?? '附則（制定時）'),
            subtitle: Text('${groups[gi].articles.length} 項目'),
            children: [
              for (var ai = 0; ai < groups[gi].articles.length; ai++)
                Padding(
                  key: gi == focus?.group && ai == focus?.article
                      ? _focusKey
                      : null,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: LawNodeRenderer(groups[gi].articles[ai].body,
                      highlight: widget.highlight),
                ),
            ],
          ),
      ],
    );
  }
}
