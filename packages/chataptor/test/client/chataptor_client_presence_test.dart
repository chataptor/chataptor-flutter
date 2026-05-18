import 'package:chataptor/chataptor.dart';
import 'package:chataptor/testing.dart';
import 'package:test/test.dart';

ChataptorConfig _testConfig() => ChataptorConfig(
  siteId: 'abc',
  widgetKey: 'pk_x',
  apiUrl: Uri.parse('http://localhost:4000'),
);

Map<String, dynamic> _twoAgentsPayload() => {
  'type': 'agent_available',
  'message': 'An agent is now available',
  'agents': [
    {
      'id': 1,
      'name': 'Anna',
      'avatar_url': 'https://cdn.example.com/anna.jpg',
      'initials': {'letters': 'AN', 'color': '#7C3AED'},
    },
    {
      'id': 2,
      'name': 'Viktor',
      'initials': {'letters': 'VI', 'color': '#0F766E'},
    },
  ],
};

Future<ChataptorClient> _connectedClient(FakeChatTransport transport) async {
  transport.inject.conversationCreated('site:abc', 'conv1');
  final client = ChataptorClient.internal(
    config: _testConfig(),
    transport: transport,
  );
  await client.connect();
  await Future<void>.delayed(const Duration(milliseconds: 50));
  return client;
}

void main() {
  group('ChataptorClient.currentOnlineAgents', () {
    test('is empty before connect()', () {
      final transport = FakeChatTransport();
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      expect(client.currentOnlineAgents, isEmpty);
    });

    test('populates from an agent:available transport event', () async {
      final transport = FakeChatTransport();
      final client = await _connectedClient(transport);

      transport.inject.event(
        MessageReceived(
          topic: 'site:abc',
          event: 'agent:available',
          payload: _twoAgentsPayload(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(client.currentOnlineAgents, hasLength(2));
      expect(client.currentOnlineAgents[0].name, 'Anna');
      expect(client.currentOnlineAgents[1].name, 'Viktor');
      expect(client.currentOnlineAgents[1].initials?.letters, 'VI');
    });

    test('clears on an agents:offline transport event', () async {
      final transport = FakeChatTransport();
      final client = await _connectedClient(transport);

      transport.inject.event(
        MessageReceived(
          topic: 'site:abc',
          event: 'agent:available',
          payload: _twoAgentsPayload(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(client.currentOnlineAgents, isNotEmpty);

      transport.inject.event(
        const MessageReceived(
          topic: 'site:abc',
          event: 'agents:offline',
          payload: {'agents': <Object>[]},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(client.currentOnlineAgents, isEmpty);
    });

    test('onlineAgentsStream emits successive snapshots', () async {
      final transport = FakeChatTransport();
      final client = await _connectedClient(transport);

      final emissions = <List<AgentInfo>>[];
      client.onlineAgentsStream.listen(emissions.add);

      transport.inject.event(
        MessageReceived(
          topic: 'site:abc',
          event: 'agent:available',
          payload: _twoAgentsPayload(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      transport.inject.event(
        const MessageReceived(
          topic: 'site:abc',
          event: 'agents:offline',
          payload: {'agents': <Object>[]},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emissions.map((e) => e.length).toList(), [2, 0]);
    });

    test('survives disconnect — anti-flash on reconnect (matches '
        'messageHistory policy)', () async {
      final transport = FakeChatTransport();
      final client = await _connectedClient(transport);

      transport.inject.event(
        MessageReceived(
          topic: 'site:abc',
          event: 'agent:available',
          payload: _twoAgentsPayload(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await client.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(client.currentOnlineAgents, hasLength(2));
    });

    test('clearSession resets currentOnlineAgents to empty', () async {
      final transport = FakeChatTransport();
      final client = await _connectedClient(transport);

      transport.inject.event(
        MessageReceived(
          topic: 'site:abc',
          event: 'agent:available',
          payload: _twoAgentsPayload(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(client.currentOnlineAgents, isNotEmpty);

      await client.clearSession();
      expect(client.currentOnlineAgents, isEmpty);
    });

    test('newer agent:available replaces the previous snapshot', () async {
      final transport = FakeChatTransport();
      final client = await _connectedClient(transport);

      transport.inject.event(
        MessageReceived(
          topic: 'site:abc',
          event: 'agent:available',
          payload: _twoAgentsPayload(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      transport.inject.event(
        const MessageReceived(
          topic: 'site:abc',
          event: 'agent:available',
          payload: {
            'agents': [
              {'id': 9, 'name': 'Maria'},
            ],
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(client.currentOnlineAgents, hasLength(1));
      expect(client.currentOnlineAgents.single.name, 'Maria');
    });
  });
}
