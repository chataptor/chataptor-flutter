import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Replace with your real site credentials from the Chataptor admin console.
  await Chataptor.init(
    siteId: 'demo-site',
    widgetKey: 'pk_demo_key',
  );

  runApp(const QuickstartApp());
}

/// Minimal host app that pushes [ChataptorChatScreen] from a button tap.
class QuickstartApp extends StatelessWidget {
  /// Creates the demo app.
  const QuickstartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chataptor Quickstart',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        ChataptorLocalizations.delegate,
      ],
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
      appBar: AppBar(title: const Text('Chataptor Quickstart')),
      body: Center(
        child: FilledButton.icon(
          icon: const Icon(Icons.support_agent),
          label: const Text('Open chat'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ChataptorChatScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
