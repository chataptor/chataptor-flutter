import 'package:chataptor/src/transport/fake_chat_transport.dart';
import 'package:chataptor/src/transport/transport_types.dart';
import 'package:test/test.dart';

void main() {
  group('FakeChatTransport', () {
    test('connect emits TransportConnecting then TransportConnected', () async {
      final transport = FakeChatTransport();
      final states = <TransportConnectionState>[];
      transport.connectionState.listen(states.add);

      await transport.connect(_stubConfig());

      // Allow stream events to flush.
      await Future<void>.delayed(Duration.zero);
      expect(states.map((s) => s.runtimeType), [
        TransportConnecting,
        TransportConnected,
      ]);
    });

    test('disconnect emits TransportDisconnected', () async {
      final transport = FakeChatTransport();
      await transport.connect(_stubConfig());
      final states = <TransportConnectionState>[];
      transport.connectionState.listen(states.add);

      await transport.disconnect();

      await Future<void>.delayed(Duration.zero);
      expect(states.last, isA<TransportDisconnected>());
    });

    test('inject.event adds to events stream', () async {
      final transport = FakeChatTransport();
      await transport.connect(_stubConfig());
      final received = <TransportEvent>[];
      transport.events.listen(received.add);

      transport.inject.event(
        const MessageReceived(topic: 't', event: 'e', payload: {'body': 'hi'}),
      );

      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(1));
      expect(received.first, isA<MessageReceived>());
    });

    test(
      'push returns injected PushResult for matching (topic, event)',
      () async {
        final transport = FakeChatTransport();
        await transport.connect(_stubConfig());
        await transport.joinChannel('site:abc', {});

        transport.inject.replyFor(
          topic: 'site:abc',
          event: 'message:send',
          result: const PushOk({'msg_id': 1}),
        );

        final result = await transport.push('site:abc', 'message:send', {
          'body': 'hi',
        });
        expect(result, isA<PushOk>());
        expect((result as PushOk).response['msg_id'], 1);
      },
    );

    test('push returns PushTimeout if no reply is injected', () async {
      final transport = FakeChatTransport();
      await transport.connect(_stubConfig());
      await transport.joinChannel('site:abc', {});
      final result = await transport.push('site:abc', 'unknown:event', {});
      expect(result, isA<PushTimeout>());
    });

    test('recorded.pushes captures every push call', () async {
      final transport = FakeChatTransport();
      await transport.connect(_stubConfig());
      await transport.joinChannel('site:abc', {});
      transport.inject.replyFor(
        topic: 'site:abc',
        event: 'message:send',
        result: const PushOk({}),
      );

      await transport.push('site:abc', 'message:send', {'body': 'hi'});
      await transport.push('site:abc', 'message:send', {'body': 'two'});

      expect(transport.recorded.pushes, hasLength(2));
      expect(transport.recorded.pushes[0].payload['body'], 'hi');
      expect(transport.recorded.pushes[1].payload['body'], 'two');
    });
  });
}

TransportConfig _stubConfig() => TransportConfig(
  url: Uri.parse('wss://example.com/socket'),
  params: const {},
  heartbeatInterval: const Duration(seconds: 30),
  reconnectionDelays: const [Duration(seconds: 1)],
);
