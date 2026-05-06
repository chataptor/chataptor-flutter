import 'package:meta/meta.dart';

/// Why the client disconnected.
enum DisconnectReason {
  /// User called `ChataptorClient.disconnect`.
  userRequested,

  /// Network-level error (DNS, timeout, TLS).
  networkError,

  /// Server closed the connection.
  serverClosed,

  /// Authentication failed during connect.
  authenticationFailed,

  /// Configuration error that prevents connecting.
  configurationError,
}

/// Discriminated union describing the lifecycle of the underlying transport
/// connection.
@immutable
sealed class ConnectionState {
  const ConnectionState();
}

/// The client is attempting to establish its first connection.
final class Connecting extends ConnectionState {
  /// Creates a [Connecting] state.
  const Connecting();

  @override
  bool operator ==(Object other) => other is Connecting;

  @override
  int get hashCode => (Connecting).hashCode;
}

/// The client has an active connection and is ready to send/receive.
final class Connected extends ConnectionState {
  /// Creates a [Connected] state.
  const Connected();

  @override
  bool operator ==(Object other) => other is Connected;

  @override
  int get hashCode => (Connected).hashCode;
}

/// The client lost its connection and is retrying.
final class Reconnecting extends ConnectionState {
  /// Creates a [Reconnecting] state describing the next retry attempt.
  const Reconnecting({
    required this.nextAttemptIn,
    required this.attemptNumber,
  });

  /// Delay before the next reconnect attempt.
  final Duration nextAttemptIn;

  /// 1-based attempt number (first retry is `1`).
  final int attemptNumber;

  @override
  bool operator ==(Object other) =>
      other is Reconnecting &&
      other.nextAttemptIn == nextAttemptIn &&
      other.attemptNumber == attemptNumber;

  @override
  int get hashCode => Object.hash(nextAttemptIn, attemptNumber);
}

/// The client is disconnected and not currently retrying.
final class Disconnected extends ConnectionState {
  /// Creates a [Disconnected] state with the given [reason].
  const Disconnected(this.reason);

  /// Why the client is disconnected.
  final DisconnectReason reason;

  @override
  bool operator ==(Object other) =>
      other is Disconnected && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}
