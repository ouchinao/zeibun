import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeibun/data/db/database.dart';
import 'package:zeibun_core/zeibun_core.dart';

/// スキーマ v1（全文索引なし）の DB を作るための最小構成。
class _V1Database extends AppDatabase {
  _V1Database(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());
}

void main() {
  late Directory dir;

  setUp(() async => dir = await Directory.systemTemp.createTemp('zeibun_db'));
  tearDown(() => dir.delete(recursive: true));

  test('upgrading from schema 1 indexes the bodies that were already saved',
      () async {
    final file = File('${dir.path}/zeibun.sqlite');

    final v1 = _V1Database(NativeDatabase(file));
    await v1.upsertLawFromCatalog(
      const LawSummary(
        lawId: '426AC0000000011',
        lawNum: '平成二十六年法律第十一号',
        lawType: 'Act',
        title: '地方法人税法',
        currentRevisionId: '426AC0000000011_20260401_000000000000000',
      ),
      'category:013',
    );
    await v1.replaceArticles(
      lawId: '426AC0000000011',
      revisionId: '426AC0000000011_20260401_000000000000000',
      rows: const [
        ArticleRow(
          seq: 1,
          section: 'main',
          path: 'main/Article_1',
          articleNum: '1',
          articleTitle: '第一条',
          plainText: 'この法律は、地方法人税について、納税義務者、課税標準、税額の計算を定める。',
          bodyJson: '{"tag":"Article","attr":{},"children":[]}',
        ),
      ],
      includesAmendSuppl: false,
      syncedAt: '2026-09-23T00:00:00',
    );
    await v1.close();

    final v2 = AppDatabase(NativeDatabase(file));
    final hits = await v2.searchFullText(FtsQuery.parse('課税標準'));
    expect(hits.single.articleNum, '1');
    expect(hits.single.snippet, contains('課税標準'));
    await v2.close();
  });
}
