import 'category_codes.dart';
import 'law_summary.dart';

/// 対象法令のルール（設計書 §2）。
class LawScope {
  const LawScope({
    required this.wholeCategories,
    required this.titleRules,
    required this.explicitLawIds,
  });

  /// 分類コード → 分類名。分類内の全件を対象にする。
  final Map<String, String> wholeCategories;

  /// 分類コード → 題名の正規表現。分類内で題名が一致するものを対象にする。
  final Map<String, RegExp> titleRules;

  /// 上記で漏れるものを法令 ID で明示。値は理由（法令名）。
  final Map<String, String> explicitLawIds;

  /// 税制法令の既定スコープ（実カタログ 2026-09 で確定）。
  static final LawScope tax = LawScope(
    wholeCategories: const {'013': '国税'},
    titleRules: {'036': RegExp('税')},
    explicitLawIds: const {
      // 財務通則 (003)
      '329AC0000000036': '国税収納金整理資金に関する法律',
      '329CO0000000051': '国税収納金整理資金に関する法律施行令',
      '329M50000040039': '国税収納金整理資金事務取扱規則',
      '415M60000008069': '収入印紙及び自動車重量税印紙の売りさばきに関する省令',
      '507CO0000000134': '防衛特別法人税に関する政令',
      '507M60000040031': '防衛特別法人税に関する省令',
      '508CO0000000106': '防衛特別所得税に関する政令（未施行）',
      // 行政組織 (011)
      '345CO0000000050': '国税不服審判所組織令',
      '345M50000040017': '国税不服審判所組織規則',
      '412CO0000000278': '国税審議会令',
      '425CO0000000025': '税制調査会令',
      // 行政手続 (021)
      '415M60000040071': '国税関係法令に係る情報通信技術を活用した行政の推進等に関する省令',
    },
  );

  /// 対象なら理由（`category:013` / `title:036` / `explicit`）、対象外なら null。
  String? reasonFor(LawSummary law) {
    final code = categoryCodeOf(law.category);
    if (code != null && wholeCategories.containsKey(code)) {
      return 'category:$code';
    }
    if (code != null && titleRules[code]?.hasMatch(law.title) == true) {
      return 'title:$code';
    }
    if (explicitLawIds.containsKey(law.lawId)) return 'explicit';
    return null;
  }

  /// 起動時同期で投げる `/laws` のクエリ（設計書 §4.2 ステップ 1）。
  /// `asof` と `response_format` は [EgovRequests] が付ける。
  List<Map<String, String>> catalogQueries() => [
        for (final code in wholeCategories.keys)
          {'category_cd': code, 'limit': '1000'},
        for (final code in titleRules.keys)
          {'category_cd': code, 'limit': '1000'},
        for (final id in explicitLawIds.keys) {'law_id': id},
      ];
}

/// 主要税法（設計書 §4.4 の先読みセット）。値は法令名。
const Map<String, String> majorTaxLaws = {
  '340AC0000000033': '所得税法',
  '340CO0000000096': '所得税法施行令',
  '340M50000040011': '所得税法施行規則',
  '340AC0000000034': '法人税法',
  '340CO0000000097': '法人税法施行令',
  '340M50000040012': '法人税法施行規則',
  '363AC0000000108': '消費税法',
  '363CO0000000360': '消費税法施行令',
  '363M50000040053': '消費税法施行規則',
  '325AC0000000073': '相続税法',
  '325CO0000000071': '相続税法施行令',
  '325M50000040017': '相続税法施行規則',
  '332AC0000000026': '租税特別措置法',
  '332CO0000000043': '租税特別措置法施行令',
  '332M50000040015': '租税特別措置法施行規則',
  '337AC0000000066': '国税通則法',
  '337CO0000000135': '国税通則法施行令',
  '337M50000040028': '国税通則法施行規則',
  '334AC0000000147': '国税徴収法',
  '334CO0000000329': '国税徴収法施行令',
  '337M50000040031': '国税徴収法施行規則',
  '325AC0000000226': '地方税法',
  '325CO0000000245': '地方税法施行令',
  '329M50000002023': '地方税法施行規則',
  '426AC0000000011': '地方法人税法',
  '342AC0000000035': '登録免許税法',
  '342AC0000000023': '印紙税法',
  '326AC1000000237': '税理士法',
};
