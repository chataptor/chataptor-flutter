import 'package:chataptor/src/errors/chataptor_error.dart';
import 'package:chataptor/src/models/message_draft.dart';
import 'package:meta/meta.dart';

/// Discriminated union describing the outcome of a
/// `ChataptorClient.sendMessage` call.
@immutable
sealed class SendResult {
  const SendResult();
}

/// The message was accepted by the server.
final class SendSuccess extends SendResult {
  /// Creates a [SendSuccess] with the [draft] that was accepted.
  const SendSuccess(this.draft);

  /// The draft that was successfully sent.
  final MessageDraft draft;

  @override
  bool operator ==(Object other) =>
      other is SendSuccess && other.draft == draft;

  @override
  int get hashCode => draft.hashCode;
}

/// The send attempt failed. Inspect [error] and retry with [pending] if
/// appropriate.
final class SendFailure extends SendResult {
  /// Creates a [SendFailure].
  const SendFailure(this.error, this.pending);

  /// Why the send failed.
  final ChataptorError error;

  /// The draft that was NOT successfully sent. Retry by re-submitting it.
  final MessageDraft pending;

  @override
  bool operator ==(Object other) =>
      other is SendFailure && other.error == error && other.pending == pending;

  @override
  int get hashCode => Object.hash(error, pending);
}
