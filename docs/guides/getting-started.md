# Getting started with Chataptor Flutter SDK

Five-minute walk-through from zero to working chat.

## 1. Prerequisites

- Flutter `3.35.0` or newer. Older Flutter versions do not bundle Dart 3.9, which the SDK requires.
- A Chataptor account — [create one for free at chataptor.com](https://chataptor.com/register). Chataptor is free, forever. From the admin console you will need:
  - **Site ID** — shown under *Settings → API*.
  - **Widget key** — public API key for this site (starts with `pk_`).

## 2. Install

Add to your app's `pubspec.yaml`:

```yaml
dependencies:
  chataptor_flutter: ^0.1.0
```

Then:

```bash
flutter pub get
```

## 3. Initialise at app start

Before you `runApp`, call `Chataptor.init` once:

```dart
import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Chataptor.init(
    siteId: 'your-site-id',
    widgetKey: 'pk_your_widget_key',
  );

  runApp(const MyApp());
}
```

## 4. Add localization delegates

Wire up `ChataptorLocalizations` in your `MaterialApp`:

```dart
MaterialApp(
  localizationsDelegates: const [
    ChataptorLocalizations.delegate,
    // plus your own + GlobalMaterial/Widgets delegates as usual
  ],
  supportedLocales: ChataptorLocalizations.supportedLocales,
  // ...
);
```

v0.1.0 ships English and Polish. Other locales arrive in v0.5.0.

## 5. Open the chat screen

The simplest integration pushes a full-screen chat page:

```dart
onPressed: () => Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const ChataptorChatScreen()),
),
```

That's it. The screen connects on mount, disconnects on dispose, and handles anonymous identification automatically.

## 6. Identifying your users (optional)

v0.1.0 treats every user as anonymous and maintains conversation continuity across app launches via a device-stable guest ID. From v0.2.0 you can pass a `CustomerIdentity` to give agents your user's email, name, and CRM linkage — and optionally an HMAC verification hash that proves the identity is real.

See [Identifying customers](./identified-customers.md) for the full guide, including copy-paste server recipes in Elixir, Ruby, Node.js, PHP, and Python.

## 7. Running multiple sites in one app (advanced)

If your app serves more than one Chataptor site — reseller or white-label setup — see [Running multiple Chataptor sites in one app](./multi-instance.md) for the per-scope client pattern.

## Troubleshooting

- **"ChataptorStateError: ChataptorClient is not connected"** — make sure `Chataptor.init` was awaited before the chat screen mounts.
- **No messages arrive** — verify your site ID and widget key against the admin console. The SDK logs connection errors via the configured logger; pass a `RecordingChataptorLogger` (from `package:chataptor/testing.dart`) during dev to inspect them.
- **Want a custom UI?** Use the core `ChataptorClient` directly and subscribe to its streams — the drop-in widgets are just consumers of the same public API.

## Next steps

- [Architecture decisions](../../ARCHITECTURE.md) — 25 locked design decisions explained.
- [Quickstart example](../../examples/quickstart) — runnable code.
