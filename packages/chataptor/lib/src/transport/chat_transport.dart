import 'package:chataptor/src/transport/transport_types.dart';

/// Port abstraction over the WebSocket transport.
///
/// The reference implementation (`PhoenixSocketTransport`) uses the
/// `phoenix_socket` package. Tests and examples can substitute
/// `FakeChatTransport`. The public SDK never leaks the concrete
/// implementation type.
abstract interface class ChatTransport {
  /// Opens the socket and transitions through [TransportConnectionState]s.
  ///
  /// Implementations MUST:
  /// - Be safe to call multiple times (re-invocation after a disconnect
  ///   should re-open; re-invocation on an open transport is a no-op).
  /// - Start emitting [TransportConnectionState] updates via
  ///   [connectionState] immediately.
  /// - NOT throw; errors flow through the [connectionState] stream as
  ///   [TransportDisconnected] with an informative `reason`.
  Future<void> connect(TransportConfig config);

  /// Leaves all channels and closes the socket. Idempotent.
  Future<void> disconnect();

  /// Joins (or re-joins) a Phoenix channel with the given [params]. The
  /// transport routes subsequent pushes on [topic] via [push] and emits
  /// incoming events through [events].
  ///
  /// Implementations MUST:
  /// - Complete successfully only after the channel has been joined (reply
  ///   received).
  /// - Throw a plain [Exception] if the server rejects the join.
  Future<void> joinChannel(String topic, Map<String, dynamic> params);

  /// Pushes [event] with [payload] to [topic]. Returns a [PushResult]
  /// reflecting the server's reply (or a timeout/disconnect marker).
  Future<PushResult> push(
    String topic,
    String event,
    Map<String, dynamic> payload,
  );

  /// All incoming events across every joined channel.
  Stream<TransportEvent> get events;

  /// Transport-level connection lifecycle.
  Stream<TransportConnectionState> get connectionState;

  /// Tears down controllers and releases resources. After [dispose] the
  /// transport is unusable.
  Future<void> dispose();
}
