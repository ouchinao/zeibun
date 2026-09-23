import 'package:test/test.dart';
import 'package:zeibun_core/zeibun_core.dart';

void main() {
  final index = LawAbbrevIndex();

  test('expands practitioner abbreviations', () {
    expect(index.expand('法法'), '法人税法');
    expect(index.expand('措令'), '租税特別措置法施行令');
    expect(index.expand('地規'), '地方税法施行規則');
    expect(index.expand('電帳法'), startsWith('電子計算機を使用して'));
  });

  test('is width-insensitive', () {
    expect(index.expand('措法'), '租税特別措置法');
    expect(index.candidates('ＡＢＣ'), ['abc']);
  });

  test('candidates put the expanded title first', () {
    expect(index.candidates('所法'), ['所得税法', '所法']);
    expect(index.candidates('法人税'), ['法人税']);
    expect(index.candidates('  '), isEmpty);
  });

  test('merges API abbrevs without overriding built-ins', () {
    final merged = index.withApiAbbrevs([
      const MapEntry('租特法,租特', '租税特別措置法'),
      const MapEntry('法法', 'ダミー'), // 既存は上書きしない
    ]);
    expect(merged.expand('租特'), '租税特別措置法');
    expect(merged.expand('法法'), '法人税法');
  });
}
