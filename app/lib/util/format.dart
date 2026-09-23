/// 日時・法令種別などの表示用フォーマット（`intl` を使わない軽量版）。
library;

String _two(int n) => n.toString().padLeft(2, '0');

/// `09:12` / 別日なら `9/21 09:12`。
String formatTime(DateTime t) {
  final local = t.toLocal();
  final now = DateTime.now();
  final hm = '${_two(local.hour)}:${_two(local.minute)}';
  if (local.year == now.year &&
      local.month == now.month &&
      local.day == now.day) {
    return hm;
  }
  return '${local.month}/${local.day} $hm';
}

/// ISO 8601 文字列を `2026-09-23 14:17` に。解釈できなければそのまま。
String formatIso(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final t = DateTime.tryParse(iso);
  if (t == null) return iso;
  final l = t.toLocal();
  return '${l.year}-${_two(l.month)}-${_two(l.day)} ${_two(l.hour)}:${_two(l.minute)}';
}

/// `YYYY-MM-DD` → `2026年9月23日`。
String formatDate(String? ymd) {
  if (ymd == null || ymd.isEmpty) return '—';
  final p = ymd.split('-');
  if (p.length != 3) return ymd;
  return '${p[0]}年${int.tryParse(p[1]) ?? p[1]}月${int.tryParse(p[2]) ?? p[2]}日';
}

const Map<String, String> lawTypeLabels = {
  'Constitution': '憲法',
  'Act': '法律',
  'CabinetOrder': '政令',
  'ImperialOrder': '勅令',
  'MinisterialOrdinance': '府省令',
  'Rule': '規則',
  'Misc': 'その他',
};

String lawTypeLabel(String type) => lawTypeLabels[type] ?? type;

const Map<String, String> repealStatusLabels = {
  'Repeal': '廃止',
  'Expire': '失効',
  'Suspend': '停止',
  'LossOfEffectiveness': '実効性喪失',
};

String repealStatusLabel(String status) => repealStatusLabels[status] ?? status;
