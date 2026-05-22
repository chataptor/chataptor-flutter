import 'dart:async';

import 'package:chataptor/src/auth/customer_identity.dart';
import 'package:chataptor/src/client/chataptor_client.dart';
import 'package:chataptor/src/client/connection_state.dart';
import 'package:chataptor/src/client/send_result.dart';
import 'package:chataptor/src/errors/chataptor_error.dart';
import 'package:chataptor/src/models/agent_info.dart';
import 'package:chataptor/src/models/message.dart';
import 'package:chataptor/src/models/message_draft.dart';
import 'package:chataptor/src/streams/value_stream.dart';

/// Records every interaction made against a [FakeChataptorClient].
class FakeChataptorClientRecorded {
  /// Creates an empty recorder.
  FakeChataptorClientRecorded();

  /// Every draft that was sent through [FakeChataptorClient.sendMessage].
  final List<MessageDraft> sentMessages = [];

  /// Every `connect()` call.
  int connectCalls = 0;

  /// Every `disconnect()` call.
  int disconnectCalls = 0;

  /// Every `clearSession()` call.
  int clearSessionCalls = 0;

  /// Every [CustomerIdentity] passed to `identify()`, in call order. Use to
  /// assert that a host-app flow invoked identify after the merchant's
  /// own sign-in path completed.
  final List<CustomerIdentity> identifyCalls = [];
}

/// Scripting API for a [FakeChataptorClient].
class FakeChataptorClientInject {
  FakeChataptorClientInject._(this._client);

  final FakeChataptorClient _client;

  /// Emits [message] to listeners on `messages` and appends it to
  /// [FakeChataptorClient.currentMessages].
  void message(Message message) {
    _client._messageHistory.add(message);
    _client._messages.add(message);
  }

  /// Transitions the fake into [state] and emits to `connectionState`.
  void connectionState(ConnectionState state) {
    _client._currentConnectionState = state;
    _client._connectionStateController.add(state);
  }

  /// Sets the agent surface. Emits on the (optional) `assignedAgent` stream.
  void assignAgent(AgentInfo agent) => _client._agent.add(agent);

  /// Scripts the outcome of the **next** [FakeChataptorClient.sendMessage]
  /// call. Each call consumes one scripted result, FIFO order.
  void completeNextSend(SendResult result) =>
      _client._scriptedSends.add(result);
}

/// Domain-level fake for [ChataptorClient].
///
/// Designed for merchants writing widget tests of their host app — never
/// exposes transport, HTTP, or serialization concerns. For low-level
/// protocol-layer tests of the SDK itself, reach for `FakeChatTransport`
/// instead.
///
/// The fake does not implement every [ChataptorClient] member — it covers
/// the surface exercised by the drop-in widgets and by typical merchant
/// host-app tests (connect / disconnect / sendMessage / clearSession /
/// identify, plus the corresponding streams). Additional members are
/// added as the real counterparts ship.
class FakeChataptorClient implements ChataptorClient {
  /// Creates a [FakeChataptorClient] in [initialConnectionState] (defaults
  /// to `Disconnected(userRequested)`), optionally with an [initialAgent].
  FakeChataptorClient({
    ConnectionState initialConnectionState = const Disconnected(
      DisconnectReason.userRequested,
    ),
    AgentInfo? initialAgent,
  }) {
    _currentConnectionState = initialConnectionState;
    if (initialAgent != null) _agent.add(initialAgent);
    inject = FakeChataptorClientInject._(this);
  }

  // Plain broadcast — does not replay to late subscribers. current state is
  // tracked separately in [_currentConnectionState].
  final StreamController<ConnectionState> _connectionStateController =
      StreamController<ConnectionState>.broadcast();
  ConnectionState? _currentConnectionState;

  final ValueStream<AgentInfo> _agent = ValueStream<AgentInfo>();
  final List<Message> _messageHistory = [];
  final StreamController<Message> _messages =
      StreamController<Message>.broadcast();
  final StreamController<ChataptorError> _errors =
      StreamController<ChataptorError>.broadcast();
  final List<SendResult> _scriptedSends = [];

  /// Scripted-event injection API.
  late final FakeChataptorClientInject inject;

  /// Observable record of calls.
  final FakeChataptorClientRecorded recorded = FakeChataptorClientRecorded();

  @override
  Stream<ConnectionState> get connectionState =>
      _connectionStateController.stream;

  @override
  ConnectionState? get currentConnectionState => _currentConnectionState;

  @override
  List<Message> get currentMessages =>
      List<Message>.unmodifiable(_messageHistory);

  @override
  Stream<Message> get messages => _messages.stream;

  @override
  Stream<ChataptorError> get errors => _errors.stream;

  @override
  Future<void> connect() async {
    recorded.connectCalls += 1;
    inject.connectionState(const Connected());
  }

  @override
  Future<void> disconnect() async {
    recorded.disconnectCalls += 1;
    inject.connectionState(const Disconnected(DisconnectReason.userRequested));
  }

  @override
  Future<SendResult> sendMessage(
    String text, {
    Map<String, dynamic>? metadata,
  }) async {
    final draft = MessageDraft(body: text, metadata: metadata ?? const {});
    recorded.sentMessages.add(draft);
    if (_scriptedSends.isEmpty) {
      return SendFailure(
        const ValidationError(
          'FakeChataptorClient: no scripted result — call '
          'inject.completeNextSend first',
          fieldErrors: {},
        ),
        draft,
      );
    }
    return _scriptedSends.removeAt(0);
  }

  @override
  Future<void> clearSession() async {
    recorded.clearSessionCalls += 1;
    _messageHistory.clear();
    if (currentConnectionState is! Disconnected) {
      await disconnect();
    }
  }

  @override
  Future<void> identify(CustomerIdentity newIdentity) async {
    recorded.identifyCalls.add(newIdentity);
  }

  @override
  Future<void> dispose() async {
    await _messages.close();
    await _errors.close();
    await _connectionStateController.close();
    await _agent.close();
  }

  // Catch-all fallback for any [ChataptorClient] member not yet stubbed —
  // throws `NoSuchMethodError` at call time so missing coverage is obvious
  // rather than silently no-op. Expand the explicit stubs above as the
  // real surface grows.
  @override
  // ignore: avoid_annotating_with_dynamic
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
