import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeibun/data/platform/network_kind.dart';
import 'package:zeibun/features/prefetch/prefetch_providers.dart';

void main() {
  ProviderContainer container(Future<NetworkKind> Function() probe) {
    final c = ProviderContainer(
        overrides: [networkProbeProvider.overrideWithValue(probe)]);
    addTearDown(c.dispose);
    return c;
  }

  test('Wi-Fi starts without confirmation, mobile and unknown ask first',
      () async {
    for (final (kind, expected) in [
      (NetworkKind.unmetered, PrefetchLaunch.start),
      (NetworkKind.metered, PrefetchLaunch.confirmMetered),
      (NetworkKind.unknown, PrefetchLaunch.confirmUnknown),
    ]) {
      final c = container(() async => kind);
      expect(
          await c.read(prefetchLauncherProvider.notifier).prepare(), expected);
    }
  });

  test('a second tap while the network is being checked is ignored', () async {
    final probe = Completer<NetworkKind>();
    final c = container(() => probe.future);
    final launcher = c.read(prefetchLauncherProvider.notifier);
    final first = launcher.prepare();
    expect(c.read(prefetchLauncherProvider), isTrue, reason: '確認中');
    expect(await launcher.prepare(), isNull);
    probe.complete(NetworkKind.unmetered);
    expect(await first, PrefetchLaunch.start);
    expect(c.read(prefetchLauncherProvider), isFalse);
  });
}
