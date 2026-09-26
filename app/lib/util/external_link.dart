import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 外部ブラウザで開く。開けなかったときに黙らないのは、押しても何も起きない
/// ボタンに見えるため。
Future<void> openExternal(BuildContext context, Uri uri) async {
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('launchUrl failed for $uri: $e');
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('ブラウザを開けませんでした')));
  }
}
