# chataptor

[![pub.dev](https://img.shields.io/pub/v/chataptor.svg)](https://pub.dev/packages/chataptor)
[![CI](https://github.com/chataptor/chataptor-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/chataptor/chataptor-flutter/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](../../LICENSE)

Pure-Dart headless core client for [Chataptor](https://chataptor.com) — real-time multilingual customer support chat.

**This package has no Flutter dependency.** Use it when you need a custom UI or when you are integrating Chataptor into a pure-Dart server or CLI context. For drop-in Flutter widgets, use [`chataptor_flutter`](../chataptor_flutter/) instead — it re-exports everything in this package.

## Install

```yaml
dependencies:
  chataptor: ^0.1.0
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

## Testing

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

## Requirements

| | Minimum |
|-|---------|
| Dart | 3.9.0 |

## License

[MIT](../../LICENSE) © 2026 Chataptor
