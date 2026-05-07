# Chataptor Flutter SDK

[![CI](https://github.com/chataptor/chataptor-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/chataptor/chataptor-flutter/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)

> Real-time multilingual customer support chat for Flutter — one agent, any language, zero awkward translations.

Official Flutter SDK for [Chataptor](https://chataptor.com). Integrate live customer support into your iOS, Android, or Web Flutter app in three lines of code. Your support team responds in their language; customers read in theirs — automatically, with no workflow change.

## Why Chataptor

- 🌍 **Real-time bidirectional auto-translation** — customer writes in Japanese, agent reads Polish, replies in Polish, customer reads Japanese. Sub-second round-trips.
- 📘 **Translation Memory + Glossary** — consistent terminology across every conversation. Brand terms and product names never get mangled in translation.
- 📧 **Email threading** — customer closes the app mid-conversation, the agent replies, the customer receives an email and can reply by email. The full history stays unified.
- 🎨 **Pure Dart** — no native SDK wrappers. Smaller binary, fewer platform-specific bugs, Flutter Web supported.
- 🔓 **Open source (MIT)** — audit the client code before shipping to production. No black box.

## Packages

| Package | pub.dev | Purpose |
|---------|---------|---------|
| [`chataptor`](./packages/chataptor) | `dart pub add chataptor` | Pure-Dart headless core — use for custom UI |
| [`chataptor_flutter`](./packages/chataptor_flutter) | `flutter pub add chataptor_flutter` | Drop-in Flutter widgets + singleton |

Most projects only need `chataptor_flutter` — it re-exports the full core API.

## Quickstart

```dart
import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Chataptor.init(
    siteId: 'your-site-id',   // from Chataptor admin → Settings → API
    widgetKey: 'pk_xxx',      // public key, safe to embed in client code
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [ChataptorLocalizations.delegate],
      supportedLocales: ChataptorLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChataptorChatScreen()),
            ),
            child: const Text('Open support chat'),
          ),
        ),
      ),
    );
  }
}
```

The screen manages its own socket connection: it connects on mount and disconnects on pop.

See the [getting-started guide](./docs/guides/getting-started.md) for theming, advanced configuration, and custom UIs.

## Requirements

| | Minimum |
|-|---------|
| Flutter | 3.35.0 |
| Dart | 3.9.0 |
| iOS | 12.0 |
| Android | API 21 |

## Roadmap

| Version | Scope |
|---------|-------|
| **v0.1.0** | Anonymous customer chat · `ChataptorChatScreen` widget · EN + PL locales |
| v0.2.0 | Identified customers (HMAC-verified) |
| v0.3.0 | Push notifications |
| v0.4.0 | File attachments · translation UI · quick replies · carousels |
| v0.5.0 | 10 additional locales · accessibility (blocking CI) · `ChataptorBubble` / `ChataptorChatSheet` |
| v0.6.0 | Flutter Web officially supported |
| v1.0.0 | API stabilisation |

## License

[MIT](./LICENSE) © 2026 Chataptor

## Links

- Product website: [chataptor.com](https://chataptor.com)
- Getting started: [`docs/guides/getting-started.md`](./docs/guides/getting-started.md)
- Architecture decisions: [`ARCHITECTURE.md`](./ARCHITECTURE.md)
- Contributing: [`CONTRIBUTING.md`](./CONTRIBUTING.md)
- Issues: [github.com/chataptor/chataptor-flutter/issues](https://github.com/chataptor/chataptor-flutter/issues)
