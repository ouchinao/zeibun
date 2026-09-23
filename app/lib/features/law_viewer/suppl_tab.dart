import 'package:flutter/material.dart';

import '../../data/db/database.dart';
import 'law_node_renderer.dart';
import 'law_text.dart';

class SupplTab extends StatelessWidget {
  const SupplTab({
    super.key,
    required this.law,
    required this.groups,
    required this.loading,
    required this.highlight,
    required this.onLoadAmendSuppl,
  });
  final Law law;
  final List<SupplGroup> groups;
  final bool loading;
  final List<String> highlight;
  final VoidCallback onLoadAmendSuppl;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (!law.bodyIncludesAmendSuppl)
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
                    onPressed: loading ? null : onLoadAmendSuppl,
                    icon: const Icon(Icons.download),
                    label: const Text('改正附則を読み込む'),
                  ),
                  if (loading)
                    const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator()),
                ]),
          ),
        if (groups.isEmpty && !loading)
          const Padding(padding: EdgeInsets.all(16), child: Text('附則はありません')),
        for (final g in groups)
          ExpansionTile(
            initiallyExpanded: g == groups.first,
            title: Text(g.amendLawNum ?? '附則（制定時）'),
            subtitle: Text('${g.articles.length} 項目'),
            children: [
              for (final a in g.articles)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: LawNodeRenderer(a.body, highlight: highlight),
                ),
            ],
          ),
      ],
    );
  }
}
