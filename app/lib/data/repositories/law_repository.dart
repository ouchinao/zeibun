import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:zeibun_core/zeibun_core.dart';

import '../db/database.dart';
import '../egov/egov_api.dart';

/// 本文の取得結果。
enum BodyStatus {
  /// キャッシュが現行と一致。通信なし
  fresh,

  /// 取得して更新した
  fetched,

  /// 取得できず、古いキャッシュを表示中
  stale,

  /// 取得できず、キャッシュも無い
  unavailable,
}

/// 取得できなかった理由。例外をそのまま画面に渡さないのは、画面が dio や
/// XML の例外型を知らずに文言を選べるようにするため。
enum BodyFailure {
  offline,

  /// 4xx/5xx と受信上限超過。e-Gov 側の応答なので再試行しても直らない
  server,

  /// XML の異常とリビジョン不一致
  invalidData,
}

class BodyLoadResult {
  const BodyLoadResult(this.status, this.articles, {this.failure});
  final BodyStatus status;
  final List<Article> articles;
  final BodyFailure? failure;
}

/// 法令を開くときの本文取得・キャッシュ（設計書 §4.2 a〜c、§4.5）。
class LawRepository {
  LawRepository({
    required this.api,
    required this.db,
    EgovRequests? requests,
    DateTime Function()? clock,
    this.revisionsMaxAge = const Duration(minutes: 10),
  })  : requests = requests ?? EgovRequests(),
        _clock = clock ?? DateTime.now;

  final EgovApi api;
  final AppDatabase db;
  final EgovRequests requests;
  final DateTime Function() _clock;

  final Duration revisionsMaxAge;

  /// 法令を開く。キャッシュが現行なら通信せず返す。違えば取得して差し替える。
  ///
  /// [includeAmendSuppl] を指定すると、その設定で取り直す（改正附則の読み込み）。
  /// 省略時は前回の設定（`body_includes_amend_suppl`）を引き継ぐ。
  Future<BodyLoadResult> openLaw(String lawId,
      {bool? includeAmendSuppl, bool force = false}) async {
    final law = await db.getLaw(lawId);
    if (law == null) {
      return const BodyLoadResult(BodyStatus.unavailable, []);
    }
    await db.touchLaw(lawId, _clock().toIso8601String());
    final wantSuppl = includeAmendSuppl ?? law.bodyIncludesAmendSuppl;
    final rev = law.currentRevisionId;
    if (rev == null) return _fromCache(lawId);
    final cachedIsCurrent =
        law.bodyRevisionId == rev && law.bodyIncludesAmendSuppl == wantSuppl;
    if (cachedIsCurrent && !force) {
      return BodyLoadResult(BodyStatus.fresh, await db.articlesOf(lawId));
    }
    try {
      await fetchBody(lawId, rev, includeAmendSuppl: wantSuppl);
      return BodyLoadResult(BodyStatus.fetched, await db.articlesOf(lawId));
    } on EgovApiException catch (e) {
      return _fromCache(lawId,
          failure: e.kind.isOffline ? BodyFailure.offline : BodyFailure.server);
    } on FormatException {
      return _fromCache(lawId, failure: BodyFailure.invalidData);
    } on RevisionMismatch {
      return _fromCache(lawId, failure: BodyFailure.invalidData);
    }
  }

  Future<BodyLoadResult> _fromCache(String lawId,
      {BodyFailure? failure}) async {
    final cached = await db.articlesOf(lawId);
    return BodyLoadResult(
      cached.isEmpty ? BodyStatus.unavailable : BodyStatus.stale,
      cached,
      failure: failure,
    );
  }

  /// `/law_data` から本文を取り、検証してパースし、1 トランザクションで差し替える。
  ///
  /// `/law_file` を使わないのは gzip が効かず所得税法で 16MB がそのまま流れるため。
  /// `Isolate.run` ではなく `compute` なのは、Web でも同じ呼び出しで動くから
  /// （Web ではメインスレッドで実行される）。
  /// `void` ではなく受信バイト数を返すのは、全法令の保存で進捗に受信量を出すため。
  Future<int> fetchBody(String lawId, String revisionId,
      {required bool includeAmendSuppl}) async {
    final uri = requests.lawDataXml(revisionId,
        includeAmendmentSuppl: includeAmendSuppl);
    final bytes = await api.getBytes(uri);
    final rows = await compute(parseLawXmlToRows,
        ParseRequest(xml: bytes, expectedRevisionId: revisionId));
    await db.replaceArticles(
      lawId: lawId,
      revisionId: revisionId,
      rows: rows,
      includesAmendSuppl: includeAmendSuppl,
      syncedAt: _clock().toIso8601String(),
    );
    return bytes.length;
  }

