import 'package:chataptor/chataptor.dart';
import 'package:chataptor/testing.dart';
import 'package:test/test.dart';

Message _agentMsg(String body) => Message(
  id: 'm-$body',
  conversationId: 'c1',
  body: body,
  author: MessageAuthor.agent,
  timestamp: DateTime.utc(2026, 4, 22, 12),
  type: MessageType.text,
  deliveryChannel: DeliveryChannel.websocket,
  status: MessageStatus.delivered,
);

void main() {
  group('FakeChataptorClient', () {
    test('exposes initial connection state', () {
      final fake = FakeChataptorClient(
        initialConnectionState: const Connected(),
      );
      expect(fake.currentConnectionState, const Connected());
    });

    test('inject.message emits on messages stream', () async {
      final fake = FakeChataptorClient();
      final received = <Message>[];
      fake.messages.listen(received.add);

      fake.inject.message(_agentMsg('hi'));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.first.body, 'hi');
    });

    test('inject.connectionState transitions and emits on stream', () async {
      final fake = FakeChataptorClient();
      final states = <ConnectionState>[];
      fake.connectionState.listen(states.add);

      fake.inject.connectionState(const Connecting());
      fake.inject.connectionState(const Connected());
      await Future<void>.delayed(Duration.zero);

      expect(states, [const Connecting(), const Connected()]);
      expect(fake.currentConnectionState, const Connected());
    });

    test(
      'sendMessage records the call and returns the scripted result',
      () async {
        final fake = FakeChataptorClient(
          initialConnectionState: const Connected(),
        );
        const draft = MessageDraft(body: 'hi');
        fake.inject.completeNextSend(const SendSuccess(draft));

        final result = await fake.sendMessage('hi');

        expect(result, isA<SendSuccess>());
        expect(fake.recorded.sentMessages, hasLength(1));
        expect(fake.recorded.sentMessages.first.body, 'hi');
      },
    );

    test(
      'sendMessage returns ValidationError by default (nothing scripted)',
      () async {
        final fake = FakeChataptorClient(
          initialConnectionState: const Connected(),
        );
        final result = await fake.sendMessage('hi');
        expect(result, isA<SendFailure>());
        expect((result as SendFailure).error, isA<ValidationError>());
      },
    );

    test('connect/disconnect are no-ops that flip the state', () async {
      final fake = FakeChataptorClient();
      await fake.connect();
      expect(fake.currentConnectionState, const Connected());
      await fake.disconnect();
      expect(fake.currentConnectionState, isA<Disconnected>());
    });

    test(
      'clearSession() records the call and transitions to Disconnected',
      () async {
        final fake = FakeChataptorClient();
        await fake.connect();
        expect(fake.currentConnectionState, const Connected());

        await fake.clearSession();

        expect(fake.currentConnectionState, isA<Disconnected>());
        expect(fake.recorded.clearSessionCalls, 1);
      },
    );
  });
}
