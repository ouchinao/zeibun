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

  /// 一回きりの問い合わせ。メニューの項目名のように「開く瞬間の値」だけ要る
  /// ところで使う。ストリームの Provider を一回読みに使うと、購読者が無いまま
  /// 破棄されて例外になる。
  Future<bool> isBookmarked(String lawId, {String? articleNum}) =>
      db.isBookmarked(lawId, articleNum);

  /// 付いた後の状態を返す（true なら追加された）。
  Future<bool> toggle(String lawId, {String? articleNum}) =>
      db.toggleBookmark(lawId,
          articleNum: articleNum, at: _clock().toIso8601String());

  Future<void> remove(int id) => db.removeBookmark(id);
}
