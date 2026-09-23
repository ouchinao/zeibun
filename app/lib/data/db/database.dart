import 'package:drift/drift.dart';
import 'package:zeibun_core/zeibun_core.dart';

part 'database.g.dart';

/// 法令（1 行 = 1 法令）。設計書 §5。
class Laws extends Table {
  TextColumn get lawId => text()();
  TextColumn get lawNum => text()();
  TextColumn get lawType => text()();
  TextColumn get title => text()();
  TextColumn get titleKana => text().nullable()();
  TextColumn get abbrev => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get promulgationDate => text().nullable()();
  TextColumn get repealStatus => text().withDefault(const Constant('None'))();
  TextColumn get repealDate => text().nullable()();
  TextColumn get scopeReason => text()();
  TextColumn get currentRevisionId => text().nullable()();
  TextColumn get currentEnforcedAt => text().nullable()();
  TextColumn get amendmentLawTitle => text().nullable()();
  TextColumn get catalogUpdated => text().nullable()();

  /// 未施行改正があるときの、asof 遠未来側のリビジョン。
  TextColumn get pendingRevisionId => text().nullable()();
  TextColumn get bodyRevisionId => text().nullable()();
  TextColumn get bodySyncedAt => text().nullable()();
  BoolColumn get bodyIncludesAmendSuppl =>
      boolean().withDefault(const Constant(false))();
  TextColumn get missingSince => text().nullable()();
  TextColumn get lastOpenedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {lawId};
}

/// 改正履歴（開いた法令のみ）。
class LawRevisions extends Table {
  TextColumn get revisionId => text()();
  TextColumn get lawId => text().references(Laws, #lawId)();
  TextColumn get enforcedAt => text()();
  TextColumn get promulgatedAt => text().nullable()();
  TextColumn get scheduledEnforcedAt => text().nullable()();
  TextColumn get enforcementComment => text().nullable()();
  TextColumn get amendmentLawId => text().nullable()();
  TextColumn get amendmentLawNum => text().nullable()();
  TextColumn get amendmentLawTitle => text().nullable()();
  TextColumn get amendmentType => text().nullable()();
  TextColumn get status => text()();
  TextColumn get apiUpdated => text().nullable()();
  TextColumn get fetchedAt => text()();

  @override
  Set<Column> get primaryKey => {revisionId};
}

/// 条文（1 行 = 1 条。本則・附則・別表それぞれ）。
class Articles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get lawId => text().references(Laws, #lawId)();
  TextColumn get revisionId => text()();
  IntColumn get seq => integer()();
  TextColumn get section => text()();
  TextColumn get supplAmendLawNum => text().nullable()();
  TextColumn get path => text()();
  TextColumn get articleNum => text().nullable()();
  TextColumn get articleTitle => text().nullable()();
  TextColumn get caption => text().nullable()();
  TextColumn get breadcrumb => text().nullable()();

  /// 検索用の平文（幅を正規化済み）。
  TextColumn get plainText => text()();

  /// 表示用: 条のサブツリー JSON（`{tag, attr, children}`）。
  /// gzip した BLOB にしないのは、`dart:io` の gzip が Web に無く、
  /// 圧縮のためだけに依存を増やしたくないから。容量が問題になったら差し替える。
  TextColumn get bodyJson => text()();
}

class SyncRuns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get startedAt => text()();
  TextColumn get finishedAt => text().nullable()();
  TextColumn get status => text()();
  IntColumn get lawsChecked => integer().withDefault(const Constant(0))();
  IntColumn get lawsUpdated => integer().withDefault(const Constant(0))();
  IntColumn get bytesDownloaded => integer().withDefault(const Constant(0))();
  TextColumn get error => text().nullable()();
}

class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// 条の保存用 DTO（Isolate から返せるように文字列だけで構成）。
class ArticleRow {
  const ArticleRow({
    required this.seq,
    required this.section,
    required this.path,
    required this.plainText,
    required this.bodyJson,
    this.supplAmendLawNum,
    this.articleNum,
    this.articleTitle,
    this.caption,
    this.breadcrumb,
  });

  final int seq;
  final String section;
  final String? supplAmendLawNum;
  final String path;
  final String? articleNum;
  final String? articleTitle;
  final String? caption;
  final String? breadcrumb;
  final String plainText;
  final String bodyJson;
}

