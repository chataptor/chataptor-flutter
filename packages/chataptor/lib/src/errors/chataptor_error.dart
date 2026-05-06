import 'package:meta/meta.dart';

/// Base type for all recoverable errors emitted by the Chataptor SDK.
///
/// Recoverable errors flow through `ChataptorClient.errors` and the result
/// types returned by client methods (e.g. `SendResult`). For programmer
/// errors (e.g. calling `sendMessage` before `connect`), the SDK throws
/// `ChataptorStateError` or `ChataptorConfigurationError` instead.
@immutable
sealed class ChataptorError {
  /// Creates a [ChataptorError] with a human-readable [message] and optional
  /// [underlyingException] + [stackTrace] for diagnostics.
  const ChataptorError(
    this.message, {
    this.underlyingException,
    this.stackTrace,
  });

  /// Short, human-readable description of the error.
  final String message;

  /// The platform/network exception that caused this error, if any.
  final Object? underlyingException;

  /// Stack trace at the point of failure, if captured.
  final StackTrace? stackTrace;

  @override
  String toString() => 'ChataptorError: $message';
}

/// Authentication failed — typically an invalid `widgetKey` or `siteId`.
final class AuthenticationError extends ChataptorError {
  /// Creates an [AuthenticationError].
  const AuthenticationError(
    super.message, {
    super.underlyingException,
    super.stackTrace,
  });

  @override
  String toString() => 'AuthenticationError: $message';
}

/// Network-layer failure — DNS, timeout, TLS, etc.
final class NetworkError extends ChataptorError {
  /// Creates a [NetworkError].
  const NetworkError(
    super.message, {
    super.underlyingException,
    super.stackTrace,
  });

  @override
  String toString() => 'NetworkError: $message';
}

/// Server indicated the client is rate-limited.
final class RateLimitError extends ChataptorError {
  /// Creates a [RateLimitError] with the server-advertised [retryAfter] delay.
  const RateLimitError(
    super.message, {
    required this.retryAfter,
    super.underlyingException,
    super.stackTrace,
  });

  /// How long to wait before retrying.
  final Duration retryAfter;

  @override
  String toString() => 'RateLimitError: $message';
}

/// Server returned an unexpected 5xx-class error.
final class ServerError extends ChataptorError {
  /// Creates a [ServerError].
  const ServerError(
    super.message, {
    super.underlyingException,
    super.stackTrace,
  });

  @override
  String toString() => 'ServerError: $message';
}

/// Request failed validation on the server.
final class ValidationError extends ChataptorError {
  /// Creates a [ValidationError] with [fieldErrors] keyed by field name.
  const ValidationError(
    super.message, {
    required this.fieldErrors,
    super.underlyingException,
    super.stackTrace,
  });

  /// Map of field name to list of validation failure messages.
  final Map<String, List<String>> fieldErrors;

  @override
  String toString() => 'ValidationError: $message';
}

/// The transport connection dropped in the middle of an operation.
final class ConnectionLostError extends ChataptorError {
  /// Creates a [ConnectionLostError].
  const ConnectionLostError(
    super.message, {
    super.underlyingException,
    super.stackTrace,
  });

  @override
  String toString() => 'ConnectionLostError: $message';
}

/// Thrown when the SDK is used incorrectly — e.g. calling `sendMessage`
/// before `connect`.
///
/// This is a *programmer error*, not a recoverable error: if it is thrown,
/// the app has a bug that needs to be fixed in source, not handled at
/// runtime.
class ChataptorStateError extends StateError {
  /// Creates a [ChataptorStateError].
  ChataptorStateError(super.message);
}

/// Thrown when the SDK is configured incorrectly — e.g. an empty widget key.
///
/// Like [ChataptorStateError], this is a programmer error.
class ChataptorConfigurationError extends ArgumentError {
  /// Creates a [ChataptorConfigurationError].
  ChataptorConfigurationError(super.message);
}
