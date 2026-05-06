import 'package:chataptor/src/client/connection_state.dart';
import 'package:chataptor/src/errors/chataptor_error.dart';
import 'package:chataptor/src/hooks/chataptor_hooks.dart';
import 'package:chataptor/src/models/agent_info.dart';
import 'package:chataptor/src/models/enums.dart';
import 'package:chataptor/src/models/message.dart';
import 'package:chataptor/src/models/message_draft.dart';
import 'package:test/test.dart';

Message _sampleMessage() => Message(
  id: 'm1',
  conversationId: 'c1',
  body: 'hi',
  author: MessageAuthor.agent,
  timestamp: DateTime.utc(2026),
  type: MessageType.text,
  deliveryChannel: DeliveryChannel.websocket,
  status: MessageStatus.sent,
);

void main() {
  test('default ChataptorHooks has no callbacks', () {
    const hooks = ChataptorHooks();
    expect(hooks.onMessageReceived, isNull);
    expect(hooks.beforeSend, isNull);
  });

  test('event callbacks are invoked via dispatch helpers', () {
    final received = <Message>[];
    final hooks = ChataptorHooks(onMessageReceived: received.add);
    hooks.onMessageReceived?.call(_sampleMessage());
    expect(received, hasLength(1));
  });

  test('beforeSend can cancel by returning null', () async {
    final hooks = ChataptorHooks(beforeSend: (_) async => null);
    final result = await hooks.beforeSend!(const MessageDraft(body: 'x'));
    expect(result, isNull);
  });

  test('beforeSend can transform the draft', () async {
    final hooks = ChataptorHooks(
      beforeSend: (d) async => d.copyWith(body: '${d.body}!'),
    );
    final result = await hooks.beforeSend!(const MessageDraft(body: 'hi'));
    expect(result?.body, 'hi!');
  });

  test('onConnectionStateChanged fires with new state', () {
    ConnectionState? last;
    final hooks = ChataptorHooks(onConnectionStateChanged: (s) => last = s);
    hooks.onConnectionStateChanged?.call(const Connected());
    expect(last, isA<Connected>());
  });

  test('onAgentAssigned fires with agent info', () {
    AgentInfo? lastAgent;
    final hooks = ChataptorHooks(onAgentAssigned: (a) => lastAgent = a);
    hooks.onAgentAssigned?.call(const AgentInfo(id: 1, name: 'A'));
    expect(lastAgent?.name, 'A');
  });

  test('onError receives ChataptorError', () {
    ChataptorError? lastErr;
    final hooks = ChataptorHooks(onError: (e) => lastErr = e);
    hooks.onError?.call(const NetworkError('x'));
    expect(lastErr, isA<NetworkError>());
  });
}
