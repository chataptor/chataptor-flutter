import 'dart:async';

/// A broadcast [Stream] wrapper that also exposes the most recently emitted
/// value synchronously, and replays it to late subscribers.
///
/// Inspired by rxdart's `BehaviorSubject` pattern but implemented without a
/// third-party dependency to keep the core package dependency surface minimal.
///
/// Typical SDK usage exposes `Stream<T>` for reactive consumers (BLoC,
/// Riverpod, Provider) while the sync `value` getter supports imperative
/// reads without awaiting.
class ValueStream<T> {
  /// Creates a [ValueStream] with no initial value.
  ValueStream();

  /// Creates a [ValueStream] seeded with [initialValue].
  ValueStream.seeded(T initialValue)
      : _value = initialValue,
        _hasValue = true;

  final StreamController<T> _controller = StreamController<T>.broadcast();
  T? _value;
  bool _hasValue = false;
  bool _closed = false;

  /// The most recently emitted value, or `null` if none has been emitted yet.
  T? get value => _value;

  /// Whether a value has ever been emitted.
  bool get hasValue => _hasValue;

  /// Whether this [ValueStream] has been closed.
  bool get isClosed => _closed;

  /// A broadcast [Stream] that emits the current [value] (if any) to each new
  /// subscriber before forwarding subsequent emissions.
  ///
  /// Uses [Stream.multi] so that the inner subscription on the underlying
  /// controller is established synchronously at listen-time, ensuring no
  /// events are missed between subscription and the first emission.
  Stream<T> get stream => Stream<T>.multi((controller) {
        if (_hasValue) controller.add(_value as T);
        final sub = _controller.stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.onCancel = sub.cancel;
      });

  /// Emits [value] to all current subscribers and stores it for late
  /// subscribers.
  ///
  /// Throws [StateError] if this [ValueStream] has been closed.
  void add(T value) {
    if (_closed) {
      throw StateError('Cannot add to a closed ValueStream.');
    }
    _value = value;
    _hasValue = true;
    _controller.add(value);
  }

  /// Closes the underlying controller. After closing, [add] throws.
  Future<void> close() async {
    _closed = true;
    await _controller.close();
  }
}
