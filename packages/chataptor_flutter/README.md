# chataptor_flutter

[![pub.dev](https://img.shields.io/pub/v/chataptor_flutter.svg)](https://pub.dev/packages/chataptor_flutter)
[![CI](https://github.com/chataptor/chataptor-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/chataptor/chataptor-flutter/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/chataptor/chataptor-flutter/blob/main/LICENSE)

Official Flutter widgets for [Chataptor](https://chataptor.com?utm_source=pub.dev&utm_medium=referral&utm_campaign=chataptor_flutter&utm_content=readme_hero) — real-time multilingual customer support chat with built-in auto-translation.

This package provides the `Chataptor` singleton, ready-to-use chat widgets, theming, and localization. It re-exports the full [`chataptor`](https://pub.dev/packages/chataptor) core, so you only need this one dependency.

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

## Testing

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

## Requirements

| | Minimum |
|-|---------|
| Flutter | 3.35.0 |
| Dart | 3.9.0 |
| iOS | 12.0 |
| Android | API 21 |

## License

[MIT](https://github.com/chataptor/chataptor-flutter/blob/main/LICENSE) © 2026 Chataptor
