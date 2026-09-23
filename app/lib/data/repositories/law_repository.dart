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

  /// オフラインで古いキャッシュを表示中
  stale,

  /// 取得できず、キャッシュも無い
  unavailable,
}

class BodyLoadResult {
  const BodyLoadResult(this.status, this.articles, {this.error});
  final BodyStatus status;
  final List<Article> articles;
  final Object? error;
}

/// 法令を開くときの本文取得・キャッシュ（設計書 §4.2 a〜c、§4.5）。
class LawRepository {
  LawRepository({
    required this.api,
    required this.db,
    EgovRequests? requests,
    DateTime Function()? clock,
  })  : requests = requests ?? EgovRequests(),
        _clock = clock ?? DateTime.now;

  final EgovApi api;
  final AppDatabase db;
  final EgovRequests requests;
  final DateTime Function() _clock;

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
    final cachedIsCurrent = rev != null &&
        law.bodyRevisionId == rev &&
        law.bodyIncludesAmendSuppl == wantSuppl;
    if (cachedIsCurrent && !force) {
      return BodyLoadResult(BodyStatus.fresh, await db.articlesOf(lawId));
    }
    if (rev == null) {
      final cached = await db.articlesOf(lawId);
      return BodyLoadResult(
          cached.isEmpty ? BodyStatus.unavailable : BodyStatus.stale, cached);
    }
    try {
      await fetchBody(lawId, rev, includeAmendSuppl: wantSuppl);
      return BodyLoadResult(BodyStatus.fetched, await db.articlesOf(lawId));
    } catch (e) {
      debugPrint('body fetch failed for $lawId: $e');
      final cached = await db.articlesOf(lawId);
      return BodyLoadResult(
        cached.isEmpty ? BodyStatus.unavailable : BodyStatus.stale,
        cached,
        error: e,
      );
    }
  }

  /// `/law_data` から本文を取り、検証してパースし、1 トランザクションで差し替える。
  ///
  /// `/law_file` を使わないのは gzip が効かず所得税法で 16MB がそのまま流れるため。
  /// `Isolate.run` ではなく `compute` なのは、Web でも同じ呼び出しで動くから
  /// （Web ではメインスレッドで実行される）。
  Future<void> fetchBody(String lawId, String revisionId,
      {required bool includeAmendSuppl}) async {
    final uri = requests.lawDataXml(revisionId,
        includeAmendmentSuppl: includeAmendSuppl);
    final xml = await api.getText(uri);
    final rows = await compute(parseLawXmlToRows,
        ParseRequest(xml: xml, expectedRevisionId: revisionId));
    await db.replaceArticles(
      lawId: lawId,
      revisionId: revisionId,
      rows: rows,
      includesAmendSuppl: includeAmendSuppl,
      syncedAt: _clock().toIso8601String(),
    );
  }

  /// 改正履歴を取り直す（改正履歴タブを開いたとき）。
  Future<List<LawRevision>> refreshRevisions(String lawId) async {
    try {
      final body = await api.getJson(requests.lawRevisions(lawId));
      final revs = [
        for (final r in (body['revisions'] as List? ?? const []))
          LawRevisionInfo.fromApi((r as Map).cast<String, dynamic>()),
      ];
      await db.replaceRevisions(lawId, revs, _clock().toIso8601String());
    } catch (e) {
      debugPrint('revisions fetch failed for $lawId: $e');
    }
    return db.revisionsOf(lawId);
  }
}

/// Isolate に渡すパース要求。
class ParseRequest {
  const ParseRequest({required this.xml, required this.expectedRevisionId});
  final String xml;
  final String expectedRevisionId;
}

/// Isolate（Web ではメインスレッド）で実行するパース。
///
/// `LawNode` をそのまま返さず文字列だけの DTO にするのは、Isolate 間のコピーを
/// 小さくし、DB へ渡す形と一致させるため。
List<ArticleRow> parseLawXmlToRows(ParseRequest req) {
  final env = LawDataEnvelope.parse(req.xml);
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
