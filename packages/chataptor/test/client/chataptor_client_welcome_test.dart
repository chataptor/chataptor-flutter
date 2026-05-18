import 'package:chataptor/chataptor.dart';
import 'package:chataptor/testing.dart';
import 'package:test/test.dart';

ChataptorConfig _testConfig({String? customerLanguage = 'pl'}) =>
    ChataptorConfig(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      translation: customerLanguage == null
          ? TranslationConfig.disabled()
          : TranslationConfig.auto(customerLanguage: customerLanguage),
    );

Map<String, dynamic> _siteConfigWithWelcome() => {
  'language_variants': [
    {
      'language_code': 'pl',
      'is_default': true,
      'welcome_message': 'Dzień dobry! W czym możemy pomóc?',
      'header_title': 'Pomoc techniczna',
    },
  ],
};

void main() {
  group('ChataptorClient welcome message injection', () {
    test(
      'injects welcome as the first agent message when history is empty',
      () async {
        final transport = FakeChatTransport()
          ..inject.joinPayload('site:abc', {
            'site_config': _siteConfigWithWelcome(),
          })
          ..inject.conversationCreated('site:abc', 'conv1');
        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );

        final emitted = <Message>[];
        client.messages.listen(emitted.add);

        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(client.currentMessages, hasLength(1));
        final welcome = client.currentMessages.first;
        expect(welcome.body, 'Dzień dobry! W czym możemy pomóc?');
        expect(welcome.author, MessageAuthor.agent);
        expect(welcome.id, 'welcome-conv1');
        expect(welcome.type, MessageType.text);
        // Same message was emitted on the broadcast stream so headless UIs
        // that only listen (don't snapshot currentMessages) still see it.
        expect(emitted.map((m) => m.id), contains('welcome-conv1'));
      },
    );

    test('does NOT inject when conversation history is non-empty', () async {
      final transport = FakeChatTransport()
        ..inject.joinPayload('site:abc', {
          'site_config': _siteConfigWithWelcome(),
        })
        ..inject.conversationCreated('site:abc', 'conv1')
        ..inject.joinPayload('conversation:conv1', {
          'messages': [
            {
              'id': 'm1',
              'body': 'Real history message',
              'author': 'agent',
              'timestamp': '2026-05-18T10:00:00Z',
            },
          ],
        });
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Only the real history message — no welcome bubble pushed on top.
      expect(client.currentMessages, hasLength(1));
      expect(client.currentMessages.first.id, 'm1');
    });

    test(
      'does NOT inject when site_config has no welcome for the language',
      () async {
        final transport = FakeChatTransport()
          ..inject.joinPayload('site:abc', {
            'site_config': const {'language_variants': <Object>[]},
          })
          ..inject.conversationCreated('site:abc', 'conv1');
        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );

        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(client.currentMessages, isEmpty);
      },
    );

    test('does NOT inject when backend omits site_config entirely', () async {
      final transport = FakeChatTransport()
        ..inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(client.currentMessages, isEmpty);
    });

    test('welcome id is deterministic per conversation — '
        'no duplicate on reconnect', () async {
      final transport = FakeChatTransport()
        ..inject.joinPayload('site:abc', {
          'site_config': _siteConfigWithWelcome(),
        })
        ..inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(client.currentMessages, hasLength(1));

      // Simulate reconnect: same conversation id, same site config.
      await client.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      transport.inject.conversationCreated('site:abc', 'conv1');
      transport.inject.joinPayload('site:abc', {
        'site_config': _siteConfigWithWelcome(),
      });
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // History buffer preserved through disconnect; welcome is not
      // re-injected because the buffer is non-empty AND the id is in
      // seenMessageIds.
      expect(client.currentMessages, hasLength(1));
      expect(client.currentMessages.first.id, 'welcome-conv1');
    });

    test(
      'falls back to site-level welcome_message when variant has none',
      () async {
        final transport = FakeChatTransport()
          ..inject.joinPayload('site:abc', {
            'site_config': const {
              'welcome_message': 'Site-level greeting',
              'language_variants': [
                {'language_code': 'pl', 'is_default': true},
              ],
            },
          })
          ..inject.conversationCreated('site:abc', 'conv1');
        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );

        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(client.currentMessages, hasLength(1));
        expect(client.currentMessages.first.body, 'Site-level greeting');
      },
    );
  });
}
