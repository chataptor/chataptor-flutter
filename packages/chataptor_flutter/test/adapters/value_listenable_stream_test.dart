import 'package:chataptor_flutter/src/adapters/value_listenable_stream.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wraps a stream and exposes latest value', () async {
    final controller = Stream<int>.fromIterable([1, 2, 3]);
    final listenable = ValueListenableStream<int>(
      stream: controller,
      initialValue: 0,
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(listenable.value, 3);
  });

  test('notifies listeners on new emissions', () async {
    final receivedValues = <int>[];
    final controller = Stream<int>.periodic(
      const Duration(milliseconds: 5),
      (i) => i,
    ).take(3);
    final listenable = ValueListenableStream<int>(
      stream: controller,
      initialValue: -1,
    );
    listenable.addListener(() => receivedValues.add(listenable.value));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(receivedValues, isNotEmpty);
    listenable.dispose();
  });

  test('dispose cancels the subscription and disposes ValueNotifier', () async {
    final listenable = ValueListenableStream<int>(
      stream: const Stream<int>.empty(),
      initialValue: 0,
    )..dispose();
    expect(listenable, isA<ValueListenable<int>>());
  });
}
