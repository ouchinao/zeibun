import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/database.dart';
import '../../util/format.dart';

/// 法令一覧・検索結果で使う行。種別・分類・施行日と状態バッジ。
class LawTile extends StatelessWidget {
  const LawTile(
      {super.key, required this.law, this.subtitleSuffix, this.onTap});

  final Law law;
  final String? subtitleSuffix;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRef = law.repealStatus != 'None';
    final badges = <Widget>[
      if (isRef) _Badge(repealStatusLabel(law.repealStatus), scheme.outline),
      if (law.pendingRevisionId != null) _Badge('施行予定あり', scheme.tertiary),
      if (law.bodyRevisionId != null &&
          law.currentRevisionId != null &&
          law.bodyRevisionId != law.currentRevisionId)
        _Badge('改正あり（未取得）', scheme.error),
      if (law.bodyRevisionId != null &&
          law.bodyRevisionId == law.currentRevisionId)
        _Badge('保存済み', scheme.primary),
    ];
    return ListTile(
      dense: true,
      title: Text(law.title,
          style: isRef ? TextStyle(color: scheme.onSurfaceVariant) : null),
      subtitle: Text(
        [
          lawTypeLabel(law.lawType),
          if (law.category != null) law.category!,
          if (isRef && law.repealDate != null)
            '${repealStatusLabel(law.repealStatus)} ${law.repealDate}'
          else if (law.currentEnforcedAt != null)
            '施行 ${law.currentEnforcedAt}',
          if (subtitleSuffix != null) subtitleSuffix!,
        ].join(' · '),
      ),
      trailing: badges.isEmpty ? null : Wrap(spacing: 4, children: badges),
      onTap: onTap ?? () => context.push('/law/${law.lawId}'),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text,
            style:
                Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
      );
}
