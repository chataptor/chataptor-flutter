import 'package:meta/meta.dart';

/// Internal configuration passed to a [ChatTransport] on connect.
///
/// Not exposed through the public SDK API — callers configure the client
/// via `ChataptorConfig`, and the client translates that into a
/// [TransportConfig] before handing it to the transport.
@immutable
class TransportConfig {
  /// Creates a [TransportConfig].
  const TransportConfig({
    required this.url,
    required this.params,
    required this.heartbeatInterval,
    required this.reconnectionDelays,
  });

  /// WebSocket URL (e.g. `wss://api.chataptor.com/socket/websocket`).
  final Uri url;

  /// Query-string / join-payload parameters (widget key, site id, platform,
  /// customer data, ...).
  final Map<String, dynamic> params;

  /// Heartbeat interval. Phoenix default is 30 s.
  final Duration heartbeatInterval;

  /// Explicit backoff schedule for reconnect attempts. The transport cycles
  /// through this list and repeats the last entry indefinitely.
  final List<Duration> reconnectionDelays;
}

/// Lifecycle state of the transport itself — a lower-level view of the
/// connection than the SDK's public [ConnectionState].
@immutable
sealed class TransportConnectionState {
  const TransportConnectionState();
}

/// Transport is opening its first connection.
final class TransportConnecting extends TransportConnectionState {
  /// Creates a [TransportConnecting] state.
  const TransportConnecting();
}

/// Transport is open and ready.
final class TransportConnected extends TransportConnectionState {
  /// Creates a [TransportConnected] state.
  const TransportConnected();
}

/// Transport lost its connection and is retrying.
final class TransportReconnecting extends TransportConnectionState {
  /// Creates a [TransportReconnecting] state.
  const TransportReconnecting({
    required this.attemptNumber,
    required this.nextAttemptIn,
  });

  /// 1-based retry count.
  final int attemptNumber;

  /// Delay before the next retry.
  final Duration nextAttemptIn;
}

/// Transport is closed and not retrying (either due to user request or a
/// fatal error).
final class TransportDisconnected extends TransportConnectionState {
  /// Creates a [TransportDisconnected] state with a human-readable [reason].
  const TransportDisconnected({required this.reason});

  /// Human-readable disconnect reason.
  final String reason;
}

/// An event emitted by the transport. Channel-scoped — each event carries
/// the topic it belongs to so the client can route without leaking channel
/// handles.
@immutable
sealed class TransportEvent {
  const TransportEvent();
}

/// The server pushed an event on [topic].
final class MessageReceived extends TransportEvent {
  /// Creates a [MessageReceived] event.
  const MessageReceived({
    required this.topic,
    required this.event,
    required this.payload,
  });

  /// Channel topic (e.g. `site:abc-shop`, `conversation:42`).
  final String topic;

  /// Phoenix event name (e.g. `message:received`).
  final String event;

  /// Raw payload map as emitted by the server.
  final Map<String, dynamic> payload;
}

/// A channel was closed — either because the client left it or the server
/// kicked it.
final class ChannelClosed extends TransportEvent {
  /// Creates a [ChannelClosed] event.
  const ChannelClosed({required this.topic, required this.reason});

  /// Channel topic that closed.
  final String topic;

  /// Human-readable reason.
  final String reason;
}

/// Non-fatal channel-level error.
final class ChannelError extends TransportEvent {
  /// Creates a [ChannelError] event.
  const ChannelError({required this.topic, required this.message});

  /// Channel topic that errored.
  final String topic;

  /// Human-readable error message.
  final String message;
}

/// Outcome of a `ChatTransport.push` operation.
@immutable
sealed class PushResult {
  const PushResult();
}

/// The push was acknowledged by the server.
final class PushOk extends PushResult {
  /// Creates a [PushOk] with the server's reply [response].
  const PushOk(this.response);

  /// Server reply payload.
  final Map<String, dynamic> response;
}

/// The server explicitly rejected the push.
final class PushServerError extends PushResult {
  /// Creates a [PushServerError].
  const PushServerError({required this.reason, required this.response});

  /// Short human-readable reason.
  final String reason;

  /// Server reply payload (often contains details).
  final Map<String, dynamic> response;
}

/// The push timed out waiting for a server reply.
final class PushTimeout extends PushResult {
  /// Creates a [PushTimeout].
  const PushTimeout();
}

/// The transport was disconnected before the push could be acknowledged.
final class PushDisconnected extends PushResult {
  /// Creates a [PushDisconnected].
  const PushDisconnected();
}
