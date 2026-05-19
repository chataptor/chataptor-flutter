# Quickstart Example

Runnable hub demonstrating every supported integration mode of the
`chataptor_flutter` SDK in a single Flutter app.

## Run

Credentials are passed via `--dart-define` so nothing sensitive lives
in source:

```bash
cd examples/quickstart
flutter pub get
flutter run \
  --dart-define=CHATAPTOR_SITE_ID=<your-site-id> \
  --dart-define=CHATAPTOR_WIDGET_KEY=<your-widget-key>
```

A ready-made wrapper for local development lives at
`run_local.ps1.example` — copy it to `run_local.ps1` (which is git-ignored)
and fill in your credentials once.

Without `--dart-define`, the app falls back to placeholder credentials
(`YOUR_SITE_ID` / `YOUR_WIDGET_KEY`) so the UI still renders for visual
review, but no real backend connection is made.

## What it demonstrates

The home screen lists four entry points, each a small but complete
example of a different integration style:

| Demo | What it shows |
|------|---------------|
| **Default** | `ChataptorChatScreen()` with the built-in Material theme and default header copy. The fastest possible drop-in. |
| **Matched to app theme** | `ChataptorTheme.matching(context)` so the chat blends with the surrounding `MaterialApp`. Header reads `Help center`. |
| **Custom brand + white-label** | Heavily customised `ChataptorTheme.light().copyWith(...)` (Polish header copy, white-label `showPoweredBy: false`). |
| **Build your own UI** | Headless integration in `lib/headless_demo.dart` — subscribes to `siteConfigStream` + `onlineAgentsStream` to render a custom presence strip and chat without using the drop-in widget. |

Plus a **Clear session** action that calls `Chataptor.instance.clearSession()`
to reset the guest identity, useful during local testing.

## Source layout

```
lib/
├── main.dart           # Hub UI + four navigation entries
└── headless_demo.dart  # Custom-UI demo built directly on ChataptorClient
```

## Next steps

- Drop-in details: [`chataptor_flutter` README](../../packages/chataptor_flutter/README.md)
- Headless API: [`chataptor` core README](../../packages/chataptor/README.md)
- Full guide: [`docs/guides/getting-started.md`](../../docs/guides/getting-started.md)
