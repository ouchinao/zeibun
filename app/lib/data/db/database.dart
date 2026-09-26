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

/// `article_num` が NULL なら法令そのもの。
/// 条の行 ID ではなく条番号で持つのは、本文を取り直すと条の行は全部作り直され、
/// ID が変わるため。
class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get lawId => text().references(Laws, #lawId)();
  TextColumn get articleNum => text().nullable()();
  TextColumn get createdAt => text()();
}

/// 条名・見出しが null になるのは、本文を保存していない法令の条をブックマークしたとき。
class BookmarkEntry {
  const BookmarkEntry({
    required this.id,
    required this.lawId,
    required this.lawTitle,
    required this.createdAt,
    this.articleNum,
    this.articleTitle,
    this.caption,
  });
  final int id;
  final String lawId;
  final String lawTitle;
  final String createdAt;
  final String? articleNum;
  final String? articleTitle;
  final String? caption;
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

enum BodyCache {
  none,
  current,

  /// 保存済みだが、一覧側で改正が施行された（画面では「改正あり（未取得）」）
  outdated,
}

/// 列の比較を各画面で書かないためにここに置く。一覧・チップ・ヘッダ・先読みで
/// 同じ比較を別々に書いていて、条件が食い違いかけたため。
extension LawFlags on Law {
  bool get isReference => RepealStatus.isReference(repealStatus);

  BodyCache get bodyCache {
    if (bodyRevisionId == null) return BodyCache.none;
    return bodyRevisionId == currentRevisionId
        ? BodyCache.current
        : BodyCache.outdated;
  }
}

/// 条の区分。DB には `LawParser` が出す文字列のまま入るが、画面で文字列を
/// 比べると typo が型で防げないので、行を読んだところで enum に変える。
enum ArticleSection {
  main('main'),
  suppl('suppl'),
  appdx('appdx');

  const ArticleSection(this.dbValue);
  final String dbValue;

  static ArticleSection fromDb(String value) => values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => throw FormatException('unknown article section: $value'),
      );
}

extension ArticleFlags on Article {
  ArticleSection get sectionKind => ArticleSection.fromDb(section);
}

enum SyncRunStatus {
  running('running'),
  success('success'),
  error('error');

  const SyncRunStatus(this.dbValue);
  final String dbValue;

  static SyncRunStatus fromDb(String value) => values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => throw FormatException('unknown sync run status: $value'),
      );
}

extension SyncRunFlags on SyncRun {
  SyncRunStatus get statusKind => SyncRunStatus.fromDb(status);
}

enum RevisionTiming { scheduled, current, past }

extension LawRevisionFlags on LawRevision {
  /// API の `current_revision_status` が `UnEnforced`。施行日が今日以前でも
  /// この値なら未施行として扱う（施行日が暫定のことがある）。
  bool get isUnenforced => status == 'UnEnforced';

  RevisionTiming timingAt(String today, {required String? currentRevisionId}) {
    if (enforcedAt.compareTo(today) > 0 || isUnenforced) {
      return RevisionTiming.scheduled;
    }
    return revisionId == currentRevisionId
        ? RevisionTiming.current
        : RevisionTiming.past;
  }
}

typedef CatalogEntry = ({LawSummary summary, String scopeReason});

class FullTextHit {
  const FullTextHit({
    required this.lawId,
    required this.lawTitle,
    required this.section,
    required this.snippet,
    this.articleNum,
    this.articleTitle,
    this.caption,
    this.breadcrumb,
  });

  final String lawId;
  final String lawTitle;
  final ArticleSection section;
  final String? articleNum;
  final String? articleTitle;
  final String? caption;
  final String? breadcrumb;

  bool get isSuppl => section == ArticleSection.suppl;

  /// 一致箇所の前後。強調は画面側が語を探して付ける（索引経由と LIKE 経由で
  /// 抜粋の作り方が違っても、画面の処理を 1 つにするため）。
  final String snippet;
}

