<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset=".github/assets/chataptor-logotype-white.png">
  <img src=".github/assets/chataptor-logotype.png" alt="Chataptor" height="56">
</picture>

<br>

Real-time, auto-translated customer support chat for Flutter — one agent, any language, no awkward translations.

[![pub.dev — chataptor](https://img.shields.io/pub/v/chataptor.svg?label=chataptor)](https://pub.dev/packages/chataptor)
[![pub.dev — chataptor_flutter](https://img.shields.io/pub/v/chataptor_flutter.svg?label=chataptor_flutter)](https://pub.dev/packages/chataptor_flutter)
[![CI](https://github.com/chataptor/chataptor-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/chataptor/chataptor-flutter/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)

</div>

> [!TIP]
> **Chataptor is free, forever.** No credit card, no trial. [Create your account at chataptor.com →](https://chataptor.com/register)

Official Flutter SDK for [Chataptor](https://chataptor.com). Integrate live customer support into your iOS or Android Flutter app in three lines of code. Your support team responds in their language; customers read in theirs — automatically, with no workflow change.

## In practice

> A customer in Tokyo writes `注文した商品がまだ届いていません`.
> Your agent reads `My order hasn't arrived yet.` in English and replies in English.
> The customer reads the reply in Japanese — instantly, in the same chat.

No language switching, no copy-paste, no Google Translate.

## Why Chataptor

- 💸 **Free, forever** — the hosted service is free; no credit card, no trial. The SDK is MIT-licensed.
- 🌍 **Real-time bidirectional auto-translation** — 100+ languages, sub-second round-trips.
- 📘 **Translation Memory + Glossary** — brand terms and product names stay consistent across every conversation.
- 📧 **Email threading** — customer closes the app mid-conversation, agent replies, customer receives an email and can reply by email. The full history stays unified.
- 🎨 **Pure Dart** — no native SDK wrappers. Smaller binary, fewer platform-specific bugs, Flutter Web supported.
- 🔓 **Open source (MIT)** — audit the client code before shipping to production.

> [!NOTE]
> **Platforms:** iOS and Android are officially supported. Flutter Web works as a side-effect of the pure-Dart core but is best-effort until officially supported. Desktop works incidentally and is not promoted.

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

## License

[MIT](./LICENSE) © 2026 Chataptor

## Links

- Product website: [chataptor.com](https://chataptor.com)
- Getting started: [`docs/guides/getting-started.md`](./docs/guides/getting-started.md)
- Architecture decisions: [`ARCHITECTURE.md`](./ARCHITECTURE.md)
- Contributing: [`CONTRIBUTING.md`](./CONTRIBUTING.md)
- Issues: [github.com/chataptor/chataptor-flutter/issues](https://github.com/chataptor/chataptor-flutter/issues)
