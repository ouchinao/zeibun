import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/common.dart';
import 'package:zeibun/data/db/storage_errors.dart';

void main() {
  test('SQLITE_FULL means the device ran out of space', () {
    expect(
        isStorageFull(SqliteException(
            extendedResultCode: SqlError.SQLITE_FULL, message: 'full')),
        isTrue);
  });

  test('other SQLite errors and non-SQLite errors are not a full disk', () {
    expect(
        isStorageFull(SqliteException(
            extendedResultCode: SqlError.SQLITE_BUSY, message: 'busy')),
        isFalse);
    expect(isStorageFull(StateError('boom')), isFalse);
  });
}
