import 'package:chataptor/src/client/connection_state.dart';
import 'package:chataptor/src/errors/chataptor_error.dart';
import 'package:chataptor/src/models/agent_info.dart';
import 'package:chataptor/src/models/message.dart';
import 'package:chataptor/src/models/message_draft.dart';
import 'package:meta/meta.dart';

/// Collection of optional callbacks and interceptors merchants pass in
/// [ChataptorConfig].
///
/// - **Event callbacks** (`onMessageReceived`, `onUnreadCountChanged`, ...)
///   fire with the new value and are fire-and-forget. Use for imperative
///   side effects (app badge, analytics).
/// - **Interceptors** (`beforeSend`, `beforeReceive`) can transform or
///   cancel the in-flight message by returning `null`.
@immutable
class ChataptorHooks {
  /// Creates a [ChataptorHooks] with every slot optional.
  const ChataptorHooks({
    this.onMessageReceived,
    this.onMessageSent,
    this.onMessageFailed,
    this.onAgentAssigned,
    this.onUnreadCountChanged,
    this.onConnectionStateChanged,
    this.onError,
    this.beforeSend,
    this.beforeReceive,
  });

  /// Called after every incoming message (agent or bot → customer).
  final void Function(Message)? onMessageReceived;

  /// Called after every customer message that was successfully sent.
  final void Function(Message)? onMessageSent;

  /// Called when a send attempt failed and surfaced a [SendFailure].
  final void Function(ChataptorError)? onMessageFailed;

  /// Called when an agent is (re)assigned to the conversation.
  final void Function(AgentInfo)? onAgentAssigned;

  /// Called every time the unread-count changes.
  final void Function(int)? onUnreadCountChanged;

  /// Called on every [ConnectionState] transition.
  final void Function(ConnectionState)? onConnectionStateChanged;

  /// Called on every [ChataptorError] emitted through the client's `errors`
  /// stream.
  final void Function(ChataptorError)? onError;

  /// Async interceptor invoked before every send. Return a modified
  /// [MessageDraft] to alter the outgoing payload, or `null` to cancel
  /// sending entirely.
  final Future<MessageDraft?> Function(MessageDraft)? beforeSend;

  /// Async interceptor invoked before every incoming [Message] is dispatched
  /// to the `messages` stream. Return a modified [Message] to transform it,
  /// or `null` to drop it.
  final Future<Message?> Function(Message)? beforeReceive;
}
