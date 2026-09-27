import 'package:flutter/material.dart';

/// ホームの各節の見出し。ブックマーク節と同じ見た目にするためここに置く。
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        // ただの文字にしないのは、読み上げの「見出しへ移動」で節を飛べるようにするため
        child: Semantics(
            header: true,
            child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
      );
}

class SectionHint extends StatelessWidget {
  const SectionHint(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      );
}
