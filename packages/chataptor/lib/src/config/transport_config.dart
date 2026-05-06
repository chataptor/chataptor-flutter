import 'dart:math' as math;

import 'package:meta/meta.dart';

/// When the SDK holds the WebSocket connection open.
enum ConnectionMode {
  /// Default. Connect when chat UI opens, disconnect when it closes. Lowest
  /// battery and data cost. Background delivery relies on push notifications
  /// (merchant-supplied FCM hook-in).
  lazy,

  /// Connect while the app is in the foreground; disconnect when the app
  /// goes to the background. Good for live unread badges in a running app.
  /// Respects platform reality — iOS kills background sockets.
  foregroundActive,
}

/// Declarative description of how the SDK should retry after a disconnect.
@immutable
class ReconnectionPolicy {
  /// Creates a [ReconnectionPolicy] with an explicit [delays] list.
  const ReconnectionPolicy(this.delays);

  /// Exponential backoff with an upper bound.
  ///
  /// Produces [maxAttempts] entries: `initialDelay`,
  /// `initialDelay * factor`, `initialDelay * factor^2`, ..., each capped at
  /// [maxDelay].
  factory ReconnectionPolicy.exponentialBackoff({
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
    double factor = 2,
    int maxAttempts = 10,
  }) {
    final delays = <Duration>[];
    for (var i = 0; i < maxAttempts; i++) {
      final ms = (initialDelay.inMilliseconds * math.pow(factor, i)).toInt();
      delays.add(Duration(milliseconds: math.min(ms, maxDelay.inMilliseconds)));
    }
    return ReconnectionPolicy(delays);
  }

  /// Delay schedule the transport walks through on each successive retry.
  final List<Duration> delays;
}

/// Transport-layer configuration exposed via `ChataptorConfig`.
@immutable
class TransportClientConfig {
  /// Creates a [TransportClientConfig] with sensible defaults.
  const TransportClientConfig({
    this.connectionMode = ConnectionMode.lazy,
    this.heartbeatInterval = const Duration(seconds: 30),
    this.reconnection = _defaultReconnection,
  });

  /// Connection lifecycle mode.
  final ConnectionMode connectionMode;

  /// Phoenix heartbeat interval.
  final Duration heartbeatInterval;

  /// Retry schedule on disconnect.
  final ReconnectionPolicy reconnection;

  /// Returns a copy with the given fields overridden.
  TransportClientConfig copyWith({
    ConnectionMode? connectionMode,
    Duration? heartbeatInterval,
    ReconnectionPolicy? reconnection,
  }) {
    return TransportClientConfig(
      connectionMode: connectionMode ?? this.connectionMode,
      heartbeatInterval: heartbeatInterval ?? this.heartbeatInterval,
      reconnection: reconnection ?? this.reconnection,
    );
  }

  // Precomputed default matching exponentialBackoff(initialDelay: 1s,
  // maxDelay: 30s, factor: 2, maxAttempts: 10). Must be const because it is
  // used as a default parameter value.
  static const ReconnectionPolicy _defaultReconnection = ReconnectionPolicy([
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
    Duration(seconds: 30),
    Duration(seconds: 30),
    Duration(seconds: 30),
    Duration(seconds: 30),
    Duration(seconds: 30),
  ]);
}
