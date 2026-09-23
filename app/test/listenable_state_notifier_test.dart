import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeibun/providers.dart';

class _Source extends ValueNotifier<int> {
  _Source() : super(0);
  bool get listened => hasListeners;
}

void main() {
  test('follows the service listenable and lets go of it once disposed', () {
    final source = _Source();
    final provider = NotifierProvider<ListenableStateNotifier<int>, int>(
        () => ListenableStateNotifier((_) => source));
    final container = ProviderContainer();

    expect(container.read(provider), 0);
    source.value = 1;
    expect(container.read(provider), 1);

    container.dispose();
    expect(source.listened, isFalse);
  });
}
