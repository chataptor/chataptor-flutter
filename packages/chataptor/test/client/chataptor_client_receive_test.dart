import 'package:chataptor/chataptor.dart';
import 'package:chataptor/testing.dart';
import 'package:test/test.dart';

Future<({ChataptorClient client, FakeChatTransport transport})> _connected(
  ChataptorConfig config,
) async {
  final transport = FakeChatTransport();
  transport.inject.conversationCreated('site:abc', 'conv1');
  final client = ChataptorClient.internal(config: config, transport: transport);
  await client.connect();
  await Future<void>.delayed(const Duration(milliseconds: 50));
  return (client: client, transport: transport);
}

void main() {
  test('messages stream emits when transport pushes a message event', () async {
    final (:client, :transport) = await _connected(
      ChataptorConfig(
        siteId: 'abc',
        widgetKey: 'pk_x',
        apiUrl: Uri.parse('http://localhost:4000'),
      ),
    );

    final received = <Message>[];
    client.messages.listen(received.add);

    transport.inject.event(
      const MessageReceived(
        topic: 'conversation:conv1',
        event: 'message:received',
        payload: {
          'message': {
            'msg_id': 1,
            'conv_id': 7,
            'body_src': 'hi',
            'author': 'agent',
            'inserted_at': '2026-04-22T12:00:00Z',
            'delivery_channel': 'websocket',
          },
        },
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(received, hasLength(1));
    expect(received.first.body, 'hi');
    expect(received.first.author, MessageAuthor.agent);
  });

  test('beforeReceive interceptor can drop messages', () async {
    final (:client, :transport) = await _connected(
      ChataptorConfig(
        siteId: 'abc',
        widgetKey: 'pk_x',
        apiUrl: Uri.parse('http://localhost:4000'),
        hooks: ChataptorHooks(beforeReceive: (_) async => null),
      ),
    );

    final received = <Message>[];
    client.messages.listen(received.add);

    transport.inject.event(
      const MessageReceived(
        topic: 'conversation:conv1',
        event: 'message:received',
        payload: {
          'message': {
            'msg_id': 1,
            'conv_id': 7,
            'body_src': 'dropped',
            'author': 'agent',
            'inserted_at': '2026-04-22T12:00:00Z',
            'delivery_channel': 'websocket',
          },
        },
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(received, isEmpty);
  });
}
