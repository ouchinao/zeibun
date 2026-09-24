// experimental 扱いの remote.dart を使うのは、DriftRemoteException がここにしか無いため
// （drift_flutter 自身が同じ型を使っている）
// ignore: experimental_member_use
import 'package:drift/remote.dart';
import 'package:sqlite3/common.dart';

/// 事前に空き容量を測らず書き込み失敗で判定するのは、空き容量を読むプラグインの
/// 保守が薄く、失敗理由を分ける方が確実なため（設計書 §11 D、Phase R R10）。
/// `DriftRemoteException` を剥がすのは、drift_flutter が DB を別 isolate で動かし、
/// SQLite の例外がその封筒に入って届くため。
bool isStorageFull(Object error) => switch (error) {
      SqliteException(:final resultCode) => resultCode == SqlError.SQLITE_FULL,
      DriftRemoteException(:final remoteCause) => isStorageFull(remoteCause),
      _ => false,
    };
