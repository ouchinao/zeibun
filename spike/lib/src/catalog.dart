/// `GET /laws` の 1 行（`law_info` + `revision_info`）を平らにしたもの。
class LawSummary {
  LawSummary({
    required this.lawId,
    required this.lawNum,
    required this.lawType,
    required this.title,
    this.titleKana,
    this.abbrev,
    this.category,
    this.promulgationDate,
    this.repealStatus = 'None',
    this.updated,
    this.currentRevisionId,
    this.currentEnforcedAt,
    this.currentRevisionStatus,
    this.amendmentLawTitle,
  });

  final String lawId;
  final String lawNum;
  final String lawType;
  final String title;
  final String? titleKana;
  final String? abbrev;
  final String? category;
  final String? promulgationDate;
  final String repealStatus;
  final String? updated;
  final String? currentRevisionId;
  final String? currentEnforcedAt;
  final String? currentRevisionStatus;
  final String? amendmentLawTitle;

  /// API のレスポンス（`laws[]` の要素）から。
  factory LawSummary.fromApi(Map<String, dynamic> row) {
    final info = (row['law_info'] as Map?)?.cast<String, dynamic>() ?? const {};
    final rev =
        (row['revision_info'] as Map?)?.cast<String, dynamic>() ?? const {};
    return LawSummary(
      lawId: info['law_id'] as String,
      lawNum: info['law_num'] as String? ?? '',
      lawType: info['law_type'] as String? ?? rev['law_type'] as String? ?? '',
      title: rev['law_title'] as String? ?? '',
      titleKana: rev['law_title_kana'] as String?,
      abbrev: rev['abbrev'] as String?,
      category: rev['category'] as String?,
      promulgationDate: info['promulgation_date'] as String?,
      repealStatus: rev['repeal_status'] as String? ?? 'None',
      updated: rev['updated'] as String?,
      currentRevisionId: rev['law_revision_id'] as String?,
      currentEnforcedAt: rev['amendment_enforcement_date'] as String?,
      currentRevisionStatus: rev['current_revision_status'] as String?,
      amendmentLawTitle: rev['amendment_law_title'] as String?,
    );
  }

  /// `fixtures/catalog_tax_snapshot.json` の行から。
  factory LawSummary.fromSnapshot(Map<String, dynamic> row) => LawSummary(
        lawId: row['law_id'] as String,
        lawNum: row['law_num'] as String? ?? '',
        lawType: row['law_type'] as String? ?? '',
        title: row['title'] as String? ?? '',
        titleKana: row['title_kana'] as String?,
        abbrev: row['abbrev'] as String?,
        category: row['category'] as String?,
        promulgationDate: row['promulgation_date'] as String?,
        repealStatus: row['repeal_status'] as String? ?? 'None',
        updated: row['updated'] as String?,
        currentRevisionId: row['current_revision_id'] as String?,
        currentEnforcedAt: row['current_enforced_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'law_id': lawId,
        'law_num': lawNum,
        'law_type': lawType,
        'title': title,
        'title_kana': titleKana,
        'abbrev': abbrev,
        'category': category,
        'promulgation_date': promulgationDate,
        'repeal_status': repealStatus,
        'updated': updated,
        'current_revision_id': currentRevisionId,
        'current_enforced_at': currentEnforcedAt,
        'current_revision_status': currentRevisionStatus,
      };
}

/// 公式仕様 (lawapi-v2.yaml v2.1.138) の `category_cd` 一覧。
///
/// 注意: 調査メモ v0.1 では「国税=023, 財務通則=021, 地方財政=008」と推定していたが、
/// 公式表では 国税=013、財務通則=003、地方財政=036、行政組織=011。
/// 023 は「国債」、021 は「行政手続」、008 は「国有財産」。
const Map<String, String> categoryCodes = {
  '001': '憲法',
  '002': '刑事',
  '003': '財務通則',
  '004': '水産業',
  '005': '観光',
  '006': '国会',
  '007': '警察',
  '008': '国有財産',
  '009': '鉱業',
  '010': '郵務',
  '011': '行政組織',
  '012': '消防',
  '013': '国税',
  '014': '工業',
  '015': '電気通信',
  '016': '国家公務員',
  '017': '国土開発',
  '018': '事業',
  '019': '商業',
  '020': '労働',
  '021': '行政手続',
  '022': '土地',
  '023': '国債',
  '024': '金融・保険',
  '025': '環境保全',
  '026': '統計',
  '027': '都市計画',
  '028': '教育',
  '029': '外国為替・貿易',
  '030': '厚生',
  '031': '地方自治',
  '032': '道路',
  '033': '文化',
  '034': '陸運',
  '035': '社会福祉',
  '036': '地方財政',
  '037': '河川',
  '038': '産業通則',
  '039': '海運',
  '040': '社会保険',
  '041': '司法',
  '042': '災害対策',
  '043': '農業',
  '044': '航空',
  '045': '防衛',
  '046': '民事',
  '047': '建築・住宅',
  '048': '林業',
  '049': '貨物運送',
  '050': '外事',
};

String? categoryCodeOf(String name) {
  for (final e in categoryCodes.entries) {
    if (e.value == name) return e.key;
  }
  return null;
}

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

  /// 上記で漏れるものを法令IDで明示。値は理由（法令名）。
  final Map<String, String> explicitLawIds;

  /// 税制法令の既定スコープ。
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

  /// 対象なら理由文字列（`category:013` / `title:036` / `explicit`）、対象外なら null。
  String? reasonFor(LawSummary law) {
    final code = law.category == null ? null : categoryCodeOf(law.category!);
    if (code != null && wholeCategories.containsKey(code)) {
      return 'category:$code';
    }
    if (code != null && titleRules[code]?.hasMatch(law.title) == true) {
      return 'title:$code';
    }
    if (explicitLawIds.containsKey(law.lawId)) return 'explicit';
    return null;
  }

  /// 起動時同期で投げる `/laws` クエリの一覧（設計書 §4.2 ステップ1）。
  List<Map<String, String>> catalogQueries() => [
        for (final code in wholeCategories.keys)
          {'category_cd': code, 'limit': '1000'},
        for (final code in titleRules.keys)
          {'category_cd': code, 'limit': '1000'},
        for (final id in explicitLawIds.keys) {'law_id': id},
      ];
}

/// 主要税法（設計書 §4.5 の先読みセット、Phase 0 の計測対象）。
/// 値は 2026-09 時点のカタログでの現行リビジョン（`fetch` はまず `/laws?law_id=` で取り直す）。
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

/// 設計書 §13 Phase 0-3 の「主要税法 10 件」。
const List<String> benchmarkLawIds = [
  '340AC0000000033', // 所得税法
  '340CO0000000096', // 所得税法施行令
  '340AC0000000034', // 法人税法
  '340CO0000000097', // 法人税法施行令
  '363AC0000000108', // 消費税法
  '325AC0000000073', // 相続税法
  '332AC0000000026', // 租税特別措置法
  '332CO0000000043', // 租税特別措置法施行令
  '337AC0000000066', // 国税通則法
  '325AC0000000226', // 地方税法
];
