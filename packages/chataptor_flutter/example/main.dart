// Minimal drop-in integration of the Chataptor Flutter SDK.
//
// For a richer multi-demo hub (default / themed / branded / headless),
// see `examples/quickstart/` at the repository root.

import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Chataptor.init(
    siteId: const String.fromEnvironment(
      'CHATAPTOR_SITE_ID',
      defaultValue: 'YOUR_SITE_ID',
    ),
    widgetKey: const String.fromEnvironment(
      'CHATAPTOR_WIDGET_KEY',
      defaultValue: 'YOUR_WIDGET_KEY',
    ),
  );

  runApp(const _ExampleApp());
}

class _ExampleApp extends StatelessWidget {
  const _ExampleApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chataptor Example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      localizationsDelegates: const [ChataptorLocalizations.delegate],
      supportedLocales: ChataptorLocalizations.supportedLocales,
      home: const _Home(),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chataptor Example')),
      body: Center(
        child: FilledButton.icon(
          icon: const Icon(Icons.support_agent),
          label: const Text('Open chat'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ChataptorChatScreen(),
            ),
          ),
        ),
      ),
    );
  }
}
