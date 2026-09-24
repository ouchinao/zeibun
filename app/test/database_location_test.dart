import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:zeibun/data/db/database_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final support = p.join(p.separator, 'support');
  final expectedDir = p.join(support, 'db');

  final asked = <String>[];
  setUp(() {
    asked.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(backupChannel, (call) async {
      asked.add(call.arguments as String);
      return null;
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(backupChannel, null);
  });

  test('on iOS asks the platform to exclude the db directory from backup',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final dir = await databaseDirectory(appSupportPath: () async => support);
    expect(dir, expectedDir);
    expect(asked, [expectedDir]);
  });

  test('on Android the manifest rules cover it, so the platform is not asked',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final dir = await databaseDirectory(appSupportPath: () async => support);
    expect(dir, expectedDir);
    expect(asked, isEmpty);
  });

  test('a failed exclusion still yields the directory so the DB can open',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(backupChannel, (call) async {
      throw PlatformException(code: 'exclude_failed');
    });
    final dir = await databaseDirectory(appSupportPath: () async => support);
    expect(dir, expectedDir);
  });
}
