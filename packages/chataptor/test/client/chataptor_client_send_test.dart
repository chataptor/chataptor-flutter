import 'package:chataptor/chataptor.dart';
import 'package:chataptor/testing.dart';
import 'package:test/test.dart';

const _convId = 'conv1';
const _convTopic = 'conversation:$_convId';

ChataptorConfig _baseConfig({ChataptorHooks? hooks}) => ChataptorConfig(
  siteId: 'abc',
  widgetKey: 'pk_x',
  apiUrl: Uri.parse('http://localhost:4000'),
  hooks: hooks ?? const ChataptorHooks(),
);

Future<({ChataptorClient client, FakeChatTransport transport})> _connected({
  ChataptorHooks? hooks,
}) async {
  final transport = FakeChatTransport();
  transport.inject.conversationCreated('site:abc', _convId);
  final client = ChataptorClient.internal(
    config: _baseConfig(hooks: hooks),
    transport: transport,
  );
  await client.connect();
  await Future<void>.delayed(const Duration(milliseconds: 50));
  return (client: client, transport: transport);
}

void main() {
  group('sendMessage', () {
    test('returns SendSuccess when server replies PushOk', () async {
      final (:client, :transport) = await _connected();
      transport.inject.replyFor(
        topic: _convTopic,
        event: 'message:send',
        result: const PushOk({'msg_id': 1}),
      );

      final result = await client.sendMessage('hi');

      expect(result, isA<SendSuccess>());
      final draft = (result as SendSuccess).draft;
      expect(draft.body, 'hi');

      // conversation:create + message:send
      expect(transport.recorded.pushes, hasLength(2));
      final sent = transport.recorded.pushes.last;
      expect(sent.topic, _convTopic);
      expect(sent.event, 'message:send');
      expect(sent.payload['text'], 'hi');
    });

    test('returns SendFailure when server replies PushServerError', () async {
      final (:client, :transport) = await _connected();
      transport.inject.replyFor(
        topic: _convTopic,
        event: 'message:send',
        result: const PushServerError(reason: 'boom', response: {}),
      );

      final result = await client.sendMessage('hi');

      expect(result, isA<SendFailure>());
      expect((result as SendFailure).error, isA<ServerError>());
      expect(result.pending.body, 'hi');
    });

    test('returns SendFailure with NetworkError on PushTimeout', () async {
      final (:client, :transport) = await _connected();
      // No reply injected — FakeChatTransport returns PushTimeout.
      final result = await client.sendMessage('hi');

      expect(result, isA<SendFailure>());
      expect((result as SendFailure).error, isA<NetworkError>());
    });

    test('beforeSend can modify the outgoing draft', () async {
      final (:client, :transport) = await _connected(
        hooks: ChataptorHooks(
          beforeSend: (d) async =>
              d.copyWith(body: '${d.body}!', metadata: {'source': 'test'}),
        ),
      );
      transport.inject.replyFor(
        topic: _convTopic,
        event: 'message:send',
        result: const PushOk({}),
      );

      final result = await client.sendMessage('hi');

      expect(result, isA<SendSuccess>());
      final sent = transport.recorded.pushes.last;
      expect(sent.payload['text'], 'hi!');
      expect(sent.payload['metadata'], {'source': 'test'});
    });

    test('beforeSend returning null cancels send', () async {
      final (:client, :transport) = await _connected(
        hooks: ChataptorHooks(beforeSend: (_) async => null),
      );

      final result = await client.sendMessage('hi');

      expect(result, isA<SendFailure>());
      expect((result as SendFailure).error, isA<ValidationError>());
      // Only conversation:create push, no message:send.
      expect(
        transport.recorded.pushes.any((p) => p.event == 'message:send'),
        isFalse,
      );
    });
  });
}
