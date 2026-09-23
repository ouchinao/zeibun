/// zeibun Phase 0 スパイク: e-Gov 法令API v2 のカタログ・本文の取得と計測。
///
/// Flutter に依存しない純 Dart。`lib/src` の `LawNode` / `LawParser` は
/// Phase 1 で `lib/data/parser` に移す前提で書いている。
library;

export 'src/catalog.dart';
export 'src/egov_client.dart';
export 'src/law_node.dart';
export 'src/law_parser.dart';
export 'src/synth.dart';
