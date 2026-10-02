import 'law_summary.dart';

/// アプリに同梱する法令一覧。e-Gov に接続できない初回起動でも一覧と法令名の
/// 検索を使えるようにする（設計書 §4.1）。
class CatalogSnapshot {
  const CatalogSnapshot({required this.generatedAt, required this.laws});

  /// 取得した日時（ISO 8601）。同期の成功とは扱わない。
  final String generatedAt;
  final List<LawSummary> laws;

  Map<String, dynamic> toJson() => {
        'generated_at': generatedAt,
        'laws': [for (final l in laws) l.toJson()],
      };

  factory CatalogSnapshot.fromJson(Map<String, dynamic> j) => CatalogSnapshot(
        generatedAt: j['generated_at'] as String,
        laws: [
          for (final l in j['laws'] as List)
            LawSummary.fromJson((l as Map).cast<String, dynamic>()),
        ],
      );
}
