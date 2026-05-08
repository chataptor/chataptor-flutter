import 'dart:async';

import 'package:chataptor/src/transport/chat_transport.dart';
import 'package:chataptor/src/transport/transport_types.dart';

/// Record of a single call to [FakeChatTransport.push].
class RecordedPush {
  /// Creates a [RecordedPush] entry.
  RecordedPush({
    required this.topic,
    required this.event,
    required this.payload,
  });

  /// Channel topic.
  final String topic;

  /// Phoenix event name.
  final String event;

  /// Payload passed to push.
  final Map<String, dynamic> payload;
}

/// Observable record of calls made against a [FakeChatTransport].
class FakeChatTransportRecorded {
  /// Creates an empty recorder.
  FakeChatTransportRecorded();

  /// Every call to [FakeChatTransport.push], in order.
  final List<RecordedPush> pushes = [];

  /// Every channel topic that was joined, in order.
  final List<String> joinedChannels = [];
}

/// Event-injection API for driving test scenarios.
class FakeChatTransportInject {
  /// Creates an injector bound to [_transport].
  FakeChatTransportInject._(this._transport);

  final FakeChatTransport _transport;

  /// Emits [event] through the transport's events stream.
  void event(TransportEvent event) => _transport._eventsController.add(event);

  /// Emits [state] through the transport's connection state stream.
  void connectionState(TransportConnectionState state) =>
      _transport._stateController.add(state);

  /// Registers a canned [result] to return from the next matching
  /// [FakeChatTransport.push] call with the given [topic] and [event].
  void replyFor({
    required String topic,
    required String event,
    required PushResult result,
  }) {
    _transport._replyQueue
        .putIfAbsent('$topic::$event', () => <PushResult>[])
        .add(result);
  }

  /// Registers a [PushOk] reply for `conversation:create` on [siteTopic].
  ///
  /// [convId] becomes both `conversationId` and `conv_id` in the response,
  /// matching what the backend returns.
  void conversationCreated(String siteTopic, String convId) {
    replyFor(
      topic: siteTopic,
      event: 'conversation:create',
      result: PushOk({
        'conversation': {'conv_id': convId, 'conversationId': convId},
      }),
    );
  }
}

/// In-memory fake implementation of [ChatTransport] for unit / widget tests.
///
/// Ships as part of `package:chataptor/testing.dart`. Never leaks into the
/// production dependency graph of host apps (only merchants testing against
/// the SDK pull it in).
class FakeChatTransport implements ChatTransport {
  /// Creates a disconnected [FakeChatTransport].
  FakeChatTransport() {
    inject = FakeChatTransportInject._(this);
  }

  final _eventsController = StreamController<TransportEvent>.broadcast();
  final _stateController =
      StreamController<TransportConnectionState>.broadcast();
  final Map<String, List<PushResult>> _replyQueue = {};

  /// Event injection API.
  late final FakeChatTransportInject inject;

  /// Recorded calls.
  final FakeChatTransportRecorded recorded = FakeChatTransportRecorded();

  @override
  Stream<TransportEvent> get events => _eventsController.stream;

  @override
  Stream<TransportConnectionState> get connectionState =>
      _stateController.stream;

  @override
  Future<void> connect(TransportConfig config) async {
    _stateController.add(const TransportConnecting());
    await Future<void>.delayed(Duration.zero);
    _stateController.add(const TransportConnected());
  }

  @override
  Future<void> disconnect() async {
    _stateController.add(const TransportDisconnected(reason: 'user requested'));
  }

  @override
  Future<void> joinChannel(String topic, Map<String, dynamic> params) async {
    recorded.joinedChannels.add(topic);
  }

  @override
  Future<PushResult> push(
    String topic,
    String event,
    Map<String, dynamic> payload,
  ) async {
    recorded.pushes.add(
      RecordedPush(topic: topic, event: event, payload: payload),
    );
    final queue = _replyQueue['$topic::$event'];
    if (queue == null || queue.isEmpty) {
      return const PushTimeout();
    }
    return queue.removeAt(0);
  }

  @override
  Future<void> dispose() async {
    await _eventsController.close();
    await _stateController.close();
  }
}
