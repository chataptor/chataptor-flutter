<div align="center">

<img src="https://raw.githubusercontent.com/chataptor/chataptor-flutter/main/.github/assets/chataptor-logotype-white.png" alt="Chataptor" height="56">

<br>

Drop-in Flutter widgets for [Chataptor](https://chataptor.com?utm_source=pub.dev&utm_medium=referral&utm_campaign=chataptor_flutter&utm_content=readme_hero) — real-time, auto-translated customer support chat.

[![pub.dev](https://img.shields.io/pub/v/chataptor_flutter.svg?label=pub.dev)](https://pub.dev/packages/chataptor_flutter)
[![pub points](https://img.shields.io/pub/points/chataptor_flutter?label=pub%20points)](https://pub.dev/packages/chataptor_flutter/score)
[![likes](https://img.shields.io/pub/likes/chataptor_flutter?label=likes)](https://pub.dev/packages/chataptor_flutter/score)
[![CI](https://github.com/chataptor/chataptor-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/chataptor/chataptor-flutter/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/chataptor/chataptor-flutter/blob/main/LICENSE)

</div>

> **Chataptor is free, forever.** Auto-translate customer conversations across 100+ languages and reach anyone, anywhere — no credit card, no trial. [Create your account →](https://chataptor.com/register?utm_source=pub.dev&utm_medium=referral&utm_campaign=chataptor_flutter&utm_content=readme_cta)

## What you get

| | |
|---|---|
| 🌍 | Auto-translate customer ↔ agent conversations across **100+ languages**, in real time |
| 🎨 | `ChataptorChatScreen` + `ChataptorChatHeader` widgets that match your Material theme out of the box |
| 📘 | Translation Memory + Glossary keep brand terms and product names consistent |
| 📧 | Email threading — chat closes, agent replies, full history stays unified |
| 🔓 | Pure-Dart core, MIT-licensed, no native wrappers, no black box |

## In practice

```
👤  Customer in Tokyo
     注文した商品がまだ届いていません
        ↓  auto-translated, in real time
🎧  Your agent reads
     "My order hasn't arrived yet."

🎧  Your agent replies in English
     "Sure, let me check your order."
        ↓  auto-translated, in real time
👤  Customer reads in Japanese
     もちろん、ご注文を確認します
```

Same chat. No language switching, no copy-paste, no Google Translate.

## Contents

- [Install](#install)
- [Quickstart](#quickstart)
- [Theming](#theming)
- [Custom UI](#custom-ui)
- [Testing](#testing)
- [Documentation](#documentation)

This package ships the `Chataptor` singleton, ready-to-use chat widgets, theming, and localization. It re-exports the full [`chataptor`](https://pub.dev/packages/chataptor) core, so this is the only dependency you need.

## Install

```yaml
dependencies:
  chataptor_flutter: ^0.1.0
```

```bash
flutter pub get
```

## Quickstart

### 1. Initialise at app start

Call `Chataptor.init` once before `runApp`. Both `siteId` and `widgetKey` are found in the Chataptor admin console under **Settings → API**.

```dart
import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Chataptor.init(
    siteId: 'your-site-id',
    widgetKey: 'pk_xxx',
  );

  runApp(const MyApp());
}
```

### 2. Add localization delegates

Wire `ChataptorLocalizations` into your `MaterialApp`:

```dart
MaterialApp(
  localizationsDelegates: const [
    ChataptorLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: ChataptorLocalizations.supportedLocales,
  home: const HomeScreen(),
)
```

v0.1.0 ships English and Polish. Ten additional locales arrive in v0.5.0.

### 3. Open the chat screen

`ChataptorChatScreen` is a full-page widget. Push it with the standard `Navigator`:

```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const ChataptorChatScreen()),
);
```

The screen connects to Chataptor on mount and disconnects when popped — no lifecycle management required on your side.

## Theming

`ChataptorTheme` controls all visual aspects of the chat UI. Two factory constructors cover the most common cases:

```dart
// Stand-alone defaults (purple accent, light backgrounds)
ChataptorTheme.light()

// Derives from the ambient Material theme — blends with your app automatically
ChataptorTheme.matching(context)
```

Override individual tokens via `copyWith`:

```dart
ChataptorTheme.light().copyWith(
  primaryColor: Colors.teal,
  bubbleRadius: const BorderRadius.all(Radius.circular(8)),
)
```

Pass the theme to `ChataptorChatScreen`:

```dart
ChataptorChatScreen(
  theme: ChataptorTheme.matching(context).copyWith(
    primaryColor: Theme.of(context).colorScheme.secondary,
  ),
)
```

## Custom UI

For full control over the UI, use the core `ChataptorClient` directly. Access the process-wide instance via `Chataptor.instance`, or inject a specific client with `ChataptorScope`:

```dart
// Access the singleton
final client = Chataptor.instance;

// Or inject a specific client into a subtree
ChataptorScope(
  client: myClient,
  child: const MyChatWidget(),
)
```

Subscribe to streams directly:

```dart
final client = Chataptor.instance;

// Incoming messages
client.messages.listen((message) {
  setState(() => _messages.add(message));
});

// Connection state
client.connectionState.listen((state) {
  if (state is Connected) _setReady();
});

// Per-language site config (welcome message, team name, offline mode)
client.siteConfigStream.listen((config) {
  setState(() => _teamName = config.activeHeaderTitle('pl'));
});

// Live roster of currently-online agents (id, name, avatar URL, initials)
client.onlineAgentsStream.listen((agents) {
  setState(() => _onlineAgents = agents);
});

// Send
final result = await client.sendMessage('Hello!');
```

The drop-in `ChataptorChatScreen` already consumes these streams to
render `ChataptorChatHeader` (avatar stack of online agents, team name
from `SiteConfig.activeHeaderTitle`, live Online/Offline indicator) —
matching the production web widget on chataptor.com sites. Headless
integrations get the same data so a custom header can show the same
presence info.

<details>
<summary><strong>Testing</strong> — wire a fake client into your widget tests</summary>

Inject a `FakeChataptorClient` via `ChataptorScope` to test your UI without a network connection:

```dart
import 'package:chataptor/chataptor.dart';
import 'package:chataptor/testing.dart';
import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chat screen mounts with connected client', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final fake = FakeChataptorClient(
      initialConnectionState: const Connected(),
    );

    await tester.pumpWidget(
      ChataptorScope(
        client: fake,
        child: const MaterialApp(home: ChataptorChatScreen()),
      ),
    );

    expect(find.byType(ChataptorChatScreen), findsOneWidget);

    // Simulate a connection drop
    fake.inject.connectionState(
      const Disconnected(DisconnectReason.networkError),
    );
    await tester.pump(const Duration(milliseconds: 100));
  });
}
```

Use `fake.inject` to drive the client into any state, and `fake.recorded` to assert on what the UI sent.

</details>

## Requirements

| | Minimum |
|-|---------|
| Flutter | 3.35.0 |
| Dart | 3.9.0 |
| iOS | 12.0 |
| Android | API 21 |

## Documentation

| | |
|---|---|
| [Getting started](https://github.com/chataptor/chataptor-flutter/blob/main/docs/guides/getting-started.md) | Five-minute walk-through from zero to working chat |
| [Identified customers](https://github.com/chataptor/chataptor-flutter/blob/main/docs/guides/identified-customers.md) | HMAC verification recipe with server-side snippets |
| [Multi-instance setup](https://github.com/chataptor/chataptor-flutter/blob/main/docs/guides/multi-instance.md) | Running multiple Chataptor sites in one app |
| [Architecture](https://github.com/chataptor/chataptor-flutter/blob/main/ARCHITECTURE.md) | Locked design decisions |
| [Changelog](https://github.com/chataptor/chataptor-flutter/blob/main/packages/chataptor_flutter/CHANGELOG.md) | Per-version release notes |
| [Example app](https://github.com/chataptor/chataptor-flutter/tree/main/examples/quickstart) | Runnable demo |

## License

[MIT](https://github.com/chataptor/chataptor-flutter/blob/main/LICENSE) © 2026 Chataptor
