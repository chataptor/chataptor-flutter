import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supply credentials via --dart-define at run time (never hard-code them):
  //   flutter run \
  //     --dart-define=CHATAPTOR_SITE_ID=<your-site-id> \
  //     --dart-define=CHATAPTOR_WIDGET_KEY=<your-widget-key>
  //
  // See examples/quickstart/run_local.ps1.example for a ready-made script.
  const siteId = String.fromEnvironment(
    'CHATAPTOR_SITE_ID',
    defaultValue: 'YOUR_SITE_ID',
  );
  const widgetKey = String.fromEnvironment(
    'CHATAPTOR_WIDGET_KEY',
    defaultValue: 'YOUR_WIDGET_KEY',
  );
  await Chataptor.init(
    config: ChataptorConfig(
      siteId: siteId,
      widgetKey: widgetKey,
      // apiUrl defaults to https://chataptor.com
      logger: _DebugLogger(),
    ),
  );

  runApp(const QuickstartApp());
}

class _DebugLogger implements ChataptorLogger {
  @override
  void log(
    ChataptorLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final tag = level.name.toUpperCase().padRight(5);
    debugPrint('[Chataptor/$tag] $message${error != null ? ' — $error' : ''}');
    if (stackTrace != null && level == ChataptorLogLevel.error) {
      debugPrint(stackTrace.toString());
    }
  }
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
      appBar: AppBar(title: const Text('Chataptor Quickstart')),
      body: Center(
        child: FilledButton.icon(
          icon: const Icon(Icons.support_agent),
          label: const Text('Open chat'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChataptorChatScreen()),
            );
          },
        ),
      ),
    );
  }
}
