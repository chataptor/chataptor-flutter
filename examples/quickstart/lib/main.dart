import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';

import 'headless_demo.dart';

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
      translation: TranslationConfig.auto(customerLanguage: 'pl'),
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

/// Hub app showcasing every supported integration mode of the SDK in one
/// runnable example.
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
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const _SectionHeader('Drop-in widget'),
          _DemoTile(
            icon: Icons.support_agent,
            title: 'Default',
            subtitle: 'ChataptorChatScreen() — Material theme, default copy',
            onTap: () => _push(context, const ChataptorChatScreen()),
          ),
          _DemoTile(
            icon: Icons.palette_outlined,
            title: 'Matched to app theme',
            subtitle:
                'theme: ChataptorTheme.matching(context) — pulls colours from MaterialApp',
            onTap: () => _push(
              context,
              ChataptorChatScreen(
                title: 'Help center',
                theme: ChataptorTheme.matching(context),
              ),
            ),
          ),
          _DemoTile(
            icon: Icons.brush_outlined,
            title: 'Custom brand + white-label',
            subtitle:
                'custom ChataptorTheme.light().copyWith(...) + showPoweredBy: false',
            onTap: () => _push(
              context,
              ChataptorChatScreen(
                title: 'Pomoc techniczna',
                showPoweredBy: false,
                theme: ChataptorTheme.light().copyWith(
                  primaryColor: const Color(0xFF0F766E),
                  onPrimaryColor: Colors.white,
                  customerBubbleColor: const Color(0xFFCCFBF1),
                  customerBubbleTextColor: const Color(0xFF134E4A),
                  agentBubbleColor: const Color(0xFFF1F5F9),
                  agentBubbleTextColor: const Color(0xFF0F172A),
                  bubbleRadius: const BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ),
          const Divider(height: 32),
          const _SectionHeader('Headless / custom UI'),
          _DemoTile(
            icon: Icons.code,
            title: 'Build your own UI',
            subtitle:
                'Drives Chataptor.instance directly — zero Chataptor widgets',
            onTap: () => _push(context, const HeadlessChatScreen()),
          ),
          const Divider(height: 32),
          const _SectionHeader('Session'),
          _DemoTile(
            icon: Icons.delete_sweep_outlined,
            title: 'Clear session',
            subtitle: 'Drops the guest ID — next open starts a fresh thread',
            onTap: () async {
              await Chataptor.instance.clearSession();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session cleared — next chat opens fresh'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
