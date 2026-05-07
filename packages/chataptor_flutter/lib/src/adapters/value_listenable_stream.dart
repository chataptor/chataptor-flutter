import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapts a [Stream] into a [ValueListenable] so merchants who prefer
/// `ValueListenableBuilder` over `StreamBuilder` can consume SDK state
/// ergonomically.
///
/// The initial value is required — [ValueListenable] must always have a
/// value.
class ValueListenableStream<T> extends ChangeNotifier
    implements ValueListenable<T> {
  /// Creates a [ValueListenableStream] subscribed to [stream], starting
  /// from [initialValue].
  ValueListenableStream({required Stream<T> stream, required T initialValue})
    : _notifier = ValueNotifier<T>(initialValue) {
    _subscription = stream.listen((event) {
      _notifier.value = event;
      notifyListeners();
    });
  }

  final ValueNotifier<T> _notifier;
  late final StreamSubscription<T> _subscription;

  @override
  T get value => _notifier.value;

  @override
  void dispose() {
    _subscription.cancel();
    _notifier.dispose();
    super.dispose();
  }
}
