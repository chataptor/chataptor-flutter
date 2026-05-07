# Chataptor Flutter SDK

> Real-time multilingual customer support chat for Flutter. One agent, many languages, zero awkward translations.

Official Flutter SDK for [Chataptor](https://chataptor.com) — adds live customer support to your mobile and web Flutter apps with built-in bidirectional auto-translation, so your support team can serve customers in any language without hiring polyglots.

## Why Chataptor

- 🌍 **Real-time bidirectional auto-translation** — customer writes in Japanese, your agent reads Polish, replies in Polish, customer reads Japanese. No workflow change.
- 📘 **Translation Memory + Glossary** — terminology stays consistent across conversations, brand terms never get lost in translation.
- 📧 **Email threading** — customer closes the app mid-conversation, agent replies, customer gets an email, replies by email, history stays unified on the backend.
- 🎨 **Pure Dart** — no native SDK wrappers. Smaller app size, fewer platform-specific bugs. Officially iOS + Android from day one; Flutter Web is best-effort through `v0.5.0` and officially supported from `v0.6.0`.
- 🔓 **Open source, MIT** — audit the client code before shipping to production.

## Packages

| Package | Purpose | Install |
|---------|---------|---------|
| [`chataptor`](./packages/chataptor) | Pure-Dart headless core | `dart pub add chataptor` |
| [`chataptor_flutter`](./packages/chataptor_flutter) | Flutter widgets + singleton | `flutter pub add chataptor_flutter` |

Most integrators only need `chataptor_flutter` — it transitively re-exports the core.

## 60-second quickstart

```dart
import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Chataptor.init(
    siteId: 'your-site',
    widgetKey: 'pk_xxx',
  );

  runApp(MaterialApp(
    localizationsDelegates: const [ChataptorLocalizations.delegate],
    supportedLocales: ChataptorLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: Builder(builder: (ctx) => FilledButton(
          onPressed: () => Navigator.of(ctx).push(
            MaterialPageRoute(builder: (_) => const ChataptorChatScreen()),
          ),
          child: const Text('Open chat'),
        )),
      ),
    ),
  ));
}
```

See the [getting-started guide](./docs/guides/getting-started.md) for identified customers, theming, and custom UIs.

## Status

`v0.1.0` — first release. Anonymous customer chat, drop-in `ChataptorChatScreen` widget, English and Polish locales.

The roadmap for v0.2.0–v1.0.0 (identified customers, push notifications, file attachments, 10+ locales, accessibility) is tracked in the repository issues.

## License

[MIT](./LICENSE) © 2026 Chataptor

## Links

- Product: [chataptor.com](https://chataptor.com)
- Architecture decisions: [`ARCHITECTURE.md`](./ARCHITECTURE.md)
- Getting started: [`docs/guides/getting-started.md`](./docs/guides/getting-started.md)
- Issues: [GitHub issues](https://github.com/chataptor/chataptor-flutter/issues)