  /// 改正された法令の本文を先読みする（設計書 §4.4）。
  /// 改正された全件を取り直さないのは、年度替わりには数百件が一斉に改正され、
  /// 起動時の通信が数百 MB になるため。主要税法と最近開いたものに絞る。
  Future<void> prefetchRevised(Iterable<CatalogChange> changes) async {
    final cutoff =
        _clock().subtract(const Duration(days: 30)).toIso8601String();
    for (final c in changes) {
      final law = await db.getLaw(c.lawId);
      final rev = law?.currentRevisionId;
      if (law == null || rev == null || law.bodyCache == BodyCache.none) {
        continue;
      }
      final recent = (law.lastOpenedAt ?? '').compareTo(cutoff) > 0;
      if (!majorTaxLaws.containsKey(c.lawId) && !recent) continue;
      try {
        await fetchBody(c.lawId, rev,
            includeAmendSuppl: law.bodyIncludesAmendSuppl);
      } catch (e) {
        // 先読みは補助なので、1 件の失敗で残りを止めない。開いたときに取り直す
        debugPrint('prefetch failed for ${c.lawId}: $e');
      }
    }
  }

  /// タブを開くたびに取り直さないのは、改正履歴が日に何度も変わるものではなく、
  /// 同じ法令を行き来するだけで e-Gov へのリクエストが増えるため。
  Future<List<LawRevision>> refreshRevisions(String lawId) async {
    final cached = await db.revisionsOf(lawId);
    if (cached.isNotEmpty) {
      final fetchedAt = DateTime.tryParse(cached.first.fetchedAt);
      if (fetchedAt != null &&
          _clock().difference(fetchedAt) < revisionsMaxAge) {
        return cached;
      }
    }
    try {
      final body = await api.getJson(requests.lawRevisions(lawId));
      final revs = [
        for (final r in (body['revisions'] as List? ?? const []))
          LawRevisionInfo.fromApi((r as Map).cast<String, dynamic>()),
      ];
      await db.replaceRevisions(lawId, revs, _clock().toIso8601String());
    } on EgovApiException catch (e) {
      debugPrint('revisions fetch failed for $lawId: $e');
    } on FormatException catch (e) {
      debugPrint('revisions response malformed for $lawId: $e');
    }
    return db.revisionsOf(lawId);
  }

  /// 一覧まで消さないのは、消した直後にオフラインでも検索と一覧が使えるようにするため。
  Future<void> clearBodies() => db.clearBodies();
}

/// Isolate に渡すパース要求。
class ParseRequest {
  const ParseRequest({required this.xml, required this.expectedRevisionId});

  /// UTF-8 のまま渡し、デコードも Isolate 側で行う（16MB の文字列を 2 度作らない）。
  final Uint8List xml;
  final String expectedRevisionId;
}

/// Isolate（Web ではメインスレッド）で実行するパース。
///
/// `LawNode` をそのまま返さず文字列だけの DTO にするのは、Isolate 間のコピーを
/// 小さくし、DB へ渡す形と一致させるため。
List<ArticleRow> parseLawXmlToRows(ParseRequest req) {
  final env = LawDataEnvelope.parse(utf8.decode(req.xml));
  env.verifyRevision(req.expectedRevisionId);
  final records = const LawParser().parse(env.law);
  return [
    for (final r in records)
      ArticleRow(
        seq: r.seq,
        section: r.section,
        supplAmendLawNum: r.supplAmendLawNum,
        path: r.path,
        articleNum: r.articleNum,
        articleTitle: r.articleTitle,
        caption: r.caption,
        breadcrumb: r.breadcrumb,
        plainText: normalizeWidth(r.plainText),
        bodyJson: jsonEncode(r.body.toJson()),
      ),
  ];
}
