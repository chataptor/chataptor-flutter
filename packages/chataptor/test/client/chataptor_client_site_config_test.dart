import 'package:chataptor/chataptor.dart';
import 'package:chataptor/testing.dart';
import 'package:test/test.dart';

ChataptorConfig _testConfig() => ChataptorConfig(
  siteId: 'abc',
  widgetKey: 'pk_x',
  apiUrl: Uri.parse('http://localhost:4000'),
  translation: TranslationConfig.auto(customerLanguage: 'pl'),
);

Map<String, dynamic> _sampleSiteConfig() => {
  'widget_language': 'en',
  'welcome_message': 'site-level fallback',
  'offline_mode': 'auto',
  'working_hours_enabled': false,
  'auto_translations_enabled': true,
  'language_variants': [
    {
      'language_code': 'en',
      'is_default': true,
      'welcome_message': 'Hi! How can we help?',
      'header_title': 'Customer Support',
    },
    {
      'language_code': 'pl',
      'is_default': false,
      'welcome_message': 'Dzień dobry! W czym możemy pomóc?',
      'header_title': 'Pomoc techniczna',
    },
  ],
};

void main() {
  group('ChataptorClient.currentSiteConfig', () {
    test('is null before connect()', () {
      final transport = FakeChatTransport();
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      expect(client.currentSiteConfig, isNull);
    });

    test('is populated after a successful connect with site_config', () async {
      final transport = FakeChatTransport();
      transport.inject.joinPayload('site:abc', {
        'site_config': _sampleSiteConfig(),
      });
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(client.currentSiteConfig, isNotNull);
      expect(client.currentSiteConfig!.widgetLanguage, 'en');
      expect(
        client.currentSiteConfig!.siteWelcomeMessage,
        'site-level fallback',
      );
      expect(client.currentSiteConfig!.languageVariants, hasLength(2));
      expect(
        client.currentSiteConfig!.activeHeaderTitle('pl'),
        'Pomoc techniczna',
      );
      expect(
        client.currentSiteConfig!.activeWelcomeMessage('pl'),
        'Dzień dobry! W czym możemy pomóc?',
      );
    });

    test('tolerates a site:X join payload without site_config', () async {
      final transport = FakeChatTransport();
      // No joinPayload registered → join returns {} → no site_config to parse.
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(client.currentSiteConfig, isNull);
    });

    test('siteConfigStream emits the parsed config', () async {
      final transport = FakeChatTransport();
      transport.inject.joinPayload('site:abc', {
        'site_config': _sampleSiteConfig(),
      });
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );

      final received = <SiteConfig>[];
      client.siteConfigStream.listen(received.add);

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(received, hasLength(greaterThanOrEqualTo(1)));
      expect(received.last.activeHeaderTitle('pl'), 'Pomoc techniczna');
    });

    test('survives disconnect (matches messageHistory policy)', () async {
      final transport = FakeChatTransport();
      transport.inject.joinPayload('site:abc', {
        'site_config': _sampleSiteConfig(),
      });
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(client.currentSiteConfig, isNotNull);

      await client.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        client.currentSiteConfig,
        isNotNull,
        reason: 'header config should not flash on reconnect',
      );
    });

    test('clearSession resets currentSiteConfig to null', () async {
      final transport = FakeChatTransport();
      transport.inject.joinPayload('site:abc', {
        'site_config': _sampleSiteConfig(),
      });
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(client.currentSiteConfig, isNotNull);

      await client.clearSession();
      expect(client.currentSiteConfig, isNull);
    });
  });
}
