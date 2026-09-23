import 'package:meta/meta.dart';

import '../catalog/law_summary.dart';

/// 起動時同期の突合結果の種別（設計書 §4.2 ステップ 3）。
enum CatalogChangeKind {
  /// ローカルに無い法令。
  added,

  /// 現行リビジョンが変わった（改正の施行 / 施行日到来）。
  revised,

  /// リビジョンは同じだが `updated` が変わった（訂正・再登録）。
  corrected,

  /// 変化なし。
  unchanged,

  /// ローカルにあるが一覧から消えた（削除せずフラグだけ立てる）。
  missing,
}

/// ローカル `laws` テーブルの突合に必要な列。
@immutable
class LocalLawState {
  const LocalLawState({
    required this.lawId,
    this.currentRevisionId,
    this.catalogUpdated,
  });

  final String lawId;
  final String? currentRevisionId;
  final String? catalogUpdated;
}

@immutable
class CatalogChange {
  const CatalogChange({
    required this.lawId,
    required this.kind,
    this.remote,
    this.previousRevisionId,
  });

  final String lawId;
  final CatalogChangeKind kind;

  /// 一覧側の行。`missing` のときは null。
  final LawSummary? remote;

  /// `revised` のときの以前のリビジョン。
  final String? previousRevisionId;

  @override
  String toString() => 'CatalogChange($kind $lawId)';
}

@immutable
class CatalogDiff {
  const CatalogDiff(this.changes);

  final List<CatalogChange> changes;

  Iterable<CatalogChange> ofKind(CatalogChangeKind kind) =>
      changes.where((c) => c.kind == kind);

  int get added => ofKind(CatalogChangeKind.added).length;
  int get revised => ofKind(CatalogChangeKind.revised).length;
  int get corrected => ofKind(CatalogChangeKind.corrected).length;
  int get missing => ofKind(CatalogChangeKind.missing).length;

  /// 未施行改正がある法令の数（一覧側の情報。ローカルとの比較ではない）。
  int get pending =>
      changes.where((c) => c.remote?.hasPendingAmendment == true).length;

  /// 本文キャッシュを持つなら取り直す必要がある法令。
  Iterable<CatalogChange> get needsRefetch => changes.where((c) =>
      c.kind == CatalogChangeKind.revised ||
      c.kind == CatalogChangeKind.corrected);
}

/// 一覧（リモート）とローカルを突合する。比較には `law_revision_id` と
/// `updated` だけを使う（`current_revision_status` は使わない）。
CatalogDiff diffCatalog({
  required Iterable<LawSummary> remote,
  required Iterable<LocalLawState> local,
}) {
  final localById = {for (final l in local) l.lawId: l};
  final seen = <String>{};
  final changes = <CatalogChange>[];

  for (final r in remote) {
    seen.add(r.lawId);
    final l = localById[r.lawId];
    if (l == null) {
      changes.add(CatalogChange(
          lawId: r.lawId, kind: CatalogChangeKind.added, remote: r));
    } else if (l.currentRevisionId != r.currentRevisionId) {
      changes.add(CatalogChange(
        lawId: r.lawId,
        kind: CatalogChangeKind.revised,
        remote: r,
        previousRevisionId: l.currentRevisionId,
      ));
    } else if (l.catalogUpdated != r.updated) {
      changes.add(CatalogChange(
          lawId: r.lawId, kind: CatalogChangeKind.corrected, remote: r));
    } else {
      changes.add(CatalogChange(
          lawId: r.lawId, kind: CatalogChangeKind.unchanged, remote: r));
    }
  }
  for (final l in local) {
    if (!seen.contains(l.lawId)) {
      changes
          .add(CatalogChange(lawId: l.lawId, kind: CatalogChangeKind.missing));
    }
  }
  return CatalogDiff(changes);
}