class LawHitCount {
  const LawHitCount(this.lawId, this.title, this.count);
  final String lawId;
  final String title;
  final int count;
}

/// ヒット一覧と法令別件数で WHERE を別々に書かないのは、片方だけ条件が変わると
/// 件数と一覧が食い違うため。
class _FullTextFilter {
  const _FullTextFilter(this.from, this.where, this.args,
      {required this.usesIndex});
  final String from;
  final String where;
  final List<Variable> args;
  final bool usesIndex;
}

_FullTextFilter? _fullTextFilter(FtsQuery q,
    {required bool includeSuppl, String? lawId}) {
  final match = q.matchExpression;
  final like = q.likePatterns;
  if (match == null && like.isEmpty) return null;
  final where = <String>[];
  final args = <Variable>[];
  if (match != null) {
    where.add('articles_fts MATCH ?');
    args.add(Variable(match));
  }
  for (final p in like) {
    where.add('a.plain_text LIKE ?');
    args.add(Variable(p));
  }
  if (!includeSuppl) {
    where.add("a.section != '${ArticleSection.suppl.dbValue}'");
  }
  if (lawId != null) {
    where.add('a.law_id = ?');
    args.add(Variable(lawId));
  }
  return _FullTextFilter(
    match == null
        ? 'articles a'
        : 'articles_fts JOIN articles a ON a.id = articles_fts.rowid',
    where.join(' AND '),
    args,
    usesIndex: match != null,
  );
}

