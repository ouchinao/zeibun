import '../db/database.dart';

/// 画面が DB を直接触らないための薄い層。時刻もここで入れる（テストで固定するため）。
class BookmarkRepository {
  BookmarkRepository({required this.db, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _clock;

  Stream<List<BookmarkEntry>> watchAll() => db.watchBookmarks();

  Stream<bool> watchIsBookmarked(String lawId, {String? articleNum}) =>
      db.watchIsBookmarked(lawId, articleNum);

  /// 付いた後の状態を返す（true なら追加された）。
  Future<bool> toggle(String lawId, {String? articleNum}) =>
      db.toggleBookmark(lawId,
          articleNum: articleNum, at: _clock().toIso8601String());

  Future<void> remove(int id) => db.removeBookmark(id);
}
