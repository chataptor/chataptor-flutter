// Minimal headless integration of the Chataptor core SDK.
//
// Run with real credentials:
//   dart run --define=CHATAPTOR_SITE_ID=... --define=CHATAPTOR_WIDGET_KEY=...

// ignore_for_file: avoid_print

import 'package:chataptor/chataptor.dart';

Future<void> main() async {
  const siteId = String.fromEnvironment(
    'CHATAPTOR_SITE_ID',
    defaultValue: 'YOUR_SITE_ID',
  );
  const widgetKey = String.fromEnvironment(
    'CHATAPTOR_WIDGET_KEY',
    defaultValue: 'YOUR_WIDGET_KEY',
  );

  final client = ChataptorClient(
    config: ChataptorConfig(
      siteId: siteId,
      widgetKey: widgetKey,
      translation: TranslationConfig.auto(customerLanguage: 'pl'),
    ),
  );

  // React to connection state updates.
  client.connectionState.listen((state) {
    print('Connection state → ${state.runtimeType}');
  });

  // React to incoming messages — including the merchant-configured
  // welcome message that the SDK injects as the first agent bubble.
  client.messages.listen((m) {
    print('${m.author.name}: ${m.body}');
  });

  // React to agent presence updates broadcast on the site channel.
  client.onlineAgentsStream.listen((agents) {
    print('Online agents: ${agents.map((a) => a.name).toList()}');
  });

  await client.connect();

  final result = await client.sendMessage('Hello from the Dart example!');
  if (result is SendFailure) {
    print('Send failed: ${result.error}');
  }

  // Allow events to settle, then tear down.
  await Future<void>.delayed(const Duration(seconds: 2));
  await client.disconnect();
  await client.dispose();
}