@DriftDatabase(
    tables: [Laws, LawRevisions, Articles, SyncRuns, AppMeta, Bookmarks])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 3;

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
          await _createFullTextIndex();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await _createFullTextIndex();
            // 表を作るだけだと v1 で保存した本文が検索に出ないので、既存行を索引化する
            await customStatement(
                "INSERT INTO articles_fts(articles_fts) VALUES ('rebuild')");
          }
          if (from < 3) await m.createTable(bookmarks);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// 外部コンテンツ表にするのは、本文を `articles.plain_text` と二重に持たないため。
  /// 同期はトリガに任せる。UPDATE のトリガが無いのは、条の行は更新せず
  /// 法令単位で全削除→全挿入しかしないから（[replaceArticles]）。
  Future<void> _createFullTextIndex() async {
    await customStatement(
        "CREATE VIRTUAL TABLE articles_fts USING fts5(plain_text, caption, article_title, "
        "content='articles', content_rowid='id', tokenize='trigram')");
    await customStatement(
        'CREATE TRIGGER articles_ai AFTER INSERT ON articles BEGIN '
        'INSERT INTO articles_fts(rowid, plain_text, caption, article_title) '
        'VALUES (new.id, new.plain_text, new.caption, new.article_title); END');
    await customStatement(
        'CREATE TRIGGER articles_ad AFTER DELETE ON articles BEGIN '
        "INSERT INTO articles_fts(articles_fts, rowid, plain_text, caption, article_title) "
        "VALUES ('delete', old.id, old.plain_text, old.caption, old.article_title); END");
  }

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

  /// `body_*` 列を含めないのは、一覧側のリビジョンと保存済み本文のリビジョンを
  /// 別々に持つことで「改正あり（未取得）」を表現するため。
  /// `missing_since` を null で含めるのは、一覧に再登場した法令の印を消すため。
  static LawsCompanion _fromCatalog(LawSummary s, String scopeReason) =>
      LawsCompanion(
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

  Future<void> upsertLawFromCatalog(LawSummary s, String scopeReason) =>
      into(laws).insertOnConflictUpdate(_fromCatalog(s, scopeReason));

  /// 1 バッチにするのは、行ごとに書くとコミットと変更通知が数百回走り、
  /// 一覧の購読者がそのたびに再描画されるため。
  Future<void> applyCatalogChanges({
    required Iterable<CatalogEntry> present,
    required Iterable<String> missing,
    required String at,
  }) =>
      batch((b) {
        b.insertAllOnConflictUpdate(laws, [
          for (final e in present) _fromCatalog(e.summary, e.scopeReason),
        ]);
        for (final lawId in missing) {
          b.update(laws, LawsCompanion(missingSince: Value(at)),
              where: (t) => t.lawId.equals(lawId));
        }
      });

  Future<void> touchLaw(String lawId, String at) =>
      (update(laws)..where((t) => t.lawId.equals(lawId)))
          .write(LawsCompanion(lastOpenedAt: Value(at)));

  /// 法令名・略称・読みの部分一致。`terms` は正規化済みの候補語。
  Future<List<Law>> searchLawsByName(List<String> terms) async {
    // drift の like() は ESCAPE 句を出さず、SQLite の LIKE に既定のエスケープ文字も
    // 無いので、バックスラッシュでのエスケープは効かない。法令名に % と _ は
    // 現れないので、ワイルドカードとして解釈させずに取り除く
    final patterns = [
      for (final t in terms)
        if (t.replaceAll(RegExp('[%_]'), '') case final c when c.isNotEmpty)
          '%$c%',
    ];
    if (patterns.isEmpty) return const [];
    final rows = await (select(laws)
          ..where((t) => Expression.or([
                for (final p in patterns)
                  t.title.lower().like(p) |
                      t.abbrev.lower().like(p) |
                      t.titleKana.lower().like(p),
              ])))
        .get();
    // SQL の ORDER BY にしないのは、廃止・失効を後ろに回す並びと題名長の並びを
    // 1 つの式にすると読みにくく、件数（数百）ではメモリ上で並べ替えても十分速いから
    rows.sort((a, b) {
      if (a.isReference != b.isReference) return a.isReference ? 1 : -1;
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

  // ------------------------------------------------------------ bookmarks

  /// 条の行と外部結合するのは、本文を保存していない法令の条もブックマークでき、
  /// そのときは条名なしで一覧に出すため。
  Stream<List<BookmarkEntry>> watchBookmarks() {
    final q = select(bookmarks).join([
      innerJoin(laws, laws.lawId.equalsExp(bookmarks.lawId)),
      leftOuterJoin(
          articles,
          articles.lawId.equalsExp(bookmarks.lawId) &
              articles.articleNum.equalsExp(bookmarks.articleNum) &
              articles.section.equals('main')),
    ])
      ..orderBy([OrderingTerm.desc(bookmarks.createdAt)]);
    return q.watch().map((rows) => [
          for (final r in rows)
            BookmarkEntry(
              id: r.readTable(bookmarks).id,
              lawId: r.readTable(bookmarks).lawId,
              lawTitle: r.readTable(laws).title,
              createdAt: r.readTable(bookmarks).createdAt,
              articleNum: r.readTable(bookmarks).articleNum,
              articleTitle: r.readTableOrNull(articles)?.articleTitle,
              caption: r.readTableOrNull(articles)?.caption,
            ),
        ]);
  }

  SimpleSelectStatement<$BookmarksTable, Bookmark> _bookmarkOf(
          String lawId, String? articleNum) =>
      select(bookmarks)
        ..where((t) =>
            t.lawId.equals(lawId) &
            (articleNum == null
                ? t.articleNum.isNull()
                : t.articleNum.equals(articleNum)));

  Stream<bool> watchIsBookmarked(String lawId, String? articleNum) =>
      _bookmarkOf(lawId, articleNum).watchSingleOrNull().map((b) => b != null);

  Future<bool> isBookmarked(String lawId, String? articleNum) async =>
      await _bookmarkOf(lawId, articleNum).getSingleOrNull() != null;

  /// 追加と削除を分けずトグルにし、トランザクションで囲むのは、連打で同じ条に
  /// 2 行入るのを防ぐため。戻り値は付いた後の状態。
  Future<bool> toggleBookmark(String lawId,
          {String? articleNum, required String at}) =>
      transaction(() async {
        final existing = await _bookmarkOf(lawId, articleNum).getSingleOrNull();
        if (existing != null) {
          await (delete(bookmarks)..where((t) => t.id.equals(existing.id)))
              .go();
          return false;
        }
        await into(bookmarks).insert(BookmarksCompanion.insert(
            lawId: lawId, articleNum: Value(articleNum), createdAt: at));
        return true;
      });

  Future<void> removeBookmark(int id) =>
      (delete(bookmarks)..where((t) => t.id.equals(id))).go();

  Future<Set<String>> bookmarkedLawIds() async =>
      {for (final b in await select(bookmarks).get()) b.lawId};

  // ------------------------------------------------------ full-text search

  /// 短い語しか無いとき索引を使わないのは、trigram が 3 文字未満の語に一致しない
  /// ため（設計書 §6）。そのとき `snippet()` も使えないので、抜粋は最初の出現位置の
  /// 前後を `substr` で切り出す。
  Future<List<FullTextHit>> searchFullText(
    FtsQuery q, {
    bool includeSuppl = false,
    String? lawId,
    int limit = 50,
  }) async {
    final f = _fullTextFilter(q, includeSuppl: includeSuppl, lawId: lawId);
    if (f == null) return const [];
    final (snippet, snippetArgs) = f.usesIndex
        ? ("snippet(articles_fts, 0, '', '', '…', 24)", const <Variable>[])
        : (
            'substr(a.plain_text, max(instr(a.plain_text, ?) - 20, 1), 80)',
            [Variable(q.likeTerms.first)]
          );
    final order = f.usesIndex
        ? 'bm25(articles_fts, 1.0, 3.0, 3.0), a.seq'
        : 'a.law_id, a.seq';
    final rows = await customSelect(
      'SELECT a.law_id, l.title, a.section, a.article_num, a.article_title, '
      'a.caption, a.breadcrumb, $snippet AS snip '
      'FROM ${f.from} JOIN laws l ON l.law_id = a.law_id '
      'WHERE ${f.where} ORDER BY $order LIMIT ?',
      variables: [...snippetArgs, ...f.args, Variable(limit)],
      readsFrom: {articles, laws},
    ).get();
    return [
      for (final r in rows)
        FullTextHit(
          lawId: r.read<String>('law_id'),
          lawTitle: r.read<String>('title'),
          section: ArticleSection.fromDb(r.read<String>('section')),
          articleNum: r.readNullable<String>('article_num'),
          articleTitle: r.readNullable<String>('article_title'),
          caption: r.readNullable<String>('caption'),
          breadcrumb: r.readNullable<String>('breadcrumb'),
          snippet: r.read<String>('snip'),
        ),
    ];
  }

  Future<List<LawHitCount>> fullTextLawCounts(
    FtsQuery q, {
    bool includeSuppl = false,
    int limit = 20,
  }) async {
    final f = _fullTextFilter(q, includeSuppl: includeSuppl);
    if (f == null) return const [];
    final rows = await customSelect(
      'SELECT a.law_id, l.title, COUNT(*) AS c '
      'FROM ${f.from} JOIN laws l ON l.law_id = a.law_id '
      'WHERE ${f.where} GROUP BY a.law_id ORDER BY c DESC, l.title LIMIT ?',
      variables: [...f.args, Variable(limit)],
      readsFrom: {articles, laws},
    ).get();
    return [
      for (final r in rows)
        LawHitCount(r.read<String>('law_id'), r.read<String>('title'),
            r.read<int>('c')),
    ];
  }

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
        status: SyncRunStatus.running.dbValue,
      ));

  Future<void> finishSyncRun(
    int id, {
    required String finishedAt,
    required SyncRunStatus status,
    int lawsChecked = 0,
    int lawsUpdated = 0,
    int bytesDownloaded = 0,
    String? error,
  }) =>
      (update(syncRuns)..where((t) => t.id.equals(id))).write(SyncRunsCompanion(
        finishedAt: Value(finishedAt),
        status: Value(status.dbValue),
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
