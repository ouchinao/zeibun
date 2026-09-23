/// zeibun Phase 0 スパイク: e-Gov 法令API v2 のカタログ・本文の取得と計測。
///
/// 法令のツリー・パーサ・スコープ定義は `packages/zeibun_core` に移した。
/// ここに残るのは `dart:io` を使う HTTP クライアント、計測用の合成法令、CLI。
library;

export 'package:zeibun_core/zeibun_core.dart';

export 'src/egov_client.dart';
export 'src/synth.dart';
