import 'normalize.dart';

/// 税法の略称辞書（設計書 §6）。実務で使われる略称 → 正式名。
///
/// API の `abbrev`（租特法 など）は別途 [LawAbbrevIndex.withApiAbbrevs] で足す。
const Map<String, String> builtinLawAbbrevs = {
  // 法律
  '所法': '所得税法',
  '法法': '法人税法',
  '消法': '消費税法',
  '相法': '相続税法',
  '措法': '租税特別措置法',
  '租特法': '租税特別措置法',
  '通法': '国税通則法',
  '徴法': '国税徴収法',
  '地法': '地方税法',
  '地方法': '地方法人税法',
  '登法': '登録免許税法',
  '印法': '印紙税法',
  '税理士法': '税理士法',
  '評基通': '財産評価基本通達', // 通達は e-Gov に無い。候補が出ないことを示すために残す
  // 政令
  '所令': '所得税法施行令',
  '法令': '法人税法施行令',
  '消令': '消費税法施行令',
  '相令': '相続税法施行令',
  '措令': '租税特別措置法施行令',
  '通令': '国税通則法施行令',
  '徴令': '国税徴収法施行令',
  '地令': '地方税法施行令',
  // 省令
  '所規': '所得税法施行規則',
  '法規': '法人税法施行規則',
  '消規': '消費税法施行規則',
  '相規': '相続税法施行規則',
  '措規': '租税特別措置法施行規則',
  '通規': '国税通則法施行規則',
  '徴規': '国税徴収法施行規則',
  '地規': '地方税法施行規則',
  '耐用年数省令': '減価償却資産の耐用年数等に関する省令',
  '耐令': '減価償却資産の耐用年数等に関する省令',
  '電帳法': '電子計算機を使用して作成する国税関係帳簿書類の保存方法等の特例に関する法律',
  '電子帳簿保存法': '電子計算機を使用して作成する国税関係帳簿書類の保存方法等の特例に関する法律',
  '国外送金法': '内国税の適正な課税の確保を図るための国外送金等に係る調書の提出等に関する法律',
  '震災特例法': '東日本大震災の被災者等に係る国税関係法律の臨時特例に関する法律',
  '租税条約等実施特例法': '租税条約等の実施に伴う所得税法、法人税法及び地方税法の特例等に関する法律',
  '輸徴法': '輸入品に対する内国消費税の徴収等に関する法律',
  '滞調法': '滞納処分と強制執行等との手続の調整に関する法律',
  '交付税法': '地方交付税法',
};

/// 略称 → 正式名の索引。検索時に入力を展開する。
class LawAbbrevIndex {
  LawAbbrevIndex([Map<String, String>? entries])
      : _entries = {
          for (final e in (entries ?? builtinLawAbbrevs).entries)
            normalizeForSearch(e.key): e.value,
        };

  final Map<String, String> _entries;

  /// API の `abbrev`（カンマ区切り）を取り込んだ索引を返す。
  LawAbbrevIndex withApiAbbrevs(Iterable<MapEntry<String, String>> pairs) {
    final merged = Map<String, String>.from(_entries);
    for (final p in pairs) {
      for (final a in p.key.split(',')) {
        final k = normalizeForSearch(a);
        if (k.isNotEmpty) merged.putIfAbsent(k, () => p.value);
      }
    }
    return LawAbbrevIndex._raw(merged);
  }

  LawAbbrevIndex._raw(this._entries);

  /// 入力に一致する正式名。完全一致のみ（部分一致は法令名検索側で行う）。
  String? expand(String query) => _entries[normalizeForSearch(query)];

  /// 入力（略称または正式名の一部）から、検索に使う語の候補を返す。
  /// 先頭が展開後の正式名、続いて入力そのもの。
  List<String> candidates(String query) {
    final q = normalizeForSearch(query);
    if (q.isEmpty) return const [];
    final full = _entries[q];
    return full == null ? [q] : [full, q];
  }
}
