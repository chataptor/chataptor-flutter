import 'package:chataptor/src/auth/customer_identity.dart';
import 'package:chataptor/src/config/chataptor_config.dart';
import 'package:chataptor/src/config/feature_toggles.dart';
import 'package:chataptor/src/config/push_config.dart';
import 'package:chataptor/src/config/transport_config.dart';
import 'package:chataptor/src/hooks/chataptor_hooks.dart';
import 'package:test/test.dart';

void main() {
  test('ChataptorConfig requires siteId and widgetKey', () {
    final config = ChataptorConfig(siteId: 'abc', widgetKey: 'pk_x');
    expect(config.siteId, 'abc');
    expect(config.widgetKey, 'pk_x');
  });

  test('ChataptorConfig sensible defaults', () {
    final config = ChataptorConfig(siteId: 'abc', widgetKey: 'pk_x');
    expect(config.apiUrl, Uri.parse('https://chataptor.com'));
    expect(config.customer, const CustomerIdentity.anonymous());
    expect(config.transport, const TransportClientConfig());
    expect(config.translation.enabled, isTrue);
    expect(config.features, const FeatureToggles());
    expect(config.push.mode, PushMode.disabled);
    expect(config.hooks, const ChataptorHooks());
    expect(config.sessionIdleTimeout, isNull);
  });

  test('ChataptorConfig accepts sessionIdleTimeout', () {
    final config = ChataptorConfig(
      siteId: 'abc',
      widgetKey: 'pk_x',
      sessionIdleTimeout: const Duration(hours: 24),
    );
    expect(config.sessionIdleTimeout, const Duration(hours: 24));
  });

  test('ChataptorConfig throws on empty siteId', () {
    expect(
      () => ChataptorConfig(siteId: '', widgetKey: 'pk_x'),
      throwsArgumentError,
    );
  });

  test('ChataptorConfig throws on empty widgetKey', () {
    expect(
      () => ChataptorConfig(siteId: 'abc', widgetKey: ''),
      throwsArgumentError,
    );
  });

  test('copyWith', () {
    final config = ChataptorConfig(siteId: 'abc', widgetKey: 'pk_x');
    final updated = config.copyWith(
      customer: const CustomerIdentity(email: 'a@b.c'),
    );
    expect(updated.customer.email, 'a@b.c');
    expect(updated.siteId, 'abc');
  });
}
