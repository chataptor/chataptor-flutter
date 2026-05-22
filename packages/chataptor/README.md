<div align="center">

<img src="https://raw.githubusercontent.com/chataptor/chataptor-flutter/main/.github/assets/chataptor-logotype-white.png" alt="Chataptor" height="56">

<br>

Pure-Dart headless client for [Chataptor](https://chataptor.com?utm_source=pub.dev&utm_medium=referral&utm_campaign=chataptor&utm_content=readme_hero) — real-time, auto-translated customer support chat.

[![pub.dev](https://img.shields.io/pub/v/chataptor.svg?label=pub.dev)](https://pub.dev/packages/chataptor)
[![pub points](https://img.shields.io/pub/points/chataptor?label=pub%20points)](https://pub.dev/packages/chataptor/score)
[![likes](https://img.shields.io/pub/likes/chataptor?label=likes)](https://pub.dev/packages/chataptor/score)
[![CI](https://github.com/chataptor/chataptor-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/chataptor/chataptor-flutter/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/chataptor/chataptor-flutter/blob/main/LICENSE)

</div>

> **Chataptor is free, forever.** Auto-translate customer conversations across 100+ languages and reach anyone, anywhere — no credit card, no trial. [Create your account →](https://chataptor.com/register?utm_source=pub.dev&utm_medium=referral&utm_campaign=chataptor&utm_content=readme_cta)

## What you get

| | |
|---|---|
| 🌍 | Auto-translate customer ↔ agent conversations across **100+ languages**, in real time |
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

## When to use this package

Use `chataptor` directly when you need a fully custom UI, or when you are integrating Chataptor into a pure-Dart server or CLI context. For drop-in Flutter widgets, install [`chataptor_flutter`](https://pub.dev/packages/chataptor_flutter) — it re-exports everything in this package.

## Install

```yaml
dependencies:
  chataptor: ^0.2.0
```

```bash
dart pub get
```

## Usage

### 1. Configure and connect

```dart
import 'package:chataptor/chataptor.dart';

final client = ChataptorClient(
  config: ChataptorConfig(
    siteId: 'your-site-id',   // Chataptor admin → Settings → API
    widgetKey: 'pk_xxx',      // public key, safe to embed in client code
  ),
);

await client.connect();
```

### 2. Listen to messages

```dart
client.messages.listen((message) {
  print('${message.body}');
});
```

### 3. Send a message

`sendMessage` returns a sealed [`SendResult`] — handle both outcomes:

```dart
final result = await client.sendMessage('Hello, I need help with my order.');

switch (result) {
  case SendSuccess():
    print('Message sent');
  case SendFailure(:final error):
    print('Send failed: $error');
}
```

### 4. Observe connection state

The `connectionState` stream emits sealed [`ConnectionState`] values:

```dart
client.connectionState.listen((state) {
  switch (state) {
    case Connected():
      print('Connected — ready to send');
    case Connecting():
      print('Connecting…');
    case Reconnecting(:final attemptNumber, :final nextAttemptIn):
      print('Retry #$attemptNumber in $nextAttemptIn');
    case Disconnected(:final reason):
      print('Disconnected: $reason');
  }
});

// Or read synchronously without subscribing:
final current = client.currentConnectionState;
```

### 5. Read site config and online-agent presence

The backend pushes site configuration (welcome message, header title per
language, offline mode) on the site channel join, and broadcasts agent
availability events thereafter. Both signals are exposed as streams with
a synchronous current-value accessor for one-shot reads:

```dart
// Per-language site config (welcomeMessage, headerTitle, offline mode).
final config = client.currentSiteConfig;
print(config?.activeHeaderTitle('pl'));

client.siteConfigStream.listen((cfg) {
  // re-render header / offline UX
});

// Live roster of currently-online agents (id, name, avatar URL, initials).
for (final agent in client.currentOnlineAgents) {
  print('${agent.name} (${agent.initials.short})');
}

client.onlineAgentsStream.listen((agents) {
  // re-render avatar stack / Online-Offline status
});
```

### 6. Clear the session

`clearSession()` drops the persisted guest identity and resets the
in-memory conversation. The next `connect()` registers as a fresh
customer with a new conversation thread. Useful for "log out" buttons
in customer apps and for local development.

```dart
await client.clearSession();
```

### 7. Disconnect and dispose

```dart
await client.disconnect();
await client.dispose(); // releases all streams and transport resources
```

## Configuration

`ChataptorConfig` accepts ergonomic defaults — only `siteId` and `widgetKey` are required:

```dart
ChataptorConfig(
  siteId: 'your-site-id',
  widgetKey: 'pk_xxx',

  // Intercept and modify outgoing messages (return null to cancel send)
  hooks: ChataptorHooks(
    beforeSend: (draft) async {
      // sanitise, enrich, or cancel
      return draft.copyWith(body: draft.body.trim());
    },
    onMessageReceived: (message) {
      // fire analytics events here
    },
    onError: (error) {
      // forward to your crash reporter
    },
  ),

  // Replace the built-in logger
  logger: MyCustomLogger(),

  // Replace the built-in storage (defaults to in-memory for pure Dart,
  // SharedPreferences via chataptor_flutter)
  storage: MyCustomStorage(),
)
```

<details>
<summary><strong>Testing</strong> — fakes for unit and widget tests</summary>

Import `package:chataptor/testing.dart` in your test files — **never in production code**.

```dart
import 'package:chataptor/chataptor.dart';
import 'package:chataptor/testing.dart';
import 'package:test/test.dart';

// Helper — Message requires explicit field values.
Message _agentMsg(String body) => Message(
  id: 'test-$body',
  conversationId: 'conv-1',
  body: body,
  author: MessageAuthor.agent,
  timestamp: DateTime.utc(2026, 1, 1),
  type: MessageType.text,
  deliveryChannel: DeliveryChannel.websocket,
  status: MessageStatus.delivered,
);

void main() {
  test('receives incoming message from agent', () async {
    final fake = FakeChataptorClient();

    expect(fake.messages, emits(isA<Message>()));
    fake.inject.message(_agentMsg('Hi, how can I help?'));
  });

  test('records outgoing messages', () async {
    final fake = FakeChataptorClient(
      initialConnectionState: const Connected(),
    );
    fake.inject.completeNextSend(
      SendSuccess(MessageDraft(body: 'Hello!')),
    );

    await fake.sendMessage('Hello!');

    expect(fake.recorded.sentMessages.first.body, 'Hello!');
  });
}
```

`FakeChataptorClient` is the high-level fake for testing code that consumes the SDK.
For testing the SDK transport layer itself, use `FakeChatTransport`.

| Export | Purpose |
|--------|---------|
| `FakeChataptorClient` | Drop-in replacement for `ChataptorClient` in host-app tests |
| `FakeChatTransport` | Transport-level scripting for SDK unit tests |
| `InMemoryChataptorStorage` | Resets between test runs |
| `RecordingChataptorLogger` | Assert on log output |

</details>

## Requirements

| | Minimum |
|-|---------|
| Dart | 3.9.0 |

## Documentation

| | |
|---|---|
| [Getting started](https://github.com/chataptor/chataptor-flutter/blob/main/docs/guides/getting-started.md) | Five-minute walk-through from zero to working chat |
| [Identified customers](https://github.com/chataptor/chataptor-flutter/blob/main/docs/guides/identified-customers.md) | HMAC verification recipe with server-side snippets |
| [Multi-instance setup](https://github.com/chataptor/chataptor-flutter/blob/main/docs/guides/multi-instance.md) | Running multiple Chataptor sites in one app |
| [Architecture](https://github.com/chataptor/chataptor-flutter/blob/main/ARCHITECTURE.md) | Locked design decisions |
| [Changelog](https://github.com/chataptor/chataptor-flutter/blob/main/packages/chataptor/CHANGELOG.md) | Per-version release notes |

## License

[MIT](https://github.com/chataptor/chataptor-flutter/blob/main/LICENSE) © 2026 Chataptor
