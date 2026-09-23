import '../law/law_node.dart';

/// `/law_data` の XML レスポンス（`law_data_response`）の封筒。
///
/// `law_full_text > Law` の本文と、`revision_info` のメタを分けて持つ。
/// 保存前に [verifyRevision] で「要求したリビジョンが返ったか」を検証する
/// （設計書 §4.5 手順 2、§11 Tampering）。
class LawDataEnvelope {
  LawDataEnvelope._(this.root, this.law, this.revisionInfo, this.lawInfo);

  final LawNode root;
  final LawNode law;

  /// `revision_info` の子要素名 → テキスト。
  final Map<String, String> revisionInfo;
  final Map<String, String> lawInfo;

  String? get revisionId => revisionInfo['law_revision_id'];
  String? get lawId => lawInfo['law_id'];
  String? get title => revisionInfo['law_title'];
  String? get enforcedAt => revisionInfo['amendment_enforcement_date'];
  String? get updated => revisionInfo['updated'];

  /// XML 文字列から。`<!DOCTYPE` を含むものは拒否する（設計書 §11 DoS）。
  static LawDataEnvelope parse(String xml) {
    if (xml.contains('<!DOCTYPE')) {
      throw const FormatException('DOCTYPE is not allowed in law XML');
    }
    return fromNode(LawNode.parseXmlString(xml));
  }

  static LawDataEnvelope fromNode(LawNode root) {
    if (root.tag != 'law_data_response') {
      throw FormatException('unexpected root element <${root.tag}>');
    }
    final law = root.firstChild('law_full_text')?.firstChild('Law');
    if (law == null) {
      throw const FormatException('law_full_text/Law not found');
    }
    Map<String, String> flatten(String name) => {
          for (final e in root.firstChild(name)?.elements ?? const <LawNode>[])
            e.tag: e.text,
        };
    return LawDataEnvelope._(
        root, law, flatten('revision_info'), flatten('law_info'));
  }

  /// 要求したリビジョンと一致しなければ [RevisionMismatch]。
  void verifyRevision(String expectedRevisionId) {
    final got = revisionId;
    if (got != expectedRevisionId) {
      throw RevisionMismatch(requested: expectedRevisionId, got: got);
    }
  }
}

/// `/law_data` が要求と違うリビジョン（または `revision_info` 無し）を返した。
/// `StateError` にしないのは、呼び出し側が他のプログラム上の誤りまで
/// 「データ異常」として握りつぶさないようにするため。
class RevisionMismatch implements Exception {
  const RevisionMismatch({required this.requested, required this.got});
  final String requested;
  final String? got;

  @override
  String toString() =>
      'RevisionMismatch: requested $requested, got ${got ?? '(none)'}';
}
