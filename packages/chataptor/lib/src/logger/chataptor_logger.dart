/// Severity of a log record.
enum ChataptorLogLevel {
  /// Verbose diagnostic detail. Usually silenced in release.
  debug,

  /// Informational lifecycle events.
  info,

  /// Recoverable anomalies worth surfacing.
  warn,

  /// Failures that prevented an operation from completing.
  error,
}

/// Single log record.
class ChataptorLogEntry {
  /// Creates a [ChataptorLogEntry].
  const ChataptorLogEntry({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  /// Severity.
  final ChataptorLogLevel level;

  /// Short human-readable message.
  final String message;

  /// Optional attached exception.
  final Object? error;

  /// Optional attached stack trace.
  final StackTrace? stackTrace;
}

/// Port abstraction over logging. Merchants implement this to forward SDK
/// logs into Sentry, AppSignal, `dart:developer`, etc.
// ignore: one_member_abstracts
abstract interface class ChataptorLogger {
  /// Writes a single log entry.
  void log(
    ChataptorLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });
}

/// Default no-op logger used when none is supplied.
class NoOpChataptorLogger implements ChataptorLogger {
  /// Creates a [NoOpChataptorLogger].
  const NoOpChataptorLogger();

  @override
  void log(
    ChataptorLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Intentionally empty.
  }
}

/// In-memory logger useful in tests. Captures every call.
class RecordingChataptorLogger implements ChataptorLogger {
  /// Creates a [RecordingChataptorLogger].
  RecordingChataptorLogger();

  /// Entries captured so far, in order.
  final List<ChataptorLogEntry> entries = [];

  @override
  void log(
    ChataptorLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    entries.add(
      ChataptorLogEntry(
        level: level,
        message: message,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
