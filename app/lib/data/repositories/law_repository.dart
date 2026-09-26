import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:zeibun_core/zeibun_core.dart';

import '../db/database.dart';
import '../db/storage_errors.dart';
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
/// XML や SQLite の例外型を知らずに文言を選べるようにするため。
/// 本文と改正履歴で同じ型なのは、どちらも「通信 → 検証 → 保存」で失敗の
/// 種類が同じだから。
enum FetchFailure {
  offline,

  /// 4xx/5xx と受信上限超過。e-Gov 側の応答なので再試行しても直らない
  server,

  /// XML / JSON の異常とリビジョン不一致
  invalidData,

  /// 端末の空き容量が尽きて保存できなかった。通信失敗と同じ「再試行」に
  /// 寄せないのは、空きを作らない限り何度やっても同じ結果だから
  storageFull,
}

/// 分類できない例外に「その他」の値を用意しないのは、画面が生の例外文字列を
/// 文言に流し込む逃げ道になるため。null を返し、呼び出し側で投げ直す。
FetchFailure? classifyFetchError(Object e) => switch (e) {
      EgovApiException(kind: final k) when k.isOffline => FetchFailure.offline,
      EgovApiException() => FetchFailure.server,
      FormatException() || RevisionMismatch() => FetchFailure.invalidData,
      _ when isStorageFull(e) => FetchFailure.storageFull,
      _ => null,
    };

class BodyLoadResult {
  const BodyLoadResult(this.status, this.articles, {this.failure});
  final BodyStatus status;
  final List<Article> articles;
  final FetchFailure? failure;
}

/// 本文をどう開くか。`bool?` と `force` の組み合わせにしないのは、
/// 「null で前回設定を引き継ぐ」が呼び出し側で読めなかったため。
enum BodyRequest {
  /// 前回の設定（改正附則を含むか）のまま。キャッシュが現行なら通信しない
  keepSetting,

  /// 改正附則込みで取り直し、以後その設定で保存する
  withAmendSuppl,

  /// キャッシュが現行でも取り直す（再試行ボタン）
  refresh,
}

class RevisionsResult {
  const RevisionsResult(this.revisions, {this.failure});
  final List<LawRevision> revisions;
  final FetchFailure? failure;
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
  Future<BodyLoadResult> openLaw(String lawId,
      {BodyRequest request = BodyRequest.keepSetting}) async {
    final law = await db.getLaw(lawId);
    if (law == null) {
      return const BodyLoadResult(BodyStatus.unavailable, []);
    }
    await db.touchLaw(lawId, _clock().toIso8601String());
    final wantSuppl =
        request == BodyRequest.withAmendSuppl || law.bodyIncludesAmendSuppl;
    final rev = law.currentRevisionId;
    if (rev == null) return _fromCache(lawId);
    final cachedIsCurrent =
        law.bodyRevisionId == rev && law.bodyIncludesAmendSuppl == wantSuppl;
    if (cachedIsCurrent && request != BodyRequest.refresh) {
      return BodyLoadResult(BodyStatus.fresh, await db.articlesOf(lawId));
    }
    try {
      await fetchBody(lawId, rev, includeAmendSuppl: wantSuppl);
      return BodyLoadResult(BodyStatus.fetched, await db.articlesOf(lawId));
    } catch (e) {
      final failure = classifyFetchError(e);
      if (failure == null) rethrow;
      return _fromCache(lawId, failure: failure);
    }
  }

  Future<BodyLoadResult> _fromCache(String lawId,
      {FetchFailure? failure}) async {
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
    final bookmarked = await db.bookmarkedLawIds();
    for (final c in changes) {
      final law = await db.getLaw(c.lawId);
      final rev = law?.currentRevisionId;
      if (law == null || rev == null || law.bodyCache == BodyCache.none) {
        continue;
      }
      final recent = (law.lastOpenedAt ?? '').compareTo(cutoff) > 0;
      final wanted = majorTaxLaws.containsKey(c.lawId) ||
          recent ||
          bookmarked.contains(c.lawId);
      if (!wanted) continue;
      try {
        await fetchBody(c.lawId, rev,
            includeAmendSuppl: law.bodyIncludesAmendSuppl);
      } catch (e) {
        // 空き容量が尽きたら残りも全部失敗するので、同期側に伝えて止める
        if (isStorageFull(e)) rethrow;
        // それ以外は補助なので、1 件の失敗で残りを止めない。開いたときに取り直す
        debugPrint('prefetch failed for ${c.lawId}: $e');
      }
    }
  }

  /// タブを開くたびに取り直さないのは、改正履歴が日に何度も変わるものではなく、
  /// 同じ法令を行き来するだけで e-Gov へのリクエストが増えるため。
  /// 失敗を握りつぶさず [FetchFailure] で返すのは、履歴が空のとき画面が
  /// 「オフライン？」と推測せずに理由を言い切るため。
  Future<RevisionsResult> refreshRevisions(String lawId) async {
    final cached = await db.revisionsOf(lawId);
    if (cached.isNotEmpty) {
      final fetchedAt = DateTime.tryParse(cached.first.fetchedAt);
      if (fetchedAt != null &&
          _clock().difference(fetchedAt) < revisionsMaxAge) {
        return RevisionsResult(cached);
      }
    }
    FetchFailure? failure;
    try {
      final body = await api.getJson(requests.lawRevisions(lawId));
      final revs = [
        for (final r in (body['revisions'] as List? ?? const []))
          LawRevisionInfo.fromApi((r as Map).cast<String, dynamic>()),
      ];
      await db.replaceRevisions(lawId, revs, _clock().toIso8601String());
    } catch (e) {
      failure = classifyFetchError(e);
      if (failure == null) rethrow;
      debugPrint('revisions fetch failed for $lawId: $e');
    }
    return RevisionsResult(await db.revisionsOf(lawId), failure: failure);
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
