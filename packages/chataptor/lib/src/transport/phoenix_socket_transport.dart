import 'dart:async';

import 'package:chataptor/src/transport/chat_transport.dart';
import 'package:chataptor/src/transport/transport_types.dart';
import 'package:phoenix_socket/phoenix_socket.dart' as phx;

/// Production [ChatTransport] implementation built on top of the
/// `phoenix_socket` package (v0.8.x).
///
/// This adapter:
/// - Maps `phoenix_socket` lifecycle events to our internal
///   [TransportConnectionState] stream.
/// - Wraps channels so consumers route all events through a single
///   [events] broadcast stream.
/// - Normalises push outcomes to [PushResult] cases.
class PhoenixSocketTransport implements ChatTransport {
  /// Creates a disconnected [PhoenixSocketTransport]. Call [connect] to open
  /// the socket.
  PhoenixSocketTransport();

  phx.PhoenixSocket? _socket;
  final Map<String, phx.PhoenixChannel> _channels = {};
  final _eventsController = StreamController<TransportEvent>.broadcast();
  final _stateController =
      StreamController<TransportConnectionState>.broadcast();

  StreamSubscription<phx.PhoenixSocketOpenEvent>? _openSub;
  StreamSubscription<phx.PhoenixSocketCloseEvent>? _closeSub;
  StreamSubscription<phx.PhoenixSocketErrorEvent>? _errorSub;

  int _reconnectAttempt = 0;

  @override
  Stream<TransportEvent> get events => _eventsController.stream;

  @override
  Stream<TransportConnectionState> get connectionState =>
      _stateController.stream;

  @override
  Future<void> connect(TransportConfig config) async {
    if (_socket != null) return;
    _stateController.add(const TransportConnecting());

    final socket = phx.PhoenixSocket(
      config.url.toString(),
      socketOptions: phx.PhoenixSocketOptions(
        params: _stringifyParams(config.params),
        heartbeat: config.heartbeatInterval,
        reconnectDelays: config.reconnectionDelays,
      ),
    );
    _socket = socket;

    // phoenix_socket 0.8.0 exposes separate open/close/error streams;
    // there is no combined stateStream.
    _openSub = socket.openStream.listen((_) {
      _stateController.add(const TransportConnected());
      _reconnectAttempt = 0;
    });

    _closeSub = socket.closeStream.listen((event) {
      _stateController.add(
        TransportDisconnected(reason: event.reason ?? 'socket closed'),
      );
    });

    _errorSub = socket.errorStream.listen((event) {
      _reconnectAttempt += 1;
      _stateController.add(
        TransportReconnecting(
          attemptNumber: _reconnectAttempt,
          nextAttemptIn: const Duration(seconds: 1),
        ),
      );
      _eventsController.add(
        ChannelError(topic: '_socket', message: event.error.toString()),
      );
    });

    // connect() in 0.8.0 handles reconnects internally and never throws.
    unawaited(socket.connect());
  }

  @override
  Future<void> disconnect() async {
    final socket = _socket;
    if (socket == null) return;

    for (final channel in _channels.values) {
      channel.leave();
    }
    _channels.clear();

    await _openSub?.cancel();
    await _closeSub?.cancel();
    await _errorSub?.cancel();
    _openSub = null;
    _closeSub = null;
    _errorSub = null;

    socket.close();
    _socket = null;

    _stateController.add(
      const TransportDisconnected(reason: 'user requested'),
    );
  }

  @override
  Future<void> joinChannel(String topic, Map<String, dynamic> params) async {
    final socket = _requireSocket();
    if (_channels.containsKey(topic)) return;

    // addChannel returns an existing channel if the topic was added before;
    // since we guard with containsKey, this is always a fresh channel here.
    final channel = socket.addChannel(
      topic: topic,
      parameters: params,
    );
    _channels[topic] = channel;

    // Route all server-pushed events through our events stream.
    // channel.messages in 0.8.0 passes both user events and phx_close/phx_error.
    channel.messages.listen((msg) {
      final eventName = msg.event.value;
      if (eventName == 'phx_close') {
        _eventsController.add(
          ChannelClosed(topic: topic, reason: 'channel_closed'),
        );
        return;
      }
      if (eventName == 'phx_error') {
        _eventsController.add(
          ChannelError(topic: topic, message: 'channel_error'),
        );
        return;
      }
      _eventsController.add(
        MessageReceived(
          topic: topic,
          event: eventName,
          payload: _asMap(msg.payload),
        ),
      );
    });

    final joinPush = channel.join();
    final response = await joinPush.future;
    if (response.isError) {
      throw Exception('Failed to join channel $topic: ${response.response}');
    }
  }

  @override
  Future<PushResult> push(
    String topic,
    String event,
    Map<String, dynamic> payload,
  ) async {
    final channel = _channels[topic];
    if (channel == null) {
      return const PushDisconnected();
    }
    final push = channel.push(event, payload);
    try {
      final response = await push.future;
      if (response.isOk) {
        return PushOk(_asMap(response.response));
      }
      return PushServerError(
        reason: 'server error',
        response: _asMap(response.response),
      );
    } on phx.ChannelTimeoutException {
      return const PushTimeout();
    } catch (err) {
      return PushServerError(
        reason: err.toString(),
        response: const {},
      );
    }
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _eventsController.close();
    await _stateController.close();
  }

  phx.PhoenixSocket _requireSocket() {
    final s = _socket;
    if (s == null) {
      throw StateError('Transport not connected — call connect() first.');
    }
    return s;
  }

  Map<String, String> _stringifyParams(Map<String, dynamic> input) {
    final out = <String, String>{};
    for (final entry in input.entries) {
      final v = entry.value;
      if (v == null) continue;
      out[entry.key] = v is String ? v : v.toString();
    }
    return out;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}
