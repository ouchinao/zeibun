import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zeibun_core/zeibun_core.dart';

/// アプリに同梱する法令一覧（`dart run tool/update_catalog_snapshot.dart` で作る）。
void main() {
  final snap = CatalogSnapshot.fromJson(
      jsonDecode(File('assets/catalog_snapshot.json').readAsStringSync())
          as Map<String, dynamic>);

  test('the bundled list records when it was taken', () {
    expect(DateTime.tryParse(snap.generatedAt), isNotNull);
  });

  test('the bundled list holds the main tax laws, each once and in scope', () {
    final titles = snap.laws.map((l) => l.title).toSet();
    expect(titles, containsAll(['所得税法', '法人税法', '消費税法', '地方税法']));
    expect(snap.laws.map((l) => l.lawId).toSet().length, snap.laws.length);
    expect(snap.laws.where((l) => LawScope.tax.reasonFor(l) == null), isEmpty);
    expect(snap.laws.where((l) => l.currentRevisionId == null), isEmpty);
  });

  test('a law survives the round trip through the bundled format', () {
    final law = snap.laws.firstWhere((l) => l.title == '法人税法');
    final back = LawSummary.fromJson(law.toJson());
    expect(back.toJson(), law.toJson());
  });
}
