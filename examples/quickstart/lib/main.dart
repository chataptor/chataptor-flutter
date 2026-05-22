import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';

import 'headless_demo.dart';

// Supply credentials via --dart-define at run time (never hard-code them):
//   flutter run \
//     --dart-define=CHATAPTOR_SITE_ID=<your-site-id> \
//     --dart-define=CHATAPTOR_WIDGET_KEY=<your-widget-key>
//
// See examples/quickstart/run_local.ps1.example for a ready-made script.
const _siteId = String.fromEnvironment(
  'CHATAPTOR_SITE_ID',
  defaultValue: 'YOUR_SITE_ID',
);
const _widgetKey = String.fromEnvironment(
  'CHATAPTOR_WIDGET_KEY',
  defaultValue: 'YOUR_WIDGET_KEY',
);

ChataptorConfig _buildConfig({Duration? sessionIdleTimeout}) => ChataptorConfig(
  siteId: _siteId,
  widgetKey: _widgetKey,
  // apiUrl defaults to https://chataptor.com
  translation: TranslationConfig.auto(customerLanguage: 'pl'),
  sessionIdleTimeout: sessionIdleTimeout,
  logger: _DebugLogger(),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Chataptor.init(config: _buildConfig());
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
          const _SectionHeader('v0.2.0 features'),
          _DemoTile(
            icon: Icons.vertical_align_bottom,
            title: 'Bottom sheet (showAppBar: false)',
            subtitle:
                'Embeds ChataptorChatScreen inside a DraggableScrollableSheet '
                'with a drag handle — host owns the chrome',
            onTap: () => _openAsBottomSheet(context),
          ),
          _DemoTile(
            icon: Icons.person_pin_outlined,
            title: 'Identify (preserve guest thread)',
            subtitle:
                'identify(qa-<epoch>) — keeps the same guestId, so the '
                'anonymous thread the customer was in follows them into '
                'the identified session (intended sign-in continuity)',
            onTap: () async {
              final epoch = DateTime.now().millisecondsSinceEpoch;
              final identity = CustomerIdentity(
                id: 'qa-$epoch',
                email: 'qa+$epoch@example.com',
                name: 'QA $epoch',
              );
              await Chataptor.instance.identify(identity);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Identified as ${identity.id} — existing thread (if any) '
                    'is now linked to this customer',
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
            },
          ),
          _DemoTile(
            icon: Icons.fiber_new_outlined,
            title: 'Clear session + identify as new user',
            subtitle:
                'clearSession() → identify(qa-<epoch>) — drops the guestId '
                'first so the next chat starts a brand new thread under '
                'a brand new customer (no continuity)',
            onTap: () async {
              await Chataptor.instance.clearSession();
              final epoch = DateTime.now().millisecondsSinceEpoch;
              final identity = CustomerIdentity(
                id: 'qa-$epoch',
                email: 'qa+$epoch@example.com',
                name: 'QA $epoch',
              );
              await Chataptor.instance.identify(identity);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Fresh start as ${identity.id} — next chat opens an '
                    'empty thread for this customer',
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
            },
          ),
          _DemoTile(
            icon: Icons.person_off_outlined,
            title: 'Re-anonymize',
            subtitle:
                'Chataptor.instance.identify(CustomerIdentity.anonymous()) — '
                'guestId is preserved (continuity in both directions)',
            onTap: () async {
              await Chataptor.instance.identify(
                const CustomerIdentity.anonymous(),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Switched back to anonymous')),
              );
            },
          ),
          _DemoTile(
            icon: Icons.timer_outlined,
            title: 'Reload with 30s idle timeout',
            subtitle:
                'Tears down + re-inits the singleton with '
                'sessionIdleTimeout: 30s — send a msg, wait 35s, reopen → '
                'fresh guest, empty history',
            onTap: () async {
              Chataptor.reset();
              await Chataptor.init(
                config: _buildConfig(
                  sessionIdleTimeout: const Duration(seconds: 30),
                ),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Re-initialised with 30s idle timeout active'),
                ),
              );
            },
          ),
          _DemoTile(
            icon: Icons.restart_alt,
            title: 'Reload with default config',
            subtitle: 'Tears down + re-inits without idle timeout',
            onTap: () async {
              Chataptor.reset();
              await Chataptor.init(config: _buildConfig());
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Re-initialised with default config'),
                ),
              );
            },
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

  void _openAsBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Material(
                color: Theme.of(sheetContext).colorScheme.surface,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(sheetContext).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Expanded(
                      child: ChataptorChatScreen(
                        showAppBar: false,
                        title: 'Help',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
