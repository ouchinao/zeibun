import 'package:meta/meta.dart';

/// `repeal_status` の値。`none` 以外は廃止・失効・停止・実効性喪失で、
/// 一覧には「参考」として載せる。
abstract final class RepealStatus {
  static const none = 'None';

  static bool isReference(String status) => status != none;
}

/// `GET /laws` の 1 行（`law_info` + 現行の `revision_info`）を平らにしたもの。
///
/// `asof` 付きの一覧では `current_revision_info` が現行、`revision_info` が
/// その時点で最新（未施行を含む）の履歴になる（設計書 §4.2）。
@immutable
class LawSummary {
  const LawSummary({
    required this.lawId,
    required this.lawNum,
    required this.lawType,
    required this.title,
    this.titleKana,
    this.abbrev,
    this.category,
    this.promulgationDate,
    this.repealStatus = RepealStatus.none,
    this.repealDate,
    this.updated,
    this.currentRevisionId,
    this.currentEnforcedAt,
    this.amendmentLawTitle,
    this.pendingRevisionId,
  });

  final String lawId;
  final String lawNum;
  final String lawType;
  final String title;
  final String? titleKana;

  /// API の略称。カンマ区切りで複数のことがある。
  final String? abbrev;
  final String? category;
  final String? promulgationDate;

  /// `None` / `Repeal` / `Expire` / `Suspend` / `LossOfEffectiveness`
  final String repealStatus;
  final String? repealDate;

  /// 現行履歴の `updated`（正誤等によるデータ更新日時）。
  final String? updated;

  /// 現行リビジョン。
  final String? currentRevisionId;
  final String? currentEnforcedAt;
  final String? amendmentLawTitle;

  /// 未施行改正があるとき、`asof` 遠未来側の履歴 ID（現行と異なる）。
  final String? pendingRevisionId;

  /// 廃止・失効した法令（一覧に「参考」として載せる）。
  bool get isReference => RepealStatus.isReference(repealStatus);

  bool get hasPendingAmendment =>
      pendingRevisionId != null && pendingRevisionId != currentRevisionId;

  /// 略称を個々に分けたもの。
  List<String> get abbrevs => (abbrev ?? '')
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList(growable: false);

  /// `/laws` レスポンスの `laws[]` 要素から。
  ///
  /// `current_revision_info` があればそれを現行とし、`revision_info` の
  /// `law_revision_id` が異なれば未施行改正ありとみなす。判定に
  /// `current_revision_status` は使わない（asof 基準で評価され、現行でも
  /// `PreviousEnforced` になることがある。2026-09-23 実測）。
  ///
  /// [currentRow] は `current_revision_info` が返らなかったときの保険で、
  /// 同じ法令を `asof` なしで取った行。その `revision_info` を現行として使う。
  factory LawSummary.fromApiRow(Map<String, dynamic> row,
      {Map<String, dynamic>? currentRow}) {
    final info = _map(row['law_info']);
    final asofRev = _map(row['revision_info']);
    final currentRev = row['current_revision_info'] is Map
        ? _map(row['current_revision_info'])
        : currentRow != null
            ? _map(currentRow['revision_info'])
            : asofRev;
    final currentId = currentRev['law_revision_id'] as String?;
    final asofId = asofRev['law_revision_id'] as String?;
    return LawSummary(
      lawId: info['law_id'] as String,
      lawNum: info['law_num'] as String? ?? '',
      lawType: info['law_type'] as String? ??
          currentRev['law_type'] as String? ??
          '',
      title: currentRev['law_title'] as String? ??
          asofRev['law_title'] as String? ??
          '',
      titleKana: currentRev['law_title_kana'] as String?,
      abbrev: currentRev['abbrev'] as String?,
      category: currentRev['category'] as String?,
      promulgationDate: info['promulgation_date'] as String?,
      repealStatus: currentRev['repeal_status'] as String? ?? RepealStatus.none,
      repealDate: currentRev['repeal_date'] as String?,
      updated: currentRev['updated'] as String?,
      currentRevisionId: currentId,
      currentEnforcedAt: currentRev['amendment_enforcement_date'] as String?,
      amendmentLawTitle: currentRev['amendment_law_title'] as String?,
      pendingRevisionId: asofId != null && asofId != currentId ? asofId : null,
    );
  }

  static Map<String, dynamic> _map(Object? o) =>
      o is Map ? o.cast<String, dynamic>() : const {};

  @override
  String toString() => 'LawSummary($lawId $title rev=$currentRevisionId)';
}

/// `GET /law_revisions/{law_id}` の `revisions[]` 要素。
@immutable
class LawRevisionInfo {
  const LawRevisionInfo({
    required this.revisionId,
    required this.enforcedAt,
    this.promulgatedAt,
    this.scheduledEnforcedAt,
    this.enforcementComment,
    this.amendmentLawId,
    this.amendmentLawNum,
    this.amendmentLawTitle,
    this.amendmentType,
    this.status,
    this.updated,
  });

  final String revisionId;
  final String enforcedAt;
  final String? promulgatedAt;
  final String? scheduledEnforcedAt;
  final String? enforcementComment;
  final String? amendmentLawId;
  final String? amendmentLawNum;
  final String? amendmentLawTitle;
  final String? amendmentType;

  /// `CurrentEnforced` / `PreviousEnforced` / `UnEnforced` / `Repeal`
  final String? status;
  final String? updated;

  factory LawRevisionInfo.fromApi(Map<String, dynamic> m) => LawRevisionInfo(
        revisionId: m['law_revision_id'] as String,
        enforcedAt: m['amendment_enforcement_date'] as String? ?? '',
        promulgatedAt: m['amendment_promulgate_date'] as String?,
        scheduledEnforcedAt:
            m['amendment_scheduled_enforcement_date'] as String?,
        enforcementComment: m['amendment_enforcement_comment'] as String?,
        amendmentLawId: m['amendment_law_id'] as String?,
        amendmentLawNum: m['amendment_law_num'] as String?,
        amendmentLawTitle: m['amendment_law_title'] as String?,
        amendmentType: m['amendment_type'] as String?,
        status: m['current_revision_status'] as String?,
        updated: m['updated'] as String?,
      );
}
