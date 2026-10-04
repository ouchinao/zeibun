// iOS の起動画面の画像（ios/Runner/Assets.xcassets/LaunchImage.imageset）を、
// アイコンの原画（assets/icon/icon.png）から作り直す。
//
//   cd app && dart run tool/update_launch_image.dart
//
// アイコンを差し替えたら `dart run flutter_launcher_icons` と一緒に流す。
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

/// 起動画面に置く大きさ（pt）。
const _pt = 128;

void main() {
  final src = img.decodePng(File('assets/icon/icon.png').readAsBytesSync())!;
  const out = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
  for (final scale in [1, 2, 3]) {
    final size = _pt * scale;
    final icon = img
        .copyResize(src,
            width: size, height: size, interpolation: img.Interpolation.cubic)
        .convert(numChannels: 4);
    _roundCorners(icon, radius: size * 0.2237);
    final name = scale == 1 ? 'LaunchImage.png' : 'LaunchImage@${scale}x.png';
    File('$out/$name').writeAsBytesSync(img.encodePng(icon));
    stdout.writeln('$name ${size}x$size');
  }
}

/// 角を丸める。原画を角丸にしないのは、ホーム画面のアイコンは iOS が角を
/// 切り抜くため（原画に丸みがあると二重になる）。起動画面は切り抜かれない。
void _roundCorners(img.Image image, {required double radius}) {
  final size = image.width;
  double overshoot(int i) {
    final c = i + 0.5;
    if (c < radius) return radius - c;
    if (c > size - radius) return c - (size - radius);
    return 0;
  }

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = overshoot(x), dy = overshoot(y);
      if (dx == 0 || dy == 0) continue;
      // 縁を透明か不透明かの 2 値で切り抜かないのは、ぎざぎざに見えるため
      final coverage = (radius - sqrt(dx * dx + dy * dy) + 0.5).clamp(0.0, 1.0);
      final p = image.getPixel(x, y);
      image.setPixelRgba(x, y, p.r, p.g, p.b, (p.a * coverage).round());
    }
  }
}