@DriftDatabase(tables: [Laws, LawRevisions, Articles, SyncRuns, AppMeta])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
              'CREATE INDEX idx_articles_law_seq ON articles(law_id, seq)');
          await customStatement(
              'CREATE INDEX idx_articles_law_num ON articles(law_id, section, article_num)');
          await customStatement(
              'CREATE INDEX idx_revisions_law ON law_revisions(law_id, enforced_at)');
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ---------------------------------------------------------------- meta

  Future<String?> getMeta(String key) async {
    final row = await (select(appMeta)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setMeta(String key, String value) =>
      into(appMeta).insertOnConflictUpdate(AppMetaCompanion.insert(
        key: key,
        value: value,
      ));

  // ---------------------------------------------------------------- laws

  Future<List<Law>> allLaws() =>
      (select(laws)..orderBy([(t) => OrderingTerm.asc(t.lawId)])).get();

  Stream<List<Law>> watchLaws() =>
      (select(laws)..orderBy([(t) => OrderingTerm.asc(t.lawId)])).watch();

  Future<Law?> getLaw(String lawId) =>
      (select(laws)..where((t) => t.lawId.equals(lawId))).getSingleOrNull();

  Stream<Law?> watchLaw(String lawId) =>
      (select(laws)..where((t) => t.lawId.equals(lawId))).watchSingleOrNull();

  Future<List<LocalLawState>> localLawStates() async {
    final rows = await allLaws();
    return [
      for (final r in rows)
        LocalLawState(
          lawId: r.lawId,
          currentRevisionId: r.currentRevisionId,
          catalogUpdated: r.catalogUpdated,
        ),
    ];
  }

  /// 一覧の行を反映する。
  ///
  /// `body_*` 列を同時に更新しないのは、一覧側のリビジョンと保存済み本文の
  /// リビジョンを別々に持つことで「改正あり（未取得）」を表現するため。
  /// 同じ理由で `missing_since` はここでリセットする（一覧に再登場した）。
  Future<void> upsertLawFromCatalog(LawSummary s, String scopeReason) async {
    final companion = LawsCompanion(
      lawId: Value(s.lawId),
      lawNum: Value(s.lawNum),
      lawType: Value(s.lawType),
      title: Value(s.title),
      titleKana: Value(s.titleKana),
      abbrev: Value(s.abbrev),
      category: Value(s.category),
      promulgationDate: Value(s.promulgationDate),
      repealStatus: Value(s.repealStatus),
      repealDate: Value(s.repealDate),
      scopeReason: Value(scopeReason),
      currentRevisionId: Value(s.currentRevisionId),
      currentEnforcedAt: Value(s.currentEnforcedAt),
      amendmentLawTitle: Value(s.amendmentLawTitle),
      catalogUpdated: Value(s.updated),
      pendingRevisionId: Value(s.pendingRevisionId),
      missingSince: const Value(null),
    );
    await into(laws).insert(companion,
        onConflict: DoUpdate((_) => companion, target: [laws.lawId]));
  }

  Future<void> markMissing(String lawId, String at) =>
      (update(laws)..where((t) => t.lawId.equals(lawId)))
          .write(LawsCompanion(missingSince: Value(at)));

  Future<void> touchLaw(String lawId, String at) =>
      (update(laws)..where((t) => t.lawId.equals(lawId)))
          .write(LawsCompanion(lastOpenedAt: Value(at)));

  Future<List<Law>> recentLaws({int limit = 10}) => (select(laws)
        ..where((t) => t.lastOpenedAt.isNotNull())
        ..orderBy([(t) => OrderingTerm.desc(t.lastOpenedAt)])
        ..limit(limit))
      .get();

  /// 法令名・略称・読みの部分一致。`terms` は正規化済みの候補語。
  Future<List<Law>> searchLawsByName(List<String> terms) async {
    if (terms.isEmpty) return const [];
    final q = select(laws);
    Expression<bool>? where;
    for (final t in terms) {
      final pattern = '%${t.replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
      final e = laws.title.lower().like(pattern) |
          laws.abbrev.lower().like(pattern) |
          laws.titleKana.lower().like(pattern);
      where = where == null ? e : (where | e);
    }
    q.where((_) => where!);
    final rows = await q.get();
    // SQL の ORDER BY にしないのは、廃止・失効を後ろに回す並びと題名長の並びを
    // 1 つの式にすると読みにくく、件数（数百）ではメモリ上で並べ替えても十分速いから
    rows.sort((a, b) {
      final ra = a.repealStatus == 'None' ? 0 : 1;
      final rb = b.repealStatus == 'None' ? 0 : 1;
      if (ra != rb) return ra - rb;
      return a.title.length.compareTo(b.title.length);
    });
    return rows;
  }

  // ------------------------------------------------------------- articles

  Future<List<Article>> articlesOf(String lawId) => (select(articles)
        ..where((t) => t.lawId.equals(lawId))
        ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
      .get();

  Future<Article?> findArticle(String lawId, String section, String num) =>
      (select(articles)
            ..where((t) =>
                t.lawId.equals(lawId) &
                t.section.equals(section) &
                t.articleNum.equals(num))
            ..limit(1))
          .getSingleOrNull();

  /// 本文を差し替える。
  ///
  /// 条ごとに UPSERT しないのは、途中で落ちたときに新旧の条が混ざった本文を
  /// 見せないため。1 法令 1 トランザクションで全削除→全挿入し、成功したときだけ
  /// `body_revision_id` を進める。
  Future<void> replaceArticles({
    required String lawId,
    required String revisionId,
    required List<ArticleRow> rows,
    required bool includesAmendSuppl,
    required String syncedAt,
  }) =>
      transaction(() async {
        await (delete(articles)..where((t) => t.lawId.equals(lawId))).go();
        await batch((b) {
          b.insertAll(articles, [
            for (final r in rows)
              ArticlesCompanion.insert(
                lawId: lawId,
                revisionId: revisionId,
                seq: r.seq,
                section: r.section,
                supplAmendLawNum: Value(r.supplAmendLawNum),
                path: r.path,
                articleNum: Value(r.articleNum),
                articleTitle: Value(r.articleTitle),
                caption: Value(r.caption),
                breadcrumb: Value(r.breadcrumb),
                plainText: r.plainText,
                bodyJson: r.bodyJson,
              ),
          ]);
        });
        await (update(laws)..where((t) => t.lawId.equals(lawId))).write(
          LawsCompanion(
            bodyRevisionId: Value(revisionId),
            bodySyncedAt: Value(syncedAt),
            bodyIncludesAmendSuppl: Value(includesAmendSuppl),
          ),
        );
      });

  Future<void> clearBodies() => transaction(() async {
        await delete(articles).go();
        await delete(lawRevisions).go();
        await update(laws).write(const LawsCompanion(
          bodyRevisionId: Value(null),
          bodySyncedAt: Value(null),
          bodyIncludesAmendSuppl: Value(false),
        ));
      });

  // ------------------------------------------------------------ revisions

  Future<List<LawRevision>> revisionsOf(String lawId) => (select(lawRevisions)
        ..where((t) => t.lawId.equals(lawId))
        ..orderBy([(t) => OrderingTerm.desc(t.enforcedAt)]))
      .get();

  Future<void> replaceRevisions(
          String lawId, List<LawRevisionInfo> revs, String fetchedAt) =>
      transaction(() async {
        await (delete(lawRevisions)..where((t) => t.lawId.equals(lawId))).go();
        await batch((b) {
          b.insertAll(lawRevisions, [
            for (final r in revs)
              LawRevisionsCompanion.insert(
                revisionId: r.revisionId,
                lawId: lawId,
                enforcedAt: r.enforcedAt,
                promulgatedAt: Value(r.promulgatedAt),
                scheduledEnforcedAt: Value(r.scheduledEnforcedAt),
                enforcementComment: Value(r.enforcementComment),
                amendmentLawId: Value(r.amendmentLawId),
                amendmentLawNum: Value(r.amendmentLawNum),
                amendmentLawTitle: Value(r.amendmentLawTitle),
                amendmentType: Value(r.amendmentType),
                status: r.status ?? '',
                apiUpdated: Value(r.updated),
                fetchedAt: fetchedAt,
              ),
          ]);
        });
      });

  // ------------------------------------------------------------ sync runs

  Future<int> startSyncRun(String startedAt) =>
      into(syncRuns).insert(SyncRunsCompanion.insert(
        startedAt: startedAt,
        status: 'running',
      ));

  Future<void> finishSyncRun(
    int id, {
    required String finishedAt,
    required String status,
    int lawsChecked = 0,
    int lawsUpdated = 0,
    int bytesDownloaded = 0,
    String? error,
  }) =>
      (update(syncRuns)..where((t) => t.id.equals(id))).write(SyncRunsCompanion(
        finishedAt: Value(finishedAt),
        status: Value(status),
        lawsChecked: Value(lawsChecked),
        lawsUpdated: Value(lawsUpdated),
        bytesDownloaded: Value(bytesDownloaded),
        error: Value(error),
      ));

  Future<List<SyncRun>> recentSyncRuns({int limit = 20}) => (select(syncRuns)
        ..orderBy([(t) => OrderingTerm.desc(t.id)])
        ..limit(limit))
      .get();
}
