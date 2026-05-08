import 'package:chataptor/chataptor.dart';
import 'package:chataptor/testing.dart';
import 'package:test/test.dart';

ChataptorConfig _testConfig() => ChataptorConfig(
  siteId: 'abc',
  widgetKey: 'pk_x',
  apiUrl: Uri.parse('http://localhost:4000'),
);

void main() {
  group('ChataptorClient lifecycle', () {
    test('starts in Disconnected state', () {
      final transport = FakeChatTransport();
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      expect(
        client.currentConnectionState,
        const Disconnected(DisconnectReason.userRequested),
      );
    });

    test('connect transitions Connecting → Connected', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      final states = <ConnectionState>[];
      client.connectionState.listen(states.add);

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states.any((s) => s is Connecting), isTrue);
      expect(states.last, isA<Connected>());
    });

    test(
      'connect joins site:<siteId> then conversation:<id> channels',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );
        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(transport.recorded.joinedChannels, [
          'site:abc',
          'conversation:conv1',
        ]);
      },
    );

    test(
      'connect stays Disconnected when conversation:create times out',
      () async {
        final transport = FakeChatTransport();
        // No conversationCreated → push returns PushTimeout.
        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );
        final states = <ConnectionState>[];
        client.connectionState.listen(states.add);

        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(states.last, isA<Disconnected>());
      },
    );

    test('disconnect transitions to Disconnected', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await client.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(client.currentConnectionState, isA<Disconnected>());
    });

    test('throws ChataptorStateError when sending before connect', () async {
      final transport = FakeChatTransport();
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      expect(
        () => client.sendMessage('hi'),
        throwsA(isA<ChataptorStateError>()),
      );
    });
  });
}
