import 'package:chataptor/src/streams/value_stream.dart';
import 'package:test/test.dart';

void main() {
  group('ValueStream', () {
    test('has no value initially', () {
      final vs = ValueStream<int>();
      expect(vs.hasValue, isFalse);
      expect(vs.value, isNull);
    });

    test('stores value after add', () {
      final vs = ValueStream<int>()..add(42);
      expect(vs.hasValue, isTrue);
      expect(vs.value, 42);
    });

    test('emits current value to late subscriber', () async {
      final vs = ValueStream<int>()..add(7);
      final first = await vs.stream.first;
      expect(first, 7);
    });

    test('emits all subsequent values', () async {
      final vs = ValueStream<int>();
      final received = <int>[];
      final sub = vs.stream.listen(received.add);
      vs
        ..add(1)
        ..add(2)
        ..add(3);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(received, [1, 2, 3]);
    });

    test(
      'late subscriber sees latest value then subsequent emissions',
      () async {
        final vs = ValueStream<int>()
          ..add(10)
          ..add(20);
        final received = <int>[];
        final sub = vs.stream.listen(received.add);
        await Future<void>.delayed(Duration.zero);
        vs.add(30);
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();
        expect(received, [20, 30]);
      },
    );

    test('supports multiple listeners (broadcast)', () async {
      final vs = ValueStream<int>();
      final a = <int>[];
      final b = <int>[];
      final subA = vs.stream.listen(a.add);
      final subB = vs.stream.listen(b.add);
      vs.add(1);
      await Future<void>.delayed(Duration.zero);
      await subA.cancel();
      await subB.cancel();
      expect(a, [1]);
      expect(b, [1]);
    });

    test('close prevents further additions', () async {
      final vs = ValueStream<int>();
      await vs.close();
      expect(() => vs.add(1), throwsStateError);
    });

    test('seeded() has hasValue=true and correct value immediately', () {
      final vs = ValueStream<int>.seeded(99);
      expect(vs.hasValue, isTrue);
      expect(vs.value, 99);
    });

    test('seeded() emits initial value to first subscriber', () async {
      final vs = ValueStream<int>.seeded(42);
      final first = await vs.stream.first;
      expect(first, 42);
    });

    test('nullable T: null is a valid value distinct from no-value', () {
      final vs = ValueStream<int?>();
      expect(vs.hasValue, isFalse);
      vs.add(null);
      expect(vs.hasValue, isTrue);
      expect(vs.value, isNull);
    });

    test('nullable T seeded with null has hasValue=true', () {
      final vs = ValueStream<int?>.seeded(null);
      expect(vs.hasValue, isTrue);
      expect(vs.value, isNull);
    });
  });
}
